import XCTest

@MainActor
final class RewindUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launchReady(_ arguments: [String] = []) {
        app.launchArguments = arguments
        app.launch()
        let tape = app.buttons["cassette"]
        XCTAssertTrue(tape.waitForExistence(timeout: 20))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Ready"), object: tape)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 20), .completed)
    }

    private func expectMemory(_ fragment: String) {
        let memory = app.staticTexts["memory.caption"]
        XCTAssertTrue(memory.waitForExistence(timeout: 4))
        let correct = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", fragment), object: memory)
        XCTAssertEqual(XCTWaiter.wait(for: [correct], timeout: 4), .completed)
    }

    func testEveryThemeBothSides() {
        launchReady()
        let b = ["SUMMER ’98", "THE LONG WAY HOME", "SUNDAY, 4:12 PM"]
        let a = ["AFTER THE LAST SONG", "FRIDAY, 11:48 PM", "A FAMILIAR VOICE"]
        for index in 0..<3 {
            app.buttons["theme.\(index)"].tap()
            app.buttons["cassette"].tap()
            expectMemory(b[index])
            XCTAssertTrue(app.buttons["cassette"].label.contains("Side B"))
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Theme-\(index)-Side-B"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            app.buttons["cassette"].tap()
            expectMemory(a[index])
            XCTAssertTrue(app.buttons["cassette"].label.contains("Side A"))
        }
    }

    func testLoadFailureCanRetry() {
        app.launchArguments = ["-simulate-load-failure"]
        app.launch()
        let retry = app.buttons["tape.retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: 15))
        XCTAssertTrue(retry.isHittable)
        retry.tap()
        let tape = app.buttons["cassette"]
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Ready"), object: tape)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 20), .completed)
        tape.tap()
        expectMemory("SUMMER ’98")
    }

    func testMemoryCancellationAndNavigationBounds() {
        launchReady()
        app.buttons["cassette"].tap()
        app.buttons["theme.1"].tap()
        XCTAssertTrue(app.buttons["cassette"].label.contains("Super Tape"))
        XCTAssertFalse(app.staticTexts["memory.caption"].waitForExistence(timeout: 1))
        app.buttons["theme.0"].tap()
        app.buttons["cassette"].swipeRight()
        XCTAssertTrue(app.buttons["cassette"].label.contains("Original"))
        app.buttons["theme.2"].tap()
        app.buttons["cassette"].swipeLeft()
        XCTAssertTrue(app.buttons["cassette"].label.contains("Vintage"))
        app.buttons["theme.0"].tap()
        app.buttons["theme.2"].tap()
        app.buttons["theme.0"].tap()
        XCTAssertTrue(app.buttons["cassette"].label.contains("Original"))
    }

    func testSoundPreferencePersistsAndAboutCredit() {
        launchReady()
        app.buttons["about"].tap()
        XCTAssertTrue(app.staticTexts["Made by Tajdid Rahman"].waitForExistence(timeout: 3))
        let sound = app.switches["sound.effects"]
        XCTAssertTrue(sound.waitForExistence(timeout: 3))
        XCTAssertTrue(sound.isHittable)
        let before = XCTAttachment(screenshot: app.screenshot()); before.name = "Sound-before"; before.lifetime = .keepAlways; add(before)
        if sound.value as? String == "1" {
            sound.tap()
        }
        let after = XCTAttachment(screenshot: app.screenshot()); after.name = "Sound-after"; after.lifetime = .keepAlways; add(after)
        let disabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "0"), object: sound)
        XCTAssertEqual(XCTWaiter.wait(for: [disabled], timeout: 3), .completed)
        app.terminate()
        launchReady()
        app.buttons["about"].tap()
        XCTAssertTrue(sound.waitForExistence(timeout: 3))
        XCTAssertEqual(sound.value as? String, "0")
        sound.tap()
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "1"), object: sound)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 3), .completed)
        app.buttons["about.done"].tap()
        app.buttons["cassette"].tap()
        expectMemory("SUMMER ’98")
    }
}
