import XCTest
@testable import Cornhub

@MainActor
final class StatsRangeTests: XCTestCase {
    private func response() -> Anki_Stats_GraphsResponse {
        var response = Anki_Stats_GraphsResponse()
        // Reviews: 10 today, 5 on day -3, 20 on day -20 (60 s each), 40 on day -200.
        for (offset, count) in [(0, 10), (-3, 5), (-20, 20), (-200, 40)] as [(Int32, UInt32)] {
            var reviews = Anki_Stats_GraphsResponse.ReviewCountsAndTimes.Reviews()
            reviews.young = count
            response.reviews.count[offset] = reviews
            var time = Anki_Stats_GraphsResponse.ReviewCountsAndTimes.Reviews()
            time.young = count * 60_000
            response.reviews.time[offset] = time
        }
        var week = Anki_Stats_GraphsResponse.TrueRetentionStats.TrueRetention()
        week.youngPassed = 15
        var month = week
        month.youngPassed = 18
        month.youngFailed = 2
        var year = month
        year.youngPassed = 50
        year.youngFailed = 25
        response.trueRetention.week = week
        response.trueRetention.month = month
        response.trueRetention.year = year
        // Due: 3 per day for the next 60 days.
        for day in 0..<400 { response.futureDue.futureDue[Int32(day)] = 3 }
        return response
    }

    private func model() throws -> StatsModel {
        let model = StatsModel(backend: try Backend())
        model.apply(response())
        return model
    }

    func testRetentionDiffersPerRange() throws {
        let model = try model()
        model.range = .week
        XCTAssertEqual(model.retention, 1.0)
        XCTAssertEqual(model.retentionReviews, 15)
        model.range = .month
        XCTAssertEqual(try XCTUnwrap(model.retention), 0.9, accuracy: 0.001)
        XCTAssertEqual(model.retentionReviews, 20)
        model.range = .year
        XCTAssertEqual(try XCTUnwrap(model.retention), 50.0 / 75.0, accuracy: 0.001)
        XCTAssertEqual(model.retentionReviews, 75)
    }

    func testTotalsPerRange() throws {
        let model = try model()
        model.range = .week
        XCTAssertEqual(model.totals.reviews, 15)
        XCTAssertEqual(model.totals.minutes, 15)
        XCTAssertEqual(model.totals.daysStudied, 2)
        model.range = .month
        XCTAssertEqual(model.totals.reviews, 35)
        XCTAssertEqual(model.totals.daysStudied, 3)
        model.range = .year
        XCTAssertEqual(model.totals.reviews, 75)
        XCTAssertEqual(model.totals.daysStudied, 4)
    }

    func testActivityLengthPerRange() throws {
        let model = try model()
        model.range = .week
        XCTAssertEqual(model.activity.count, 7)
        XCTAssertEqual(model.activity.last, 10)
        model.range = .month
        XCTAssertEqual(model.activity.count, 30)
        model.range = .year
        XCTAssertEqual(model.activity.count, 364)
    }

    func testForecastBucketsPerRange() throws {
        let model = try model()
        model.range = .week
        XCTAssertEqual(model.forecast, Array(repeating: 3, count: 7))
        model.range = .month
        XCTAssertEqual(model.forecast.count, 30)
        model.range = .year
        XCTAssertEqual(model.forecast, Array(repeating: 90, count: 12))
    }

    func testNoReviewsInRangeGivesNilRetention() throws {
        let model = StatsModel(backend: try Backend())
        var response = Anki_Stats_GraphsResponse()
        response.futureDue.futureDue[0] = 1
        model.apply(response)
        XCTAssertNil(model.retention)
        XCTAssertEqual(model.retentionReviews, 0)
    }
}
