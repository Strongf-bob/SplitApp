import Foundation

enum SplitLaunchPresentation {
    static let minimumDuration: TimeInterval = 0.35

    static func remainingDuration(since startedAt: Date, now: Date = .now) -> TimeInterval {
        max(0, minimumDuration - now.timeIntervalSince(startedAt))
    }
}
