import SwiftUI

struct ResultView: View {
    let payload: ResultPayload
    let onNextLevel: () -> Void
    let onRetry: () -> Void
    let onBackToLevels: () -> Void

    @State private var visibleStars: Int = 0
    @State private var showBanner: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if showBanner, !payload.newAchievements.isEmpty {
                    achievementBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                starRow

                statsCard

                if payload.newAchievements.isEmpty == false {
                    unlockedList
                }

                actions
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(LinearGradient.appBackgroundGradient.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            animateStars()
            if !payload.newAchievements.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showBanner = true
                    }
                }
            }
        }
    }

    private var achievementBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("New achievement")
                .font(.caption.bold())
                .foregroundColor(.appBackground)

            if let first = payload.newAchievements.first {
                Text(first.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.appBackground)
                Text(first.detail)
                    .font(.caption)
                    .foregroundColor(.appBackground.opacity(0.9))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.appAccent)
                .shadow(color: .black.opacity(0.28), radius: 16, x: 0, y: 10)
        )
    }

    private var starRow: some View {
        VStack(spacing: 16) {
            Text(payload.result.success ? "Pattern complete" : "Keep exploring")
                .font(.title2.bold())
                .foregroundColor(.appTextPrimary)

            HStack(spacing: 18) {
                ForEach(0..<3, id: \.self) { index in
                    let isFilled = index < visibleStars
                    Image(systemName: isFilled ? "star.fill" : "star")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(isFilled ? .appAccent : .appSurface)
                        .shadow(color: Color.appAccent.opacity(isFilled ? 0.9 : 0.0), radius: 16, x: 0, y: 6)
                        .scaleEffect(isFilled ? 1.1 : 0.9)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: visibleStars)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .appCardStyle(cornerRadius: 24)
    }

    private var statsCard: some View {
        let accuracyText = String(format: "%.0f%%", payload.result.accuracy * 100)
        let timeText = formattedTime(payload.result.timeElapsed)

        return VStack(alignment: .leading, spacing: 16) {
            Text("Session stats")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            HStack {
                statBlock(title: "Accuracy", value: accuracyText)
                statBlock(title: "Max streak", value: "\(payload.result.maxStreak)x")
                statBlock(title: "Time", value: timeText)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .appCardStyle(cornerRadius: 24)
    }

    private var unlockedList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unlocked this round")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            ForEach(payload.newAchievements, id: \.id) { achievement in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.appAccent)
                        .font(.system(size: 18, weight: .bold))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(achievement.title)
                            .font(.subheadline.bold())
                            .foregroundColor(.appTextPrimary)
                        Text(achievement.detail)
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(cornerRadius: 20)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button(action: onNextLevel) {
                Text(nextLevelTitle)
                    .font(.headline)
                    .foregroundColor(.appBackground)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.appPrimary)
                    )
            }
            .buttonStyle(.plain)
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Button(action: onRetry) {
                Text("Replay level")
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.appSurface)
                    )
            }
            .buttonStyle(.plain)
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Button(action: onBackToLevels) {
                Text("Back to levels")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
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

    private func animateStars() {
        visibleStars = 0
        let total = payload.result.starsEarned
        guard total > 0 else { return }
        for index in 0..<total {
            let delay = 0.1 + Double(index) * 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    visibleStars = index + 1
                }
            }
        }
    }

    private func formattedTime(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded()))
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%d:%02d", minutes, remaining)
    }

    private var nextLevelTitle: String {
        if payload.level >= AppData.maxLevelsPerDifficulty {
            return "Explore other levels"
        } else {
            return "Next level"
        }
    }
}

