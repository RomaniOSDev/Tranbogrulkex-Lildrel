import SwiftUI

enum PlayRoute: Hashable {
    case levels(ActivityKind, Difficulty)
    case rhythm(ActivityKind, Difficulty, Int)
    case melody(ActivityKind, Difficulty, Int)
    case harmony(ActivityKind, Difficulty, Int)
    case practice(ActivityKind, Difficulty)
    case result(ResultPayload)
}

struct ResultPayload: Hashable {
    let activity: ActivityKind
    let difficulty: Difficulty
    let level: Int
    let result: ActivityResult
    let newAchievements: [AchievementType]
}

struct HomeView: View {
    @EnvironmentObject private var appData: AppData
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var path: [PlayRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroSummary

                    dailySection

                    difficultyPicker

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(ActivityKind.allCases) { activity in
                            VStack(spacing: 8) {
                                NavigationLink(
                                    value: PlayRoute.levels(activity, selectedDifficulty)
                                ) {
                                    ActivityCardView(activity: activity, difficulty: selectedDifficulty)
                                }
                                .buttonStyle(.plain)

                                HStack(spacing: 8) {
                                    NavigationLink(
                                        value: PlayRoute.practice(activity, selectedDifficulty)
                                    ) {
                                        Text("Free practice")
                                            .font(.caption.bold())
                                            .foregroundColor(.appTextPrimary)
                                            .padding(.vertical, 6)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(Color.appSurface)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(LinearGradient.appBackgroundGradient.ignoresSafeArea())
            .navigationDestination(for: PlayRoute.self) { route in
                switch route {
                case .levels(let activity, let difficulty):
                    LevelGridView(
                        activity: activity,
                        difficulty: difficulty,
                        onSelectLevel: { level in
                            switch activity {
                            case .rhythm:
                                path.append(.rhythm(activity, difficulty, level))
                            case .melody:
                                path.append(.melody(activity, difficulty, level))
                            case .harmony:
                                path.append(.harmony(activity, difficulty, level))
                            }
                        }
                    )
                case .rhythm(let activity, let difficulty, let level):
                    RhythmMaestroScreen(
                        activity: activity,
                        difficulty: difficulty,
                        level: level,
                        isPractice: false
                    ) { result in
                        let newlyUnlocked = appData.registerResult(
                            activity: activity,
                            difficulty: difficulty,
                            level: level,
                            result: result
                        )
                        let payload = ResultPayload(
                            activity: activity,
                            difficulty: difficulty,
                            level: level,
                            result: result,
                            newAchievements: newlyUnlocked
                        )
                        path.append(.result(payload))
                    }
                case .melody(let activity, let difficulty, let level):
                    MelodyMakerScreen(
                        activity: activity,
                        difficulty: difficulty,
                        level: level,
                        isPractice: false
                    ) { result in
                        let newlyUnlocked = appData.registerResult(
                            activity: activity,
                            difficulty: difficulty,
                            level: level,
                            result: result
                        )
                        let payload = ResultPayload(
                            activity: activity,
                            difficulty: difficulty,
                            level: level,
                            result: result,
                            newAchievements: newlyUnlocked
                        )
                        path.append(.result(payload))
                    }
                case .harmony(let activity, let difficulty, let level):
                    HarmonyHeroScreen(
                        activity: activity,
                        difficulty: difficulty,
                        level: level,
                        isPractice: false
                    ) { result in
                        let newlyUnlocked = appData.registerResult(
                            activity: activity,
                            difficulty: difficulty,
                            level: level,
                            result: result
                        )
                        let payload = ResultPayload(
                            activity: activity,
                            difficulty: difficulty,
                            level: level,
                            result: result,
                            newAchievements: newlyUnlocked
                        )
                        path.append(.result(payload))
                    }
                case .result(let payload):
                    ResultView(
                        payload: payload,
                        onNextLevel: {
                            handleNextLevel(from: payload)
                        },
                        onRetry: {
                            handleRetry(from: payload)
                        },
                        onBackToLevels: {
                            handleBackToLevels(from: payload)
                        }
                    )
                case .practice(let activity, let difficulty):
                    switch activity {
                    case .rhythm:
                        RhythmMaestroScreen(
                            activity: activity,
                            difficulty: difficulty,
                            level: 1,
                            isPractice: true
                        ) { _ in }
                    case .melody:
                        MelodyMakerScreen(
                            activity: activity,
                            difficulty: difficulty,
                            level: 1,
                            isPractice: true
                        ) { _ in }
                    case .harmony:
                        HarmonyHeroScreen(
                            activity: activity,
                            difficulty: difficulty,
                            level: 1,
                            isPractice: true
                        ) { _ in }
                    }
                }
            }
        }
    }

    private var heroSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Play hub")
                .font(.largeTitle.bold())
                .foregroundColor(.appTextPrimary)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Stars")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                    Text("\(appData.totalStars)")
                        .font(.title2.bold())
                        .foregroundColor(.appTextPrimary)
                    Text("Across all levels")
                        .font(.caption2)
                        .foregroundColor(.appTextSecondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCardStyle(cornerRadius: 16)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Session streak")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                    Text("\(appData.dailyStreak)x")
                        .font(.title2.bold())
                        .foregroundColor(.appTextPrimary)
                    Text("Daily patterns in a row")
                        .font(.caption2)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCardStyle(cornerRadius: 16)
            }
        }
        .padding(.top, 24)
    }

    private var dailySection: some View {
        let daily = appData.currentDailyChallenge

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily pattern")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    Text("\(daily.activity.displayName) • \(daily.difficulty.displayName) • Level \(daily.level)")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(appData.hasCompletedTodayDaily ? "Completed" : "New today")
                        .font(.caption.bold())
                        .foregroundColor(appData.hasCompletedTodayDaily ? .appAccent : .appPrimary)
                    Text("Streak: \(appData.dailyStreak)")
                        .font(.caption2)
                        .foregroundColor(.appTextSecondary)
                }
            }

            Button(action: {
                let challenge = appData.currentDailyChallenge
                switch challenge.activity {
                case .rhythm:
                    path.append(.rhythm(challenge.activity, challenge.difficulty, challenge.level))
                case .melody:
                    path.append(.melody(challenge.activity, challenge.difficulty, challenge.level))
                case .harmony:
                    path.append(.harmony(challenge.activity, challenge.difficulty, challenge.level))
                }
            }) {
                Text(appData.hasCompletedTodayDaily ? "Replay daily pattern" : "Start daily pattern")
                    .font(.subheadline.bold())
                    .foregroundColor(.appBackground)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.appPrimary)
                    )
            }
            .buttonStyle(.plain)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .padding(14)
        .appCardStyle(cornerRadius: 18)
    }

    private var difficultyPicker: some View {
        HStack(spacing: 8) {
            ForEach(Difficulty.allCases) { difficulty in
                let isSelected = difficulty == selectedDifficulty
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedDifficulty = difficulty
                    }
                }) {
                    Text(difficulty.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(isSelected ? .appBackground : .appTextSecondary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelected ? Color.appPrimary : Color.appSurface)
                        )
                }
                .buttonStyle(.plain)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.appSurface)
        )
    }

    private func handleNextLevel(from payload: ResultPayload) {
        let nextLevel = payload.level + 1
        if nextLevel <= AppData.maxLevelsPerDifficulty,
           appData.isLevelUnlocked(activity: payload.activity, difficulty: payload.difficulty, level: nextLevel) {
            path.removeAll { route in
                if case .result(let other) = route {
                    return other == payload
                }
                return false
            }
            switch payload.activity {
            case .rhythm:
                path.append(.rhythm(payload.activity, payload.difficulty, nextLevel))
            case .melody:
                path.append(.melody(payload.activity, payload.difficulty, nextLevel))
            case .harmony:
                path.append(.harmony(payload.activity, payload.difficulty, nextLevel))
            }
        } else {
            handleBackToLevels(from: payload)
        }
    }

    private func handleRetry(from payload: ResultPayload) {
        path.removeAll { route in
            if case .result(let other) = route {
                return other == payload
            }
            return false
        }
        switch payload.activity {
        case .rhythm:
            path.append(.rhythm(payload.activity, payload.difficulty, payload.level))
        case .melody:
            path.append(.melody(payload.activity, payload.difficulty, payload.level))
        case .harmony:
            path.append(.harmony(payload.activity, payload.difficulty, payload.level))
        }
    }

    private func handleBackToLevels(from payload: ResultPayload) {
        path.removeAll()
        path.append(.levels(payload.activity, payload.difficulty))
    }
}

private struct ActivityCardView: View {
    @EnvironmentObject private var appData: AppData

    let activity: ActivityKind
    let difficulty: Difficulty

    private var difficultyFactor: Double {
        switch difficulty {
        case .easy: return 0.6
        case .normal: return 0.8
        case .hard: return 1.0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.displayName)
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)

                    Text(activity.description)
                        .font(.footnote)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.appBackground.opacity(0.7))
                        .frame(width: 64, height: 64)

                    Image(systemName: activityIcon)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.appPrimary)
                }
            }

            progressRow
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.appSurface)
                .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 8)
        )
    }

    private var activityIcon: String {
        switch activity {
        case .rhythm:
            return "waveform.path.ecg"
        case .melody:
            return "music.note.list"
        case .harmony:
            return "circle.grid.3x3.fill"
        }
    }

    private var progressRow: some View {
        let maxLevels = AppData.maxLevelsPerDifficulty
        let completed = (1...maxLevels).filter {
            appData.stars(for: activity, difficulty: difficulty, level: $0) > 0
        }.count
        let totalStars = (1...maxLevels).map {
            appData.stars(for: activity, difficulty: difficulty, level: $0)
        }.reduce(0, +)
        let maxStars = maxLevels * 3
        let progress = max(0, min(1, Double(totalStars) / Double(maxStars)))

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Difficulty: \(difficulty.displayName)")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                Text("\(completed) / \(maxLevels) levels")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            GeometryReader { proxy in
                let width = proxy.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appBackground.opacity(0.9))
                        .frame(height: 8)

                    Capsule()
                        .fill(Color.appAccent)
                        .frame(width: width * CGFloat(progress * difficultyFactor), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

struct LevelGridView: View {
    @EnvironmentObject private var appData: AppData

    let activity: ActivityKind
    let difficulty: Difficulty
    let onSelectLevel: (Int) -> Void

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(activity.displayName)
                        .font(.title.bold())
                        .foregroundColor(.appTextPrimary)

                    Text("\(difficulty.displayName) • Tap a tile to begin.")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.top, 24)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(1...AppData.maxLevelsPerDifficulty, id: \.self) { level in
                        let stars = appData.stars(for: activity, difficulty: difficulty, level: level)
                        let unlocked = appData.isLevelUnlocked(activity: activity, difficulty: difficulty, level: level)

                        Button(action: {
                            if unlocked {
                                onSelectLevel(level)
                            }
                        }) {
                            VStack(spacing: 6) {
                                Text("\(level)")
                                    .font(.headline)
                                    .foregroundColor(.appTextPrimary)

                                HStack(spacing: 2) {
                                    ForEach(0..<3, id: \.self) { index in
                                        Image(systemName: index < stars ? "star.fill" : "star")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(index < stars ? .appAccent : .appTextSecondary.opacity(0.5))
                                    }
                                }
                                .frame(maxWidth: .infinity)

                                if !unlocked {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.appTextSecondary)
                                }
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(unlocked ? Color.appSurface : Color.appSurface.opacity(0.5))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(unlocked ? Color.appPrimary.opacity(0.6) : Color.clear, lineWidth: 1)
                            )
                            .opacity(unlocked ? 1.0 : 0.4)
                        }
                        .buttonStyle(.plain)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Levels")
        .navigationBarTitleDisplayMode(.inline)
    }
}

