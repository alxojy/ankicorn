import XCTest

@testable import Cornhub

@MainActor
final class DeckOverviewModelTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = try makeTempDirectory()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func loadedModel() async throws -> DeckHomeModel {
        let model = DeckHomeModel(launch: LaunchOptions(seedSample: true), directory: directory)
        await model.load()
        XCTAssertEqual(model.state, .loaded)
        return model
    }

    func testCollectionCountsAddUpAndComeFromTheEngine() async throws {
        let model = try await loadedModel()
        let backend = try XCTUnwrap(model.backend)
        let hsk1 = try XCTUnwrap(model.decks.first { $0.name == "HSK 1" })
        let overview = DeckOverviewModel()
        await overview.load(deck: hsk1, backend: backend)
        let counts = overview.counts
        XCTAssertEqual(counts.total, hsk1.totalCards)
        XCTAssertEqual(counts.total, counts.mature + counts.young + counts.unseen)
        XCTAssertEqual(counts.unseen, counts.total, "fresh sample cards are all new")
        XCTAssertEqual(counts.mature, 0)
        XCTAssertEqual(counts.young, 0)
        XCTAssertEqual(counts.seen, 0)
    }

    func testDailyLimitCapIsDetectedFromUncappedAvailability() async throws {
        let model = try await loadedModel()
        let backend = try XCTUnwrap(model.backend)
        let hsk1 = try XCTUnwrap(model.decks.first { $0.name == "HSK 1" })
        let overview = DeckOverviewModel()
        await overview.load(deck: hsk1, backend: backend)
        XCTAssertEqual(overview.newAvailable, hsk1.totalCards)
        XCTAssertLessThan(hsk1.newCount, overview.newAvailable, "the daily new limit holds cards back")
        XCTAssertTrue(DeckOverviewModel.isCapped(available: overview.newAvailable, shown: hsk1.newCount))
        XCTAssertFalse(DeckOverviewModel.isCapped(available: overview.reviewAvailable, shown: hsk1.reviewCount))
    }

    func testStudyTotalIsNewPlusLearningPlusDueFromTheEngine() async throws {
        let model = try await loadedModel()
        for deck in model.decks {
            XCTAssertEqual(DeckOverviewModel.studyTotal(deck), deck.newCount + deck.learningCount + deck.reviewCount)
        }
        let hsk1 = try XCTUnwrap(model.decks.first { $0.name == "HSK 1" })
        XCTAssertEqual(DeckOverviewModel.studyTotal(hsk1), 20)
    }

    func testLevelsOnlyForDecksWithChildren() async throws {
        let model = try await loadedModel()
        let hsk1 = try XCTUnwrap(model.decks.first { $0.name == "HSK 1" })
        let hsk2 = try XCTUnwrap(model.decks.first { $0.name == "HSK 2" })
        XCTAssertFalse(DeckOverviewModel.showsLevels(hsk1))
        XCTAssertTrue(DeckOverviewModel.showsLevels(hsk2))
        let overview = DeckOverviewModel()
        await overview.load(deck: hsk2, backend: try XCTUnwrap(model.backend))
        XCTAssertEqual(Set(overview.levelCounts.keys), Set(hsk2.children.map(\.id)))
    }

    func testBreadcrumbSubtitleAndParentName() async throws {
        let model = try await loadedModel()
        let hsk2 = try XCTUnwrap(model.decks.first { $0.name == "HSK 2" })
        let verbs = try XCTUnwrap(hsk2.children.first)
        XCTAssertEqual(DeckOverviewModel.breadcrumb(verbs), "HSK 2 ›")
        XCTAssertEqual(DeckOverviewModel.parentName(verbs), "HSK 2")
        XCTAssertNil(DeckOverviewModel.breadcrumb(hsk2))
        XCTAssertEqual(model.tile(fullName: "HSK 2")?.id, hsk2.id)
        XCTAssertTrue(DeckOverviewModel.subtitle(hsk2).hasSuffix("· 1 level"), DeckOverviewModel.subtitle(hsk2))
    }

    func testCappedLineAndLastStudiedAndForecastText() {
        XCTAssertEqual(DeckOverviewModel.cappedLine(available: 538, shown: 20), "of 538 · capped")
        XCTAssertEqual(DeckOverviewModel.cappedLine(available: 30, shown: 0), "limit reached")
        XCTAssertEqual(DeckOverviewModel.lastStudiedText(nil), "Not studied yet")
        XCTAssertEqual(DeckOverviewModel.lastStudiedText(0), "Last studied today")
        XCTAssertEqual(DeckOverviewModel.lastStudiedText(1), "Last studied yesterday")
        XCTAssertEqual(DeckOverviewModel.lastStudiedText(2), "Last studied 2 days ago")
        XCTAssertEqual(DeckOverviewModel.forecast([0: 9, 1: 12, 3: 4, 7: 5, 8: 100]), [12, 0, 4, 0, 0, 0, 5])
    }

    func testDeckSearchEscapesQuotesAndWildcards() {
        XCTAssertEqual(DeckOverviewModel.deckSearch("A::B"), "\"deck:A::B\"")
        XCTAssertEqual(DeckOverviewModel.deckSearch("A \"q\"_*"), "\"deck:A \\\"q\\\"\\_\\*\"")
    }
}
