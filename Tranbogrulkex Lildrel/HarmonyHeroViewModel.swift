import Foundation
import Combine

final class HarmonyHeroViewModel: ObservableObject {
    struct Round: Identifiable, Equatable {
        let id = UUID()
        let targetIndex: Int
        let options: [Int]
        var selectedIndex: Int?
        var isCorrect: Bool? {
            guard let selectedIndex else { return nil }
            return selectedIndex == targetIndex
        }
    }

    @Published private(set) var rounds: [Round] = []
    @Published private(set) var currentRoundIndex: Int = 0
    @Published private(set) var isFinished: Bool = false
    @Published private(set) var accuracy: Double = 0
    @Published private(set) var maxStreak: Int = 0
    @Published private(set) var streak: Int = 0

    private(set) var activity: ActivityKind
    private(set) var difficulty: Difficulty
    private(set) var level: Int

    private var startDate: Date?

    init(activity: ActivityKind, difficulty: Difficulty, level: Int) {
        self.activity = activity
        self.difficulty = difficulty
        self.level = level
        buildRounds()
    }

    private func buildRounds() {
        let chordCount: Int
        switch difficulty {
        case .easy:
            chordCount = 6
        case .normal:
            chordCount = 8
        case .hard:
            chordCount = 10
        }

        let roundCount = 6 + level
        let baseIndices = Array(0..<chordCount)

        var generated: [Round] = []
        for i in 0..<roundCount {
            let target = baseIndices[(i + level) % chordCount]
            var options: [Int] = [target]
            for j in 1..<4 {
                let index = baseIndices[(i + j * 2 + level) % chordCount]
                if !options.contains(index) {
                    options.append(index)
                }
            }
            while options.count < 4 {
                if let random = baseIndices.randomElement(), !options.contains(random) {
                    options.append(random)
                }
            }
            options.shuffle()
            let round = Round(targetIndex: target, options: options)
            generated.append(round)
        }
        rounds = generated
    }

    func selectOption(at optionIndex: Int) {
        guard !isFinished else { return }
        guard currentRoundIndex < rounds.count else { return }

        if startDate == nil {
            startDate = Date()
        }

        var updated = rounds
        updated[currentRoundIndex].selectedIndex = optionIndex
        rounds = updated
        recomputeAccuracyAndStreak()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.advanceRoundIfNeeded()
        }
    }

    private func advanceRoundIfNeeded() {
        guard !isFinished else { return }
        currentRoundIndex += 1
        if currentRoundIndex >= rounds.count {
            finish()
        }
    }

    private func recomputeAccuracyAndStreak() {
        var hits = 0
        var considered = 0
        var currentStreak = 0
        var best = 0

        for round in rounds {
            if let isCorrect = round.isCorrect {
                considered += 1
                if isCorrect {
                    hits += 1
                    currentStreak += 1
                    if currentStreak > best {
                        best = currentStreak
                    }
                } else {
                    currentStreak = 0
                }
            }
        }

        if considered == 0 {
            accuracy = 0
        } else {
            accuracy = Double(hits) / Double(considered)
        }
        streak = currentStreak
        maxStreak = best
    }

    private func finish() {
        isFinished = true
    }

    func buildResult() -> ActivityResult {
        let elapsed: TimeInterval
        if let startDate {
            elapsed = Date().timeIntervalSince(startDate)
        } else {
            elapsed = TimeInterval(rounds.count)
        }

        let successThreshold: Double
        switch difficulty {
        case .easy:
            successThreshold = 0.55
        case .normal:
            successThreshold = 0.7
        case .hard:
            successThreshold = 0.8
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

