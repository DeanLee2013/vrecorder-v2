//  LifecycleUITests.swift
//  Purpose: Background-stop lifecycle regression (feature #6 WI-3). Launches with
//  a deterministic ACTIVE fixture session (no mic), backgrounds the app, and
//  asserts the session stopped — verifying the scene-phase teardown (audit-G4r2 #2)
//  via the MicButton's accessibility value (listening → idle).

import XCTest

final class LifecycleUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func test_backgroundStopsActiveSession() {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-fixtureListening"]
        app.launch()

        let mic = app.buttons["vr.live.mic"]
        XCTAssertTrue(mic.waitForExistence(timeout: 10))
        XCTAssertEqual(mic.value as? String, "listening",
                       "launch fixture should start in an active listening state")

        // Background the app — scene-phase .background must stop() the session.
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 5))
        app.activate()

        XCTAssertTrue(mic.waitForExistence(timeout: 5))
        XCTAssertEqual(mic.value as? String, "idle",
                       "backgrounding should have stopped the session")
    }
}
