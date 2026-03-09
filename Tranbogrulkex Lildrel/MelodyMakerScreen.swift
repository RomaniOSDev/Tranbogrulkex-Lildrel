import SwiftUI

struct MelodyMakerScreen: View {
    @StateObject private var viewModel: MelodyMakerViewModel

    let activity: ActivityKind
    let difficulty: Difficulty
    let level: Int
    let onFinished: (ActivityResult) -> Void
    let isPractice: Bool

    @EnvironmentObject private var appData: AppData
    @State private var showResultOnce: Bool = false
    @State private var selectedPaletteNote: Int? = nil

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
        _viewModel = StateObject(wrappedValue: MelodyMakerViewModel(activity: activity, difficulty: difficulty, level: level))
    }

    private var paletteNotes: [Int] {
        switch difficulty {
        case .easy:
            return [0, 1, 2]
        case .normal, .hard:
            return [0, 1, 2, 3]
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height: CGFloat = 200
                    VStack {
                        ZStack {
                            staffBackground(width: width, height: height)
                            targetGhostMelody(width: width, height: height)
                            placedNotes(width: width, height: height)
                            slotTapLayer(width: width, height: height)
                        }
                        .frame(height: height)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.appSurface)
                        )
                    }
                }
                .frame(height: 220)

                palette
                controls
                stats
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Melody Maker")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.isFinished) { finished in
            if finished, !showResultOnce {
                showResultOnce = true
                let result = viewModel.buildResult()
                if !isPractice {
                    onFinished(result)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rebuild the glowing phrase with your own notes.")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            Text("Tap a note in the palette, then tap a slot on the staff to place it. Fill as many slots as you can, then check your phrase.")
                .font(.subheadline)
                .foregroundColor(.appTextSecondary)

            if appData.guidedModeEnabled {
                Text("Guided hints are on. Match the bright circles to the shadow melody.")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func staffBackground(width: CGFloat, height: CGFloat) -> some View {
        Canvas { context, size in
            let lineCount = 4
            let spacing = height / CGFloat(lineCount + 1)

            for i in 1...lineCount {
                let y = CGFloat(i) * spacing
                var path = Path()
                path.move(to: CGPoint(x: 16, y: y))
                path.addLine(to: CGPoint(x: size.width - 16, y: y))
                context.stroke(path, with: .color(Color.appBackground.opacity(0.7)), lineWidth: 1)
            }
        }
    }

    private func targetGhostMelody(width: CGFloat, height: CGFloat) -> some View {
        let count = max(viewModel.slots.count, 1)
        let cellWidth = (width - 32) / CGFloat(count)
        let lineCount = 4
        let spacing = height / CGFloat(lineCount + 1)

        return ForEach(viewModel.slots) { slot in
            let x = 16 + CGFloat(slot.index) * cellWidth + cellWidth / 2
            let y = CGFloat(lineCount - slot.targetNote) * spacing
            Circle()
                .strokeBorder(Color.appAccent.opacity(0.25), lineWidth: 2)
                .background(
                    Circle().fill(Color.appAccent.opacity(0.08))
                )
                .frame(width: 22, height: 22)
                .position(x: x, y: y)
        }
    }

    private func placedNotes(width: CGFloat, height: CGFloat) -> some View {
        let count = max(viewModel.slots.count, 1)
        let cellWidth = (width - 32) / CGFloat(count)
        let lineCount = 4
        let spacing = height / CGFloat(lineCount + 1)

        return ForEach(viewModel.slots) { slot in
            if let placed = slot.placedNote {
                let x = 16 + CGFloat(slot.index) * cellWidth + cellWidth / 2
                let y = CGFloat(lineCount - placed) * spacing

                Circle()
                    .fill(Color.appPrimary)
                    .overlay(
                        Circle()
                            .stroke(Color.appBackground.opacity(0.9), lineWidth: 2)
                    )
                    .shadow(color: Color.appPrimary.opacity(0.7), radius: 10, x: 0, y: 4)
                    .frame(width: 24, height: 24)
                    .position(x: x, y: y)
                    .onTapGesture {
                        viewModel.clearSlot(at: slot.index)
                    }
            }
        }
    }

    private var palette: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note Palette")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(paletteNotes, id: \.self) { note in
                        Button(action: {
                            selectedPaletteNote = note
                        }) {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(selectedPaletteNote == note ? Color.appAccent : Color.appPrimary)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.appBackground.opacity(0.9), lineWidth: 2)
                                    )
                                    .shadow(color: Color.appPrimary.opacity(0.7), radius: 10, x: 0, y: 4)
                                    .overlay(
                                        Text(displayName(for: note))
                                            .font(.caption2.bold())
                                            .foregroundColor(.appBackground)
                                    )

                                Text(displayName(for: note))
                                    .font(.caption)
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.finish()
            }) {
                Text("Check Phrase")
                    .font(.subheadline.bold())
                    .foregroundColor(.appBackground)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.appPrimary)
                    )
            }
            .buttonStyle(.plain)
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Text("Tip: Longer correct streaks boost your streak stat and help you earn more stars.")
                .font(.footnote)
                .foregroundColor(.appTextSecondary)
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
                statBlock(title: "Filled", value: "\(filledCount)/\(viewModel.slots.count)")
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

    private var filledCount: Int {
        viewModel.slots.filter { $0.placedNote != nil }.count
    }
    private func slotTapLayer(width: CGFloat, height: CGFloat) -> some View {
        let count = max(viewModel.slots.count, 1)
        let cellWidth = (width - 32) / CGFloat(count)

        return HStack(spacing: 0) {
            ForEach(viewModel.slots) { slot in
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: cellWidth, height: height)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let note = selectedPaletteNote {
                            viewModel.place(note: note, at: slot.index)
                        }
                    }
            }
        }
        .frame(width: width - 32, height: height)
        .padding(.horizontal, 16)
    }

    private func displayName(for noteIndex: Int) -> String {
        switch noteIndex {
        case 0: return "Low"
        case 1: return "Mid"
        case 2: return "High"
        default: return "Bright"
        }
    }
}

