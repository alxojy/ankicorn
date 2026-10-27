import Foundation

extension Backend {
    /// `graphs`: the engine's statistics for the cards matching `search` (empty = everything) over `days` days.
    func graphs(search: String, days: UInt32) throws -> Anki_Stats_GraphsResponse {
        var request = Anki_Stats_GraphsRequest()
        request.search = search
        request.days = days
        return try call(service: ServiceIndex.Stats.service, method: ServiceIndex.Stats.graphs, request)
    }
}
