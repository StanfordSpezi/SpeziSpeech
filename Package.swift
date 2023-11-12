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
        .iOS(.v17)
    ],
    products: [
        .library(name: "SpeziSpeech", targets: ["SpeziSpeech"])
    ],
    dependencies: [
        .package(url: "https://github.com/StanfordSpezi/Spezi", .upToNextMinor(from: "0.8.0"))
    ],
    targets: [
        .target(
            name: "SpeziSpeech",
            dependencies: [
                .product(name: "Spezi", package: "Spezi")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SpeziSpeechTests",
            dependencies: [
                .target(name: "SpeziSpeech")
            ]
        )
    ]
)
