//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import XCTest


class TestAppUITests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
    }
    
    func testSpeziSpeech() throws {
        let app = XCUIApplication()
        app.launch()
        
        XCTAssert(app.staticTexts["SpeziSpeech"].waitForExistence(timeout: 1))
        
        try app.testVoiceSelection()
    }
        
}

extension XCUIApplication {
    func testVoiceSelection() throws {
        let picker = pickers["voicePicker"]
        let optionToSelect = picker.pickerWheels.element(boundBy: 0)
        optionToSelect.adjust(toPickerWheelValue: "Kathy")
    }
}
