import SwiftUI

private struct OnboardingPageData: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let accent: Color
}

struct OnboardingContainerView: View {
    @EnvironmentObject private var appData: AppData
    @State private var currentIndex: Int = 0
    @State private var animateShape: Bool = false

    let onFinished: () -> Void

    private let pages: [OnboardingPageData] = [
        OnboardingPageData(
            title: "Feel the Beat",
            subtitle: "Tap glowing circles in time with the moving rhythm line.",
            accent: .appPrimary
        ),
        OnboardingPageData(
            title: "Shape the Melody",
            subtitle: "Drag bright notes onto the staff to match the ghost pattern.",
            accent: .appAccent
        ),
        OnboardingPageData(
            title: "Catch the Harmony",
            subtitle: "Listen to visual chord cues and pick the matching tiles.",
            accent: .appPrimary
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page, isActive: index == currentIndex, animateShape: $animateShape)
                        .tag(index)
                        .padding(.horizontal, 16)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animateShape = true
                }
            }
            .onChange(of: currentIndex) { _ in
                animateShape = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animateShape = true
                }
            }

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == currentIndex ? Color.appPrimary : Color.appSurface)
                            .frame(width: index == currentIndex ? 24 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentIndex)
                    }
                }

                Button(action: handlePrimaryButton) {
                    Text(currentIndex == pages.count - 1 ? "Start Playing" : "Next")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color.appPrimary.cornerRadius(14))
                }
                .buttonStyle(.plain)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

                Button(action: skip) {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            .background(
                LinearGradient(
                    colors: [Color.appSurface.opacity(0.96), Color.appBackground.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(LinearGradient.appBackgroundGradient.ignoresSafeArea())
    }

    private func handlePrimaryButton() {
        if currentIndex < pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
            }
        } else {
            finish()
        }
    }

    private func skip() {
        finish()
    }

    private func finish() {
        onFinished()
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPageData
    let isActive: Bool
    @Binding var animateShape: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 24)

                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(LinearGradient.appCardGradient)
                        .frame(height: 260)
                        .shadow(color: Color.black.opacity(0.45), radius: 24, x: 0, y: 18)

                    GeometryReader { proxy in
                        Canvas { context, size in
                            let width = size.width
                            let height = size.height

                            var path = Path()
                            let midY = height * 0.5
                            let amplitude = height * 0.18

                            let steps = 40
                            for i in 0...steps {
                                let progress = Double(i) / Double(steps)
                                let x = width * progress
                                let wave = sin(progress * .pi * 2 * 1.5)
                                let animatedWave = wave * Double(amplitude) * (animateShape ? 1.0 : 0.4)
                                let y = midY + CGFloat(animatedWave)

                                if i == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }

                            let strokeStyle = StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                            context.stroke(path, with: .color(page.accent), style: strokeStyle)

                            let beatCount = 6
                            for i in 0..<beatCount {
                                let progress = CGFloat(i) / CGFloat(max(beatCount - 1, 1))
                                let x = width * progress
                                let wave = sin(Double(progress) * .pi * 2 * 1.5)
                                let animatedWave = wave * Double(amplitude) * (animateShape ? 1.0 : 0.4)
                                let y = midY + CGFloat(animatedWave)

                                let baseSize: CGFloat = 30
                                let scale = animateShape ? 1.0 + 0.15 * sin(Double(i) + (isActive ? 1.0 : 0.0)) : 1.0
                                let size = baseSize * CGFloat(scale)

                                let rect = CGRect(
                                    x: x - size / 2,
                                    y: y - size / 2,
                                    width: size,
                                    height: size
                                )

                                let circlePath = Path(ellipseIn: rect)
                                context.fill(circlePath, with: .color(page.accent.opacity(0.85)))
                                context.stroke(circlePath, with: .color(Color.appBackground.opacity(0.8)), lineWidth: 2)
                            }
                        }
                        .padding(32)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(page.title)
                        .font(.title.bold())
                        .foregroundColor(.appTextPrimary)
                        .multilineTextAlignment(.leading)

                    Text(page.subtitle)
                        .font(.body)
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 0)
        }
    }
}

