import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case decks, browse, stats, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .decks: "Decks"
        case .browse: "Browse"
        case .stats: "Stats"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .decks: "square.stack"
        case .browse: "magnifyingglass"
        case .stats: "chart.bar"
        case .settings: "gearshape"
        }
    }
}
