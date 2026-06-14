//  LiveScreenUITests.swift
//  Purpose: Smoke UI test (feature #6 WI-2) — launches the app in UI-testing mode
//  and asserts the live screen's key controls exist by accessibility id. Proves
//  the XCUITest target + launch mode + a11y identifiers all work end-to-end.

import XCTest

final class LiveScreenUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting"]   // isolated InMemory store, no Keychain
        app.launch()
        return app
    }

    func test_liveScreenShowsMicAndGear() {
        let app = launch()
        XCTAssertTrue(app.buttons["vr.live.gear"].waitForExistence(timeout: 10),
                      "settings gear should be on the live screen")
        XCTAssertTrue(app.buttons["vr.live.mic"].waitForExistence(timeout: 5),
                      "mic button should be on the live screen")
    }

    func test_gearOpensSettings() {
        let app = launch()
        XCTAssertTrue(app.buttons["vr.live.gear"].waitForExistence(timeout: 10))
        app.buttons["vr.live.gear"].tap()
        XCTAssertTrue(app.buttons["vr.settings.apiKeyRow"].waitForExistence(timeout: 5),
                      "tapping the gear should reveal the Settings API-key row")
    }
}
