#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${HOME}/.agentpulse"
PENDING_DIR="${BASE_DIR}/pending"
RESPONSES_DIR="${BASE_DIR}/responses"
POLICY_FILE="${BASE_DIR}/policy.json"

mkdir -p "${PENDING_DIR}" "${RESPONSES_DIR}" "${BASE_DIR}"

emit_hook() {
  local decision="$1"
  local reason="$2"
  /usr/bin/python3 - "$decision" "$reason" <<'PY'
import json
import sys

decision = sys.argv[1]
reason = sys.argv[2]
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": decision,
        "permissionDecisionReason": reason
    }
}))
PY
}

INPUT_JSON="$(cat || true)"
if [ -z "${INPUT_JSON}" ]; then
  emit_hook "deny" "AgentPulse bridge received empty hook payload"
  exit 0
fi

REQUEST_ID="$(uuidgen | tr '[:upper:]' '[:lower:]')"
PENDING_FILE="${PENDING_DIR}/${REQUEST_ID}.json"
RESPONSE_FILE="${RESPONSES_DIR}/${REQUEST_ID}.json"

META_JSON="$(HOOK_INPUT_JSON="${INPUT_JSON}" /usr/bin/python3 - "${REQUEST_ID}" "${POLICY_FILE}" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

request_id = sys.argv[1]
policy_path = Path(sys.argv[2])
payload = json.loads(os.environ["HOOK_INPUT_JSON"])

policy = {
    "defaultDecision": "ask",
    "timeoutSeconds": 115,
    "timeoutAction": "deny",
    "toolRules": {
        "Read": {"decision": "allow", "riskLevel": "low"},
        "Glob": {"decision": "allow", "riskLevel": "low"},
        "LS": {"decision": "allow", "riskLevel": "low"},
        "Bash": {"decision": "ask", "riskLevel": "high"},
        "Write": {"decision": "ask", "riskLevel": "high"},
        "Edit": {"decision": "ask", "riskLevel": "high"},
        "MultiEdit": {"decision": "ask", "riskLevel": "high"},
        "Delete": {"decision": "ask", "riskLevel": "high"},
        "Move": {"decision": "ask", "riskLevel": "high"},
        "Rename": {"decision": "ask", "riskLevel": "high"},
        "WebFetch": {"decision": "ask", "riskLevel": "high"}
    }
}

if policy_path.exists():
    try:
        policy = json.loads(policy_path.read_text())
    except Exception:
        pass

tool_name = payload.get("tool_name", "Unknown")
rule = policy.get("toolRules", {}).get(tool_name)
if rule:
    decision = rule.get("decision", policy.get("defaultDecision", "ask"))
    risk = rule.get("riskLevel", "high")
else:
    decision = policy.get("defaultDecision", "ask")
    risk = "high"

timeout = int(policy.get("timeoutSeconds", 115))
timeout_action = policy.get("timeoutAction", "deny")

reason = f"Policy {decision} for {tool_name} (risk: {risk})."

request_payload = {
    "id": request_id,
    "createdAt": datetime.now(timezone.utc).isoformat(),
    "source": "claude",
    "sessionId": payload.get("session_id", ""),
    "toolUseId": payload.get("tool_use_id", ""),
    "toolName": tool_name,
    "toolInput": payload.get("tool_input", {}),
    "riskLevel": risk,
    "riskReason": reason,
    "timeoutSeconds": timeout,
}

print(json.dumps({
    "decision": decision,
    "reason": reason,
    "risk": risk,
    "timeoutSeconds": timeout,
    "timeoutAction": timeout_action,
    "requestPayload": request_payload,
}))
PY
)"

INITIAL_DECISION="$(printf '%s' "${META_JSON}" | /usr/bin/python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["decision"])')"
INITIAL_REASON="$(printf '%s' "${META_JSON}" | /usr/bin/python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["reason"])')"
TIMEOUT_SECONDS="$(printf '%s' "${META_JSON}" | /usr/bin/python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["timeoutSeconds"])')"
TIMEOUT_ACTION="$(printf '%s' "${META_JSON}" | /usr/bin/python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["timeoutAction"])')"

if [ "${INITIAL_DECISION}" = "allow" ]; then
  emit_hook "allow" "${INITIAL_REASON}"
  exit 0
fi

if [ "${INITIAL_DECISION}" = "deny" ]; then
  emit_hook "deny" "${INITIAL_REASON}"
  exit 0
fi

META_JSON_ENV="${META_JSON}" /usr/bin/python3 - "${PENDING_FILE}" <<'PY'
import json
import os
import sys

meta = json.loads(os.environ["META_JSON_ENV"])
out_path = sys.argv[1]
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(meta["requestPayload"], f, indent=2)
PY

cleanup() {
  rm -f "${PENDING_FILE}" || true
}
trap cleanup EXIT

elapsed_ms=0
sleep_ms=500
max_ms=$((TIMEOUT_SECONDS * 1000))

while [ "${elapsed_ms}" -lt "${max_ms}" ]; do
  if [ -f "${RESPONSE_FILE}" ]; then
    RESPONSE_RESULT="$(/usr/bin/python3 - "${RESPONSE_FILE}" "${REQUEST_ID}" <<'PY'
import json
import sys

response_path = sys.argv[1]
request_id = sys.argv[2]

try:
    payload = json.load(open(response_path, encoding="utf-8"))
except Exception:
    print("deny\nMalformed AgentPulse response payload")
    raise SystemExit(0)

if payload.get("id") != request_id:
    print("deny\nResponse ID mismatch")
    raise SystemExit(0)

decision = payload.get("decision", "deny")
if decision not in {"allow", "deny", "ask"}:
    decision = "deny"

reason = payload.get("decisionReason", "Decision from AgentPulse")
print(f"{decision}\\n{reason}")
PY
)"

    DECISION="$(printf '%s' "${RESPONSE_RESULT}" | head -n1)"
    REASON="$(printf '%s' "${RESPONSE_RESULT}" | tail -n +2)"
    rm -f "${RESPONSE_FILE}" || true
    emit_hook "${DECISION}" "${REASON}"
    exit 0
  fi

  sleep 0.5
  elapsed_ms=$((elapsed_ms + sleep_ms))
done

emit_hook "${TIMEOUT_ACTION}" "Timed out waiting for AgentPulse response"
exit 0
