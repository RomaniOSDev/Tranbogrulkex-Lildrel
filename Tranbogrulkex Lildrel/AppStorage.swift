import Foundation
import SwiftUI
import Combine

enum ActivityKind: String, CaseIterable, Identifiable, Codable, Hashable {
    case rhythm
    case melody
    case harmony

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rhythm:
            return "Rhythm Maestro"
        case .melody:
            return "Melody Maker"
        case .harmony:
            return "Harmony Hero"
        }
    }

    var description: String {
        switch self {
        case .rhythm:
            return "Tap along to the animated beat and keep perfect timing."
        case .melody:
            return "Drag notes onto the staff to rebuild the target melody."
        case .harmony:
            return "Find matching chord progressions by listening to visual cues."
        }
    }
}

enum Difficulty: String, CaseIterable, Identifiable, Codable, Hashable {
    case easy
    case normal
    case hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy:
            return "Easy"
        case .normal:
            return "Normal"
        case .hard:
            return "Hard"
        }
    }
}

struct ActivityResult: Equatable, Hashable, Codable {
    let accuracy: Double
    let maxStreak: Int
    let timeElapsed: TimeInterval
    let success: Bool
    let starsEarned: Int
}

enum AchievementType: String, CaseIterable, Identifiable, Hashable, Codable {
    case firstStar
    case starCollector
    case starMaster
    case gettingWarm
    case sessionHero
    case levelExplorer
    case levelChampion
    case precisionArtist
    case perfectStreak
    case quickFinish
    case dailyStreak3
    case dailyStreak7
    case rhythmSpecialist
    case melodyArchitect
    case harmonyExplorer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstStar:
            return "First Spark"
        case .starCollector:
            return "Rhythm Chaser"
        case .starMaster:
            return "Harmony Legend"
        case .gettingWarm:
            return "Warm Up Complete"
        case .sessionHero:
            return "Endless Groove"
        case .levelExplorer:
            return "Pattern Explorer"
        case .levelChampion:
            return "Pattern Champion"
        case .precisionArtist:
            return "Precision Artist"
        case .perfectStreak:
            return "Combo Flow"
        case .quickFinish:
            return "Lightning Run"
        case .dailyStreak3:
            return "Daily Trio"
        case .dailyStreak7:
            return "Weekly Flow"
        case .rhythmSpecialist:
            return "Beat Sculptor"
        case .melodyArchitect:
            return "Melody Architect"
        case .harmonyExplorer:
            return "Harmony Explorer"
        }
    }

    var detail: String {
        switch self {
        case .firstStar:
            return "Earn your very first star in any activity."
        case .starCollector:
            return "Collect at least 15 stars across all activities."
        case .starMaster:
            return "Collect at least 30 stars across all activities."
        case .gettingWarm:
            return "Finish 5 activities in total."
        case .sessionHero:
            return "Finish 20 activities in total."
        case .levelExplorer:
            return "Complete 3 different levels with at least one star."
        case .levelChampion:
            return "Complete 20 different levels with at least one star."
        case .precisionArtist:
            return "Reach at least 95% accuracy in any activity."
        case .perfectStreak:
            return "Reach a streak of 10 or more in a single run."
        case .quickFinish:
            return "Clear any level with stars in under 40 seconds."
        case .dailyStreak3:
            return "Complete the daily pattern three days in a row."
        case .dailyStreak7:
            return "Complete the daily pattern seven days in a row."
        case .rhythmSpecialist:
            return "Earn stars on at least 10 Rhythm levels."
        case .melodyArchitect:
            return "Earn stars on at least 10 Melody levels."
        case .harmonyExplorer:
            return "Earn stars on at least 10 Harmony levels."
        }
    }
}

struct AchievementStatus: Identifiable {
    let type: AchievementType
    let isUnlocked: Bool

    var id: String { type.id }
}

final class AppData: ObservableObject {
    static let resetNotification = Notification.Name("AppDataDidReset")
    static let maxLevelsPerDifficulty = 12

    @Published private(set) var starsByLevel: [String: Int]
    @Published private(set) var totalPlayTime: TimeInterval
    @Published private(set) var totalActivitiesPlayed: Int
    @Published private(set) var bestAccuracy: Double
    @Published private(set) var overallMaxStreak: Int
    @Published private(set) var shortestSuccessfulTime: TimeInterval

    @Published private(set) var dailyCompletedDates: Set<String>
    @Published var guidedModeEnabled: Bool
    @Published var hasSeenOnboarding: Bool

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.starsByLevel = defaults.dictionary(forKey: "starsByLevel") as? [String: Int] ?? [:]
        self.totalPlayTime = defaults.double(forKey: "totalPlayTime")
        self.totalActivitiesPlayed = defaults.integer(forKey: "totalActivitiesPlayed")
        self.bestAccuracy = defaults.double(forKey: "bestAccuracy")
        self.overallMaxStreak = defaults.integer(forKey: "overallMaxStreak")
        let savedShortestTime = defaults.double(forKey: "shortestSuccessfulTime")
        self.shortestSuccessfulTime = savedShortestTime > 0 ? savedShortestTime : 0

        if let storedDates = defaults.array(forKey: "dailyCompletedDates") as? [String] {
            self.dailyCompletedDates = Set(storedDates)
        } else {
            self.dailyCompletedDates = []
        }

        self.guidedModeEnabled = defaults.bool(forKey: "guidedModeEnabled")
        self.hasSeenOnboarding = defaults.bool(forKey: "hasSeenOnboarding")
    }

    // MARK: - Level keys and stars

    private func key(for activity: ActivityKind, difficulty: Difficulty, level: Int) -> String {
        return "\(activity.rawValue)_\(difficulty.rawValue)_\(level)"
    }

    func stars(for activity: ActivityKind, difficulty: Difficulty, level: Int) -> Int {
        let value = starsByLevel[key(for: activity, difficulty: difficulty, level: level)] ?? 0
        return max(0, min(3, value))
    }

    func isLevelUnlocked(activity: ActivityKind, difficulty: Difficulty, level: Int) -> Bool {
        guard level > 1 else { return true }
        let previousStars = stars(for: activity, difficulty: difficulty, level: level - 1)
        return previousStars > 0
    }

    // MARK: - Aggregates

    var totalStars: Int {
        starsByLevel.values.reduce(0, +)
    }

    var completedLevelsCount: Int {
        starsByLevel.values.filter { $0 > 0 }.count
    }

    // MARK: - Daily challenge helpers

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    var todayKey: String {
        dateString(for: Date())
    }

    var currentDailyChallenge: (activity: ActivityKind, difficulty: Difficulty, level: Int) {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let seed = (components.year ?? 0) * 10_000 + (components.month ?? 0) * 100 + (components.day ?? 0)

        let activities = ActivityKind.allCases
        let difficulties = Difficulty.allCases

        let activityIndex = abs(seed) % activities.count
        let difficultyIndex = abs(seed / 7) % difficulties.count
        let levelIndex = abs(seed / 13) % AppData.maxLevelsPerDifficulty

        let activity = activities[activityIndex]
        let difficulty = difficulties[difficultyIndex]
        let level = levelIndex + 1
        return (activity, difficulty, level)
    }

    var hasCompletedTodayDaily: Bool {
        dailyCompletedDates.contains(todayKey)
    }

    var dailyStreak: Int {
        let calendar = Calendar(identifier: .gregorian)
        var streak = 0
        var currentDate = Date()

        while dailyCompletedDates.contains(dateString(for: currentDate)) {
            streak += 1
            if let previous = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                currentDate = previous
            } else {
                break
            }
        }
        return streak
    }

    var dailyCompletionsThisWeek: Int {
        let calendar = Calendar(identifier: .gregorian)
        guard let todayWeekOfYear = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: Date()).weekOfYear,
              let todayYearForWeekOfYear = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: Date()).yearForWeekOfYear else {
            return 0
        }

        var count = 0
        for key in dailyCompletedDates {
            guard let date = (DateFormatter.cachedDayFormatter.date(from: key)) else { continue }
            let comps = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: date)
            if comps.weekOfYear == todayWeekOfYear, comps.yearForWeekOfYear == todayYearForWeekOfYear {
                count += 1
            }
        }
        return count
    }

    // MARK: - Achievements

    var unlockedAchievementTypes: [AchievementType] {
        var result: [AchievementType] = []

        if totalStars >= 1 {
            result.append(.firstStar)
        }
        if totalStars >= 15 {
            result.append(.starCollector)
        }
        if totalStars >= 30 {
            result.append(.starMaster)
        }
        if totalActivitiesPlayed >= 5 {
            result.append(.gettingWarm)
        }
        if totalActivitiesPlayed >= 20 {
            result.append(.sessionHero)
        }
        if completedLevelsCount >= 3 {
            result.append(.levelExplorer)
        }
        if completedLevelsCount >= 20 {
            result.append(.levelChampion)
        }
        if bestAccuracy >= 0.95 {
            result.append(.precisionArtist)
        }
        if overallMaxStreak >= 10 {
            result.append(.perfectStreak)
        }
        if shortestSuccessfulTime > 0, shortestSuccessfulTime <= 40 {
            result.append(.quickFinish)
        }
        if dailyStreak >= 3 {
            result.append(.dailyStreak3)
        }
        if dailyStreak >= 7 {
            result.append(.dailyStreak7)
        }

        let rhythmLevels = completedLevelsCount(for: .rhythm)
        let melodyLevels = completedLevelsCount(for: .melody)
        let harmonyLevels = completedLevelsCount(for: .harmony)

        if rhythmLevels >= 10 {
            result.append(.rhythmSpecialist)
        }
        if melodyLevels >= 10 {
            result.append(.melodyArchitect)
        }
        if harmonyLevels >= 10 {
            result.append(.harmonyExplorer)
        }

        return result
    }

    private func completedLevelsCount(for activity: ActivityKind) -> Int {
        starsByLevel.keys.filter { key in
            key.hasPrefix(activity.rawValue + "_")
        }.compactMap { key in
            starsByLevel[key]
        }
        .filter { $0 > 0 }
        .count
    }

    func achievementStatuses() -> [AchievementStatus] {
        let unlocked = Set(unlockedAchievementTypes)
        return AchievementType.allCases.map { type in
            AchievementStatus(type: type, isUnlocked: unlocked.contains(type))
        }
    }

    // MARK: - Persistence helpers

    private func saveStars() {
        defaults.set(starsByLevel, forKey: "starsByLevel")
    }

    private func saveStats() {
        defaults.set(totalPlayTime, forKey: "totalPlayTime")
        defaults.set(totalActivitiesPlayed, forKey: "totalActivitiesPlayed")
        defaults.set(bestAccuracy, forKey: "bestAccuracy")
        defaults.set(overallMaxStreak, forKey: "overallMaxStreak")
        if shortestSuccessfulTime > 0 {
            defaults.set(shortestSuccessfulTime, forKey: "shortestSuccessfulTime")
        }
    }

    private func saveOnboarding() {
        defaults.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
    }

    private func saveGuidedMode() {
        defaults.set(guidedModeEnabled, forKey: "guidedModeEnabled")
    }

    private func saveDailyCompleted() {
        let array = Array(dailyCompletedDates)
        defaults.set(array, forKey: "dailyCompletedDates")
    }

    // MARK: - Public API

    func markOnboardingSeen() {
        guard hasSeenOnboarding == false else { return }
        hasSeenOnboarding = true
        saveOnboarding()
    }

    func setGuidedMode(enabled: Bool) {
        guidedModeEnabled = enabled
        saveGuidedMode()
    }

    @discardableResult
    func registerResult(
        activity: ActivityKind,
        difficulty: Difficulty,
        level: Int,
        result: ActivityResult
    ) -> [AchievementType] {
        let before = Set(unlockedAchievementTypes)

        if result.starsEarned > 0 {
            let k = key(for: activity, difficulty: difficulty, level: level)
            let current = starsByLevel[k] ?? 0
            if result.starsEarned > current {
                starsByLevel[k] = result.starsEarned
                saveStars()
            }
        }

        totalPlayTime += max(0, result.timeElapsed)
        totalActivitiesPlayed += 1
        if result.accuracy > bestAccuracy {
            bestAccuracy = result.accuracy
        }
        if result.maxStreak > overallMaxStreak {
            overallMaxStreak = result.maxStreak
        }
        if result.success {
            if shortestSuccessfulTime <= 0 || result.timeElapsed < shortestSuccessfulTime {
                shortestSuccessfulTime = result.timeElapsed
            }
        }
        saveStats()

        let daily = currentDailyChallenge
        if result.success,
           daily.activity == activity,
           daily.difficulty == difficulty,
           daily.level == level {
            dailyCompletedDates.insert(todayKey)
            saveDailyCompleted()
        }

        let after = Set(unlockedAchievementTypes)
        let newlyUnlocked = Array(after.subtracting(before))
        return newlyUnlocked
    }

    func resetAll() {
        starsByLevel = [:]
        totalPlayTime = 0
        totalActivitiesPlayed = 0
        bestAccuracy = 0
        overallMaxStreak = 0
        shortestSuccessfulTime = 0
        dailyCompletedDates = []
        guidedModeEnabled = false
        hasSeenOnboarding = false

        defaults.removeObject(forKey: "starsByLevel")
        defaults.removeObject(forKey: "totalPlayTime")
        defaults.removeObject(forKey: "totalActivitiesPlayed")
        defaults.removeObject(forKey: "bestAccuracy")
        defaults.removeObject(forKey: "overallMaxStreak")
        defaults.removeObject(forKey: "shortestSuccessfulTime")
        defaults.removeObject(forKey: "dailyCompletedDates")
        defaults.removeObject(forKey: "guidedModeEnabled")
        defaults.removeObject(forKey: "hasSeenOnboarding")

        NotificationCenter.default.post(name: AppData.resetNotification, object: nil)
    }
}

private extension DateFormatter {
    static let cachedDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}


