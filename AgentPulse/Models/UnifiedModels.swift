import Foundation
import SwiftUI

enum AgentSource: String, Codable {
    case claude
    case codex
}

enum AgentAccentColor: String, Codable, CaseIterable {
    case amber
    case mint
    case coral
    case slateBlue

    var color: Color {
        switch self {
        case .amber:
            return Color(hex: 0xE8A84C)
        case .mint:
            return Color(hex: 0x7ECBA1)
        case .coral:
            return Color(hex: 0xE07A5F)
        case .slateBlue:
            return Color(hex: 0x8B9FC7)
        }
    }
}

struct UnifiedAgent: Identifiable, Hashable {
    let id: String
    let name: String
    let model: String
    let source: AgentSource
    let currentTask: String?
    let progress: Double
    let isActive: Bool
    let accent: AgentAccentColor
}

enum TaskStatus: String, Codable {
    case pending
    case inProgress
    case completed
}

struct UnifiedTask: Identifiable, Hashable {
    let id: String
    let subject: String
    let status: TaskStatus
    let owner: String?
    let updatedAt: Date
}

enum HeatLevel: String, Codable {
    case hot
    case warm
    case cool

    var color: Color {
        switch self {
        case .hot:
            return Color(hex: 0xE8A84C)
        case .warm:
            return Color(hex: 0xE07A5F).opacity(0.6)
        case .cool:
            return Color.white.opacity(0.15)
        }
    }
}

struct UnifiedFileActivity: Identifiable, Hashable {
    let id: String
    let path: String
    let source: AgentSource
    let updatedAt: Date

    var heatLevel: HeatLevel {
        let elapsed = Date().timeIntervalSince(updatedAt)
        switch elapsed {
        case ..<60:
            return .hot
        case ..<300:
            return .warm
        default:
            return .cool
        }
    }

    var directory: String {
        let nsPath = path as NSString
        let dir = nsPath.deletingLastPathComponent
        return dir.isEmpty ? "" : dir + "/"
    }

    var fileName: String {
        (path as NSString).lastPathComponent
    }

    var elapsedText: String {
        let sec = max(0, Int(Date().timeIntervalSince(updatedAt)))
        if sec < 60 { return "\(sec)s" }
        if sec < 3600 { return "\(sec / 60)m" }
        return "\(sec / 3600)h"
    }
}

struct AggregateStats {
    var activeAgents: Int
    var totalMessages: Int
    var totalToolCalls: Int
    var successRate: Double

    static let empty = AggregateStats(activeAgents: 0, totalMessages: 0, totalToolCalls: 0, successRate: 0)
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
