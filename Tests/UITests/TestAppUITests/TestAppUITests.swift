//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


@MainActor
class TestAppUITests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
    }
    
    func testSpeziSpeech() throws {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.staticTexts["Spezi Speech Tests"].waitForExistence(timeout: 1))
    }
    
    func testSynthesisWithVoiceSelection() throws {
        let app = XCUIApplication()
        app.launch()
        
        let voiceSelectionTestViewButton = app.staticTexts["Speech Voice Selection Test View"]
        
        XCTAssertTrue(voiceSelectionTestViewButton.waitForExistence(timeout: 1))
        voiceSelectionTestViewButton.tap()
        
        #if !os(visionOS)
        let picker = app.pickers["voicePicker"]
        let optionToSelect = picker.pickerWheels.element(boundBy: 0)
        optionToSelect.adjust(toPickerWheelValue: "Kathy")
        #endif
        
        let textField = app.textFields["Enter text to be spoken"]
        XCTAssertTrue(textField.waitForExistence(timeout: 1))
        
        textField.tap()
        textField.typeText("Hello, this is a test of the Spezi Speech module.")
        
        let speakButton = app.buttons["Speak"]
        XCTAssertTrue(speakButton.waitForExistence(timeout: 1))
        speakButton.tap()
        
        // Waits for speech to generate
        sleep(5)
    }
}
