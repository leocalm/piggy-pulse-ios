import XCTest

final class ScreenshotCaptureUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureRawScreenshot() throws {
        let config = try ScreenshotCaptureConfig.load()

        app.launchArguments = [
            "-AppleLanguages", "(\(config.locale))",
            "-AppleLocale", config.locale.replacingOccurrences(of: "-", with: "_"),
            "--screenshot-mode",
            "--screenshot-locale", config.locale,
            "--screenshot-state", config.state
        ]
        app.launch()

        waitForScreenshotState(config.state)

        let screenshot = XCUIScreen.main.screenshot()
        let outputURL = URL(fileURLWithPath: config.outputDirectory, isDirectory: true)
            .appendingPathComponent(config.filename)

        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try screenshot.pngRepresentation.write(to: outputURL, options: .atomic)

        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = config.filename
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func waitForScreenshotState(_ state: String) {
        let expectedIdentifier = accessibilityIdentifier(for: state)
        let target = app.descendants(matching: .any)[expectedIdentifier].firstMatch
        XCTAssertTrue(
            target.waitForExistence(timeout: TestConfig.longTimeout),
            "Screenshot state marker \(expectedIdentifier) did not appear for \(state)"
        )

        let ready = app.descendants(matching: .any)["screenshot.ready"].firstMatch
        XCTAssertTrue(
            ready.waitForExistence(timeout: TestConfig.defaultTimeout),
            "Screenshot ready marker did not appear for \(state)"
        )
    }

    private func accessibilityIdentifier(for state: String) -> String {
        switch state {
        case "01-dashboard-nebula", "02-dashboard-electric-neon", "03-dashboard-tropical":
            return "screenshot.dashboard"
        case "04-transactions":
            return "screenshot.transactions"
        case "05-period-configuration":
            return "screenshot.periodConfiguration"
        case "06-categories":
            return "screenshot.categories"
        default:
            XCTFail("Unknown screenshot state: \(state)")
            return "screenshot.ready"
        }
    }

    private struct ScreenshotCaptureConfig {
        let locale: String
        let state: String
        let outputDirectory: String
        let filename: String

        static func load() throws -> ScreenshotCaptureConfig {
            let environment = ProcessInfo.processInfo.environment
            let values = try loadFileConfig().merging(environment) { _, environmentValue in
                environmentValue
            }
            let locale = try required("SCREENSHOT_LOCALE", in: values)
            let state = try required("SCREENSHOT_STATE", in: values)
            let outputDirectory = try required("SCREENSHOT_CAPTURE_OUTPUT_DIR", in: values)
            let filename = values["SCREENSHOT_CAPTURE_FILENAME"].flatMap { $0.isEmpty ? nil : $0 } ?? "\(state).png"

            return ScreenshotCaptureConfig(
                locale: locale,
                state: state,
                outputDirectory: outputDirectory,
                filename: filename
            )
        }

        private static func loadFileConfig() throws -> [String: String] {
            let path = ProcessInfo.processInfo.environment["SCREENSHOT_CAPTURE_CONFIG"]
                ?? "/tmp/piggypulse-screenshot-capture.env"
            guard FileManager.default.fileExists(atPath: path) else {
                return [:]
            }

            let contents = try String(contentsOfFile: path, encoding: .utf8)
            var values: [String: String] = [:]
            for line in contents.split(separator: "\n") {
                guard let separator = line.firstIndex(of: "=") else {
                    continue
                }
                let key = String(line[..<separator])
                let value = String(line[line.index(after: separator)...])
                values[key] = value
            }
            return values
        }

        private static func required(_ name: String, in values: [String: String]) throws -> String {
            guard let value = values[name], !value.isEmpty else {
                throw XCTSkip("Missing required screenshot capture config value: \(name)")
            }
            return value
        }
    }
}
