import Foundation
import Combine

final class MelodyMakerViewModel: ObservableObject {
    struct NoteSlot: Identifiable, Equatable {
        let id = UUID()
        let index: Int
        var placedNote: Int?
        let targetNote: Int
    }

    @Published private(set) var slots: [NoteSlot] = []
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
        buildTargetPattern()
    }

    private func buildTargetPattern() {
        let length: Int
        switch difficulty {
        case .easy:
            length = 6 + level
        case .normal:
            length = 8 + level
        case .hard:
            length = 10 + level
        }

        let noteRange: [Int]
        switch difficulty {
        case .easy:
            noteRange = [0, 1, 2]
        case .normal:
            noteRange = [0, 1, 2, 3]
        case .hard:
            noteRange = [0, 1, 2, 3]
        }

        var pattern: [NoteSlot] = []
        for i in 0..<length {
            let noteIndex: Int
            if difficulty == .hard && i % 4 == 3 {
                noteIndex = (i + level) % noteRange.count
            } else {
                noteIndex = (i * 2 + level) % noteRange.count
            }

            let slot = NoteSlot(index: i, placedNote: nil, targetNote: noteIndex)
            pattern.append(slot)
        }
        slots = pattern
    }

    func startIfNeeded() {
        guard startDate == nil else { return }
        startDate = Date()
    }

    func place(note: Int, at slotIndex: Int) {
        guard slotIndex >= 0, slotIndex < slots.count else { return }
        startIfNeeded()

        var updated = slots
        updated[slotIndex].placedNote = note
        slots = updated
        recomputeAccuracyAndStreak()
    }

    func clearSlot(at slotIndex: Int) {
        guard slotIndex >= 0, slotIndex < slots.count else { return }
        var updated = slots
        updated[slotIndex].placedNote = nil
        slots = updated
        recomputeAccuracyAndStreak()
    }

    func finish() {
        isFinished = true
        recomputeAccuracyAndStreak()
    }

    private func recomputeAccuracyAndStreak() {
        var hits = 0
        var considered = 0
        var currentStreak = 0
        var best = 0

        for slot in slots {
            if let placed = slot.placedNote {
                considered += 1
                if placed == slot.targetNote {
                    hits += 1
                    currentStreak += 1
                    if currentStreak > best {
                        best = currentStreak
                    }
                } else {
                    currentStreak = 0
                }
            } else {
                currentStreak = 0
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

    func buildResult() -> ActivityResult {
        let elapsed: TimeInterval
        if let startDate {
            elapsed = Date().timeIntervalSince(startDate)
        } else {
            elapsed = TimeInterval(slots.count)
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

