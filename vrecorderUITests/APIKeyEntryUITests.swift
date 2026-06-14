//  APIKeyEntryUITests.swift
//  Purpose: feature #6 WI-4 — drives feature #2's API-key flow end-to-end via the
//  XCUITest harness (isolated -uiTesting InMemory store). Verifies the UI-drivable
//  acceptance criteria (enter→已配置, empty→disabled, clear→未配置). feature #2's
//  Release/real-Keychain criterion stays a separate device pass.

import XCTest

final class APIKeyEntryUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launch(seedKey: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting"]
        if let seedKey { app.launchArguments += ["-seedKey", seedKey] }
        app.launch()
        return app
    }

    private func openKeySheet(_ app: XCUIApplication) -> XCUIElement {
        XCTAssertTrue(app.buttons["vr.live.gear"].waitForExistence(timeout: 10))
        app.buttons["vr.live.gear"].tap()
        let row = app.buttons["vr.settings.apiKeyRow"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        return row
    }

    func test_enterValidKeyFlipsRowToConfigured() {
        let app = launch()                       // no seed → 未配置
        let row = openKeySheet(app)
        XCTAssertEqual(row.value as? String, "未配置")
        row.tap()
        let field = app.secureTextFields["vr.apikey.field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("sk-uitestkey1234567")
        app.buttons["vr.apikey.save"].tap()      // saves + dismisses
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertEqual(row.value as? String, "已配置", "row should reflect the saved key")
    }

    func test_emptyKeyKeepsSaveDisabled() {
        let app = launch()
        openKeySheet(app).tap()
        let save = app.buttons["vr.apikey.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertFalse(save.isEnabled, "empty draft → 保存 disabled")
    }

    func test_clearKeyFlipsRowToUnconfigured() {
        let app = launch(seedKey: "sk-seededkey1234567")   // starts 已配置
        let row = openKeySheet(app)
        XCTAssertEqual(row.value as? String, "已配置")
        row.tap()
        app.buttons["vr.apikey.clear"].tap()
        app.alerts.buttons["清除"].tap()                    // confirm
        app.buttons["取消"].tap()                           // dismiss the sheet
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertEqual(row.value as? String, "未配置", "row should reflect the cleared key")
    }
}
