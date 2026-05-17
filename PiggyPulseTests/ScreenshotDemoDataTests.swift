import XCTest
@testable import PiggyPulse

final class ScreenshotDemoDataTests: XCTestCase {
    func testScreenshotDemoCatalogIsComplete() {
        XCTAssertEqual(ScreenshotDemoCatalog.validate(), [])
    }

    func testEveryLocaleGeneratesAtLeast120TransactionsWithUniqueIDs() {
        for locale in ScreenshotLocaleID.allCases {
            let profile = ScreenshotDemoCatalog.profile(for: locale)
            XCTAssertGreaterThanOrEqual(profile.allTransactions.count, 120, locale.rawValue)
            XCTAssertEqual(Set(profile.allTransactions.map(\.id)).count, profile.allTransactions.count, locale.rawValue)
        }
    }

    func testDemoGenerationIsDeterministic() {
        let first = ScreenshotDemoCatalog.profile(for: .enUS)
        let second = ScreenshotDemoCatalog.profile(for: .enUS)

        XCTAssertEqual(first.allTransactions.map(\.id), second.allTransactions.map(\.id))
        XCTAssertEqual(first.allTransactions.map(\.date), second.allTransactions.map(\.date))
        XCTAssertEqual(first.allTransactions.map(\.description), second.allTransactions.map(\.description))
        XCTAssertEqual(first.allTransactions.map(\.amount), second.allTransactions.map(\.amount))
    }

    func testDemoTransactionsUsePositiveDisplayAmounts() {
        for locale in ScreenshotLocaleID.allCases {
            let profile = ScreenshotDemoCatalog.profile(for: locale)
            XCTAssertTrue(profile.allTransactions.allSatisfy { $0.amount >= 0 }, locale.rawValue)
        }
    }

    func testScreenshotModeIsOffByDefaultDuringUnitTests() {
        XCTAssertNil(ScreenshotModeConfiguration.current())
    }
}
