// swift-tools-version:5.9

//
// This source file is part of the Stanford Spezi open source project
// 
// SPDX-FileCopyrightText: 2023 Stanford University and the project authors (see CONTRIBUTORS.md)
// 
// SPDX-License-Identifier: MIT
//

import PackageDescription


let package = Package(
    name: "SpeziSpeech",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .visionOS(.v1),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SpeziSpeechRecognizer", targets: ["SpeziSpeechRecognizer"]),
        .library(name: "SpeziSpeechSynthesizer", targets: ["SpeziSpeechSynthesizer"])
    ],
    dependencies: [
        .package(url: "https://github.com/StanfordSpezi/Spezi", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "SpeziSpeechRecognizer",
            dependencies: [
                .product(name: "Spezi", package: "Spezi")
            ]
        ),
        .target(
            name: "SpeziSpeechSynthesizer",
            dependencies: [
                .product(name: "Spezi", package: "Spezi")
            ]
        ),
        .testTarget(
            name: "SpeziSpeechTests",
            dependencies: [
                .target(name: "SpeziSpeechRecognizer"),
                .target(name: "SpeziSpeechSynthesizer")
            ]
        )
    ]
)
