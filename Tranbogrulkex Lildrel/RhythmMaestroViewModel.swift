import Foundation
import Combine

final class RhythmMaestroViewModel: ObservableObject {
    struct BeatStep: Equatable {
        let circleIndex: Int
        let shouldTap: Bool
    }

    @Published private(set) var steps: [BeatStep] = []
    @Published private(set) var currentStepIndex: Int = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isFinished: Bool = false
    @Published private(set) var accuracy: Double = 0
    @Published private(set) var maxStreak: Int = 0
    @Published private(set) var streak: Int = 0
    @Published private(set) var progress: Double = 0

    private(set) var activity: ActivityKind
    private(set) var difficulty: Difficulty
    private(set) var level: Int

    private var expectedTapCount: Int = 0
    private var hitCount: Int = 0
    private var missCount: Int = 0
    private var didTapOnCurrentStep: Bool = false
    private var startDate: Date?

    var tickInterval: TimeInterval {
        switch difficulty {
        case .easy:
            return max(0.6 - TimeInterval(level) * 0.02, 0.3)
        case .normal:
            return max(0.45 - TimeInterval(level) * 0.015, 0.25)
        case .hard:
            return max(0.35 - TimeInterval(level) * 0.015, 0.18)
        }
    }

    init(activity: ActivityKind, difficulty: Difficulty, level: Int) {
        self.activity = activity
        self.difficulty = difficulty
        self.level = level
        generatePattern()
    }

    private func generatePattern() {
        let circleCount = 4
        let baseLength: Int
        switch difficulty {
        case .easy:
            baseLength = 16 + level * 2
        case .normal:
            baseLength = 20 + level * 2
        case .hard:
            baseLength = 24 + level * 2
        }

        var generated: [BeatStep] = []
        var tapEvery: Int

        switch difficulty {
        case .easy:
            tapEvery = 2
        case .normal:
            tapEvery = 1
        case .hard:
            tapEvery = 1
        }

        for index in 0..<baseLength {
            let circle = (index + level) % circleCount
            let shouldTap: Bool

            switch difficulty {
            case .easy:
                shouldTap = index % tapEvery == 0
            case .normal:
                if index % 4 == 0 {
                    shouldTap = true
                } else if index % 4 == 2 {
                    shouldTap = level % 2 == 0
                } else {
                    shouldTap = false
                }
            case .hard:
                if index % 3 == 0 {
                    shouldTap = true
                } else if index % 5 == 0 {
                    shouldTap = true
                } else {
                    shouldTap = false
                }
            }

            generated.append(BeatStep(circleIndex: circle, shouldTap: shouldTap))
        }

        expectedTapCount = generated.filter { $0.shouldTap }.count
        if expectedTapCount == 0 {
            expectedTapCount = 1
        }
        steps = generated
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        isFinished = false
        currentStepIndex = 0
        hitCount = 0
        missCount = 0
        streak = 0
        maxStreak = 0
        progress = 0
        startDate = Date()
        if steps.isEmpty {
            generatePattern()
        }
    }

    func tick() {
        guard isRunning, !isFinished else { return }
        if currentStepIndex < steps.count {
            if steps[currentStepIndex].shouldTap && !didTapOnCurrentStep {
                streak = 0
                missCount += 1
            }
        }

        didTapOnCurrentStep = false

        currentStepIndex += 1

        if currentStepIndex >= steps.count {
            finish()
        } else {
            progress = Double(currentStepIndex) / Double(steps.count)
            recomputeAccuracy()
        }
    }

    func registerTap() {
        guard isRunning, !isFinished else { return }
        guard currentStepIndex < steps.count else { return }

        let step = steps[currentStepIndex]

        if step.shouldTap {
            if !didTapOnCurrentStep {
                didTapOnCurrentStep = true
                hitCount += 1
                streak += 1
                if streak > maxStreak {
                    maxStreak = streak
                }
            }
        } else {
            streak = 0
            missCount += 1
        }

        recomputeAccuracy()
    }

    private func finish() {
        isRunning = false
        isFinished = true
        recomputeAccuracy()
    }

    private func recomputeAccuracy() {
        let totalEvents = max(expectedTapCount, 1)
        let clampedHits = max(0, min(hitCount, totalEvents))
        accuracy = Double(clampedHits) / Double(totalEvents)
    }

    func buildResult() -> ActivityResult {
        let elapsed: TimeInterval
        if let startDate {
            elapsed = Date().timeIntervalSince(startDate)
        } else {
            elapsed = TimeInterval(steps.count) * tickInterval
        }

        let successThreshold: Double
        switch difficulty {
        case .easy:
            successThreshold = 0.6
        case .normal:
            successThreshold = 0.75
        case .hard:
            successThreshold = 0.85
        }

        let star1Threshold = successThreshold
        let star2Threshold = min(0.9, successThreshold + 0.15)
        let star3Threshold = 0.97

        let stars: Int
        if accuracy >= star3Threshold {
            stars = 3
        } else if accuracy >= star2Threshold {
            stars = 2
        } else if accuracy >= star1Threshold {
            stars = 1
        } else {
            stars = 0
        }

        let success = stars > 0

        return ActivityResult(
            accuracy: accuracy,
            maxStreak: maxStreak,
            timeElapsed: elapsed,
            success: success,
            starsEarned: stars
        )
    }
}

