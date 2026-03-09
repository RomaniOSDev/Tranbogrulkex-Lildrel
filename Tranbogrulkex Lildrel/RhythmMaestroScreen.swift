import SwiftUI

struct RhythmMaestroScreen: View {
    @StateObject private var viewModel: RhythmMaestroViewModel
    @State private var timer: Timer?

    let activity: ActivityKind
    let difficulty: Difficulty
    let level: Int
    let onFinished: (ActivityResult) -> Void
    let isPractice: Bool

    @EnvironmentObject private var appData: AppData
    @State private var comboMessageVisible: Bool = false

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
        _viewModel = StateObject(wrappedValue: RhythmMaestroViewModel(activity: activity, difficulty: difficulty, level: level))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                beatStrip
                comboLabel
                controls
                stats
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Rhythm Maestro")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startIfNeeded()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: viewModel.isFinished) { finished in
            if finished {
                timer?.invalidate()
                timer = nil
                if !isPractice {
                    let result = viewModel.buildResult()
                    onFinished(result)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Follow the glowing beat and tap in sync.")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            Text("Tap anywhere in the lane when the highlighted circle is active. Try to keep your streak alive.")
                .font(.subheadline)
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var comboLabel: some View {
        VStack(spacing: 4) {
            if comboMessageVisible {
                Text("Great streak!")
                    .font(.subheadline.bold())
                    .foregroundColor(.appAccent)
                    .transition(.opacity)
            }
            if appData.guidedModeEnabled {
                Text("Guided hints are on.")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var beatStrip: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ForEach([0, 1, 2, 3], id: \.self) { index in
                    let isActive = currentActiveIndex == index
                    let upcomingIndex = upcomingActiveIndex ?? -1
                    let isUpcoming = appData.guidedModeEnabled && upcomingIndex == index
                    Circle()
                        .fill(isActive ? Color.appPrimary : Color.appSurface)
                        .overlay(
                            Circle()
                                .stroke(Color.appAccent.opacity(isActive ? 1.0 : 0.0), lineWidth: 3)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.appAccent.opacity(isUpcoming ? 0.5 : 0.0), lineWidth: 2)
                        )
                        .shadow(color: Color.appPrimary.opacity(isActive ? 0.7 : 0.0), radius: isActive ? 18 : 0)
                        .frame(width: 64, height: 64)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActive)
                }
            }
            .frame(maxWidth: .infinity)

            Button(action: {
                viewModel.registerTap()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.appSurface)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.appPrimary.opacity(0.4), lineWidth: 1)
                        )

                    Text("Tap in time with the highlighted circle")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 12)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(action: {
                restart()
            }) {
                Text("Restart Pattern")
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

            Button(action: {
                viewModel.registerTap()
            }) {
                Text("Emphasize Beat")
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

    private var stats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            HStack {
                statBlock(
                    title: "Accuracy",
                    value: String(format: "%.0f%%", viewModel.accuracy * 100)
                )
                statBlock(
                    title: "Max streak",
                    value: "\(viewModel.maxStreak)x"
                )
                statBlock(
                    title: "Progress",
                    value: String(format: "%.0f%%", viewModel.progress * 100)
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

    private var currentActiveIndex: Int? {
        guard viewModel.currentStepIndex < viewModel.steps.count else { return nil }
        return viewModel.steps[viewModel.currentStepIndex].circleIndex
    }

    private var upcomingActiveIndex: Int? {
        let nextIndex = viewModel.currentStepIndex + 1
        guard nextIndex < viewModel.steps.count else { return nil }
        return viewModel.steps[nextIndex].circleIndex
    }

    private func startIfNeeded() {
        if !viewModel.isRunning && !viewModel.isFinished {
            viewModel.start()
        }
        startTimer()
    }

    private func restart() {
        timer?.invalidate()
        timer = nil
        viewModel.start()
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        let interval = viewModel.tickInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            viewModel.tick()
            handleComboHint()
        }
    }

    private func handleComboHint() {
        if viewModel.streak >= 5 && !comboMessageVisible {
            withAnimation(.easeInOut(duration: 0.3)) {
                comboMessageVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    comboMessageVisible = false
                }
            }
        }
    }
}

