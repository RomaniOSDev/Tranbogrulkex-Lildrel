import SwiftUI

struct CreateView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pattern Sketchpad")
                            .font(.largeTitle.bold())
                            .foregroundColor(.appTextPrimary)
                        Text("Build your own looping rhythm grid and see it animate.")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(.top, 24)

                    RhythmSketchPad()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(LinearGradient.appBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct RhythmSketchPad: View {
    private let rows = 4
    private let columns = 8

    @State private var activeCells: Set<Int> = []
    @State private var playhead: Int = 0
    @State private var isPlaying: Bool = false
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Tap tiles to toggle beats. Press Play to see your pattern come alive.")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
                ForEach(0..<(rows * columns), id: \.self) { index in
                    let isOn = activeCells.contains(index)
                    let columnIndex = index % columns
                    let highlight = columnIndex == playhead && isPlaying

                    Button(action: {
                        toggleCell(index)
                    }) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(cellColor(isOn: isOn, highlight: highlight))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(highlight ? Color.appAccent : Color.appBackground.opacity(0.6), lineWidth: highlight ? 2 : 1)
                            )
                            .frame(height: 32)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .appCardStyle(cornerRadius: 18)

            HStack(spacing: 12) {
                Button(action: togglePlay) {
                    Text(isPlaying ? "Pause" : "Play")
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

                Button(action: clear) {
                    Text("Clear")
                        .font(.subheadline.bold())
                        .foregroundColor(.appTextPrimary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.appSurface)
                        )
                }
                .buttonStyle(.plain)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func cellColor(isOn: Bool, highlight: Bool) -> Color {
        if highlight && isOn {
            return .appPrimary
        } else if isOn {
            return .appAccent
        } else if highlight {
            return Color.appSurface.opacity(0.9)
        } else {
            return Color.appSurface
        }
    }

    private func toggleCell(_ index: Int) {
        if activeCells.contains(index) {
            activeCells.remove(index)
        } else {
            activeCells.insert(index)
        }
    }

    private func togglePlay() {
        isPlaying.toggle()
        if isPlaying {
            startTimer()
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            playhead = (playhead + 1) % columns
        }
    }

    private func clear() {
        activeCells.removeAll()
        playhead = 0
    }
}

struct ExploreView: View {
    @EnvironmentObject private var appData: AppData

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    statsCard
                    guidedModeSection
                    levelMapLink
                    settingsLink
                    achievementsSection
                    resetSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(LinearGradient.appBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onReceive(NotificationCenter.default.publisher(for: AppData.resetNotification)) { _ in
        }
    }

    private var settingsLink: some View {
        NavigationLink(destination: SettingsView()) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    Text("Rate this app and review privacy information.")
                        .font(.footnote)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                Spacer()
                Image(systemName: "gearshape")
                    .foregroundColor(.appTextSecondary)
            }
            .padding(14)
            .appCardStyle(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress overview")
                .font(.largeTitle.bold())
                .foregroundColor(.appTextPrimary)
            Text("Track your stars, clear more levels, and unlock new banners.")
                .font(.subheadline)
                .foregroundColor(.appTextSecondary)
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            HStack {
                statBlock(title: "Total stars", value: "\(appData.totalStars)")
                statBlock(title: "Activities played", value: "\(appData.totalActivitiesPlayed)")
                statBlock(title: "Best accuracy", value: String(format: "%.0f%%", appData.bestAccuracy * 100))
            }

            HStack {
                statBlock(title: "Levels cleared", value: "\(appData.completedLevelsCount)")
                statBlock(title: "Play time", value: formattedTime(appData.totalPlayTime))
                statBlock(title: "Daily this week", value: "\(appData.dailyCompletionsThisWeek)/7")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(cornerRadius: 22)
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundColor(.appTextSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var guidedModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Guided mode")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    Text("Turn on subtle visual hints inside activities.")
                        .font(.footnote)
                        .foregroundColor(.appTextSecondary)
                }
                Spacer()
                Toggle(isOn: Binding(
                    get: { appData.guidedModeEnabled },
                    set: { appData.setGuidedMode(enabled: $0) }
                )) {
                    EmptyView()
                }
                .labelsHidden()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(cornerRadius: 20)
    }

    private var levelMapLink: some View {
        NavigationLink(destination: ProgressMapView().environmentObject(appData)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level map")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    Text("See your star trail across every activity and difficulty.")
                        .font(.footnote)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.appTextSecondary)
            }
            .padding(14)
            .appCardStyle(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }

    private var achievementsSection: some View {
        let statuses = appData.achievementStatuses()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            if statuses.isEmpty {
                Text("Play a few rounds to start unlocking banners.")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
            } else {
                ForEach(statuses) { status in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: status.isUnlocked ? "checkmark.seal.fill" : "seal")
                            .foregroundColor(status.isUnlocked ? .appAccent : .appTextSecondary)
                            .font(.system(size: 20, weight: .bold))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(status.type.title)
                                .font(.subheadline.bold())
                                .foregroundColor(.appTextPrimary)
                            Text(status.type.detail)
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }

                        Spacer()
                    }
                    .padding(10)
                    .appCardStyle(cornerRadius: 16)
                }
            }
        }
    }

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reset progress")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            Text("You can clear all stars, stats, and achievements to start fresh. This cannot be undone.")
                .font(.footnote)
                .foregroundColor(.appTextSecondary)

            Button(action: {
                appData.resetAll()
            }) {
                Text("Reset all progress")
                    .font(.subheadline.bold())
                    .foregroundColor(.appBackground)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.red.opacity(0.8))
                    )
            }
            .buttonStyle(.plain)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(cornerRadius: 22)
    }

    private func formattedTime(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded()))
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%d:%02d", minutes, remaining)
    }
}

struct ProgressMapView: View {
    @EnvironmentObject private var appData: AppData

    private let difficulties = Difficulty.allCases

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Level map")
                        .font(.largeTitle.bold())
                        .foregroundColor(.appTextPrimary)
                    Text("Browse your progress across every activity, difficulty, and level.")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.top, 24)

                ForEach(ActivityKind.allCases) { activity in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(activity.displayName)
                            .font(.headline)
                            .foregroundColor(.appTextPrimary)

                        ForEach(difficulties) { difficulty in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(difficulty.displayName)
                                    .font(.caption.bold())
                                    .foregroundColor(.appTextSecondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(1...AppData.maxLevelsPerDifficulty, id: \.self) { level in
                                            let stars = appData.stars(for: activity, difficulty: difficulty, level: level)
                                            levelChip(level: level, stars: stars)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .appCardStyle(cornerRadius: 20)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(LinearGradient.appBackgroundGradient.ignoresSafeArea())
        .navigationTitle("Level map")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func levelChip(level: Int, stars: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(level)")
                .font(.caption.bold())
                .foregroundColor(.appTextPrimary)
            HStack(spacing: 1) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < stars ? "star.fill" : "star")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(index < stars ? .appAccent : .appTextSecondary.opacity(0.4))
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            stars > 0 ? Color.appPrimary.opacity(0.95) : Color.appSurface.opacity(0.9),
                            Color.appBackground.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}


