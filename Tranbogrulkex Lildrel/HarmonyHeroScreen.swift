import SwiftUI

struct HarmonyHeroScreen: View {
    @StateObject private var viewModel: HarmonyHeroViewModel

    let activity: ActivityKind
    let difficulty: Difficulty
    let level: Int
    let onFinished: (ActivityResult) -> Void

    @State private var hasReportedResult: Bool = false
    let isPractice: Bool

    @EnvironmentObject private var appData: AppData

    init(
        activity: ActivityKind,
        difficulty: Difficulty,
        level: Int,
        isPractice: Bool,
        onFinished: @escaping (ActivityResult) -> Void
    ) {
        self.activity = activity
        self.difficulty = difficulty
        self.level = level
        self.onFinished = onFinished
        self.isPractice = isPractice
        _viewModel = StateObject(wrappedValue: HarmonyHeroViewModel(activity: activity, difficulty: difficulty, level: level))
    }

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                VStack(spacing: 16) {
                    targetCard
                    chordGrid
                }

                stats
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Harmony Hero")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.isFinished) { finished in
            if finished, !hasReportedResult {
                hasReportedResult = true
                let result = viewModel.buildResult()
                if !isPractice {
                    onFinished(result)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Match the highlighted harmony tile to its partner.")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            Text("Each round shows a cue label at the top. Tap the tile that feels like the best continuation of that pattern.")
                .font(.subheadline)
                .foregroundColor(.appTextSecondary)

            if appData.guidedModeEnabled {
                Text("Guided hints are on. After a miss, the matching tile is softly highlighted.")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var targetCard: some View {
        let label = chordLabel(for: currentTargetIndex)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Current cue")
                .font(.caption)
                .foregroundColor(.appTextSecondary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label.title)
                        .font(.title3.bold())
                        .foregroundColor(.appTextPrimary)
                    Text(label.subtitle)
                        .font(.footnote)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }

                Spacer()

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appSurface)
                    .frame(width: 60, height: 60)
                    .overlay(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.appAccent, lineWidth: 3)
                                .blur(radius: 2)
                            Image(systemName: "triangle.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.appAccent)
                        }
                    )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.appSurface)
        )
    }

    private var chordGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose the matching harmony")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    optionView(at: 0)
                    optionView(at: 1)
                }
                HStack(spacing: 12) {
                    optionView(at: 2)
                    optionView(at: 3)
                }
            }
        }
    }

    @ViewBuilder
    private func optionView(at optionIndex: Int) -> some View {
        if optionIndex < currentRound.options.count {
            let chordIndex = currentRound.options[optionIndex]
            let label = chordLabel(for: chordIndex)
            let isSelected = currentRound.selectedIndex == optionIndex
            let isCorrect = currentRound.isCorrect == true && isSelected
            let isWrong = currentRound.isCorrect == false && isSelected
            let shouldHintCorrect =
                appData.guidedModeEnabled &&
                currentRound.isCorrect == false &&
                currentRound.selectedIndex != nil &&
                chordIndex == currentRound.targetIndex

            Button(action: {
                viewModel.selectOption(at: optionIndex)
            }) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(label.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.appTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(label.subtitle)
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(backgroundColor(isSelected: isSelected, isCorrect: isCorrect, isWrong: isWrong, hint: shouldHintCorrect))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(borderColor(isSelected: isSelected, isCorrect: isCorrect, isWrong: isWrong, hint: shouldHintCorrect), lineWidth: isSelected || shouldHintCorrect ? 2 : 1)
                )
                .shadow(color: Color.black.opacity(isSelected ? 0.25 : 0.0), radius: isSelected ? 12 : 0, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        } else {
            Color.clear
                .frame(maxWidth: .infinity)
        }
    }

    private func backgroundColor(isSelected: Bool, isCorrect: Bool, isWrong: Bool, hint: Bool) -> Color {
        if isCorrect {
            return .appPrimary
        } else if isWrong {
            return Color.red.opacity(0.4)
        } else if hint {
            return Color.appSurface.opacity(0.9)
        } else if isSelected {
            return Color.appSurface.opacity(0.9)
        } else {
            return Color.appSurface
        }
    }

    private func borderColor(isSelected: Bool, isCorrect: Bool, isWrong: Bool, hint: Bool) -> Color {
        if isCorrect {
            return .appBackground
        } else if isWrong {
            return Color.red.opacity(0.9)
        } else if hint {
            return .appAccent
        } else if isSelected {
            return .appAccent
        } else {
            return Color.appBackground.opacity(0.8)
        }
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            HStack {
                statBlock(title: "Accuracy", value: String(format: "%.0f%%", viewModel.accuracy * 100))
                statBlock(title: "Max streak", value: "\(viewModel.maxStreak)x")
                statBlock(title: "Round", value: "\(viewModel.currentRoundIndex + 1)/\(viewModel.rounds.count)")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.appSurface)
        )
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
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private var currentRound: HarmonyHeroViewModel.Round {
        if viewModel.currentRoundIndex < viewModel.rounds.count {
            return viewModel.rounds[viewModel.currentRoundIndex]
        } else if let last = viewModel.rounds.last {
            return last
        } else {
            return HarmonyHeroViewModel.Round(targetIndex: 0, options: [0, 1, 2, 3])
        }
    }

    private var currentTargetIndex: Int {
        currentRound.targetIndex
    }

    private func chordLabel(for index: Int) -> (title: String, subtitle: String) {
        let namesEasy = [
            ("Bright I", "Simple open harmony"),
            ("Soft ii", "Gentle step upward"),
            ("Bold IV", "Strong lift in color"),
            ("Calm V", "Stable leading tone"),
            ("Warm vi", "Smooth descending color"),
            ("Wide I", "Expanded root color")
        ]

        let namesNormal = [
            ("Lifted I", "Root color with extra sparkle"),
            ("Flowing ii", "Upward color with a light tilt"),
            ("Glow IV", "Open shape with soft edge"),
            ("Drive V", "Forward motion with tension"),
            ("Shade vi", "Smooth and mellow shape"),
            ("Turnaround", "Short looping pattern"),
            ("Echo I", "Root color returning home"),
            ("Split V", "Leaning above the root")
        ]

        let namesHard = [
            ("Drift I", "Floating root color"),
            ("Sharp II", "Tilted above the root"),
            ("Wide IV", "Open, layered build"),
            ("Stacked V", "Dense upward motion"),
            ("Soft VII", "Gentle high color"),
            ("Color I", "Root with added shimmer"),
            ("Stretch IV", "Pulled outward layers"),
            ("Glow VI", "Deep, glowing pattern"),
            ("Slide II", "Sliding entry tone"),
            ("Shift V", "Shifting tension shape")
        ]

        switch difficulty {
        case .easy:
            let safeIndex = max(0, min(index, namesEasy.count - 1))
            return namesEasy[safeIndex]
        case .normal:
            let safeIndex = max(0, min(index, namesNormal.count - 1))
            return namesNormal[safeIndex]
        case .hard:
            let safeIndex = max(0, min(index, namesHard.count - 1))
            return namesHard[safeIndex]
        }
    }
}

