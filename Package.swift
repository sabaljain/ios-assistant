// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CalendarAssistant",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "CalendarAssistant", targets: ["CalendarAssistant"])
    ],
    targets: [
        .target(
            name: "CalendarAssistant",
            path: "Sources/CalendarAssistant"
        )
    ]
)
