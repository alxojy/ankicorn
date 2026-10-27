import SwiftUI

/// Full-screen review: header, card panel, grade bar, swipe to grade, congrats.
struct ReviewScreen: View {
    @State private var model: ReviewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("swipeGradeCount") private var swipeCount = 0
    @State private var drag: CGFloat = 0
    @State private var pastThreshold = false

    private static let threshold: CGFloat = 110

    init(backend: Backend, deckID: Int64?) {
        _model = State(initialValue: ReviewModel(backend: backend, deckID: deckID))
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            switch model.phase {
            case .loading:
                ProgressView().frame(maxHeight: .infinity)
            case .failed(let message):
                ContentUnavailableView {
                    Label("Review stopped", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try again") { Task { await model.start() } }.frame(minHeight: Theme.minTarget)
                }
            case .congrats:
                CongratsScreen(info: model.congrats) { dismiss() }
            case .card:
                cardPanel
                if swipeCount < 5, model.revealed {
                    Text("Swipe right for Good, left for Again")
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
                gradeBar
            }
        }
        .padding(.horizontal, 16)
        .background(Theme.bg.ignoresSafeArea())
        .task { await model.start() }
        .sensoryFeedback(.impact, trigger: pastThreshold)
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").frame(width: Theme.minTarget, height: Theme.minTarget)
                }
                .accessibilityLabel("Close review")
                .accessibilityIdentifier("review-close")
                Spacer()
                Button { Task { await model.undo() } } label: {
                    Image(systemName: "arrow.uturn.backward").frame(width: Theme.minTarget, height: Theme.minTarget)
                }
                .disabled(model.undoLabel.isEmpty)
                .accessibilityLabel(model.undoLabel.isEmpty ? "Undo" : model.undoLabel)
                .accessibilityIdentifier("review-undo")
                Menu {
                    Button("Redo", systemImage: "arrow.uturn.forward") { Task { await model.redo() } }
                        .disabled(model.redoLabel.isEmpty)
                    Text("Flag, mark, bury and more are coming soon")
                } label: {
                    Image(systemName: "ellipsis").frame(width: Theme.minTarget, height: Theme.minTarget)
                }
                .accessibilityLabel("More")
            }
            .foregroundStyle(Theme.text)
            if model.phase == .card {
                ProgressView(value: model.progress).tint(Theme.accent)
                    .accessibilityLabel("Progress")
                HStack(spacing: 16) {
                    count(model.counts.new, Theme.new, "new")
                    count(model.counts.learning, Theme.learning, "learning")
                    count(model.counts.review, Theme.accent, "to review")
                }
            }
        }
    }

    private func count(_ value: Int, _ color: Color, _ name: String) -> some View {
        Text("\(value)").font(.subheadline.weight(.semibold))
            .foregroundStyle(value == 0 ? Theme.zero : color)
            .accessibilityLabel("\(value) \(name)")
    }

    private var cardPanel: some View {
        let progress = max(-1, min(1, drag / Self.threshold))
        let tint = progress >= 0 ? Theme.accent : Theme.again
        return ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.reviewCard).fill(Theme.card)
            CardWebView(
                html: model.revealed ? model.answerHTML : model.questionHTML, css: model.rendered?.css ?? "")
                .padding(16)
            RoundedRectangle(cornerRadius: Theme.Radius.reviewCard)
                .strokeBorder(tint, lineWidth: 3)
                .shadow(color: tint.opacity(0.8), radius: 16)
                .opacity(abs(progress))
            if abs(progress) > 0.3 {
                Text(stamp(progress))
                    .font(.display(DisplaySize.answer, relativeTo: .title))
                    .foregroundStyle(tint)
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(tint, lineWidth: 3))
                    .rotationEffect(.degrees(progress >= 0 ? -12 : 12))
            }
        }
        .frame(maxHeight: .infinity)
        .offset(x: drag)
        .rotationEffect(.degrees(Double(drag) / 20))
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.snappy) { model.reveal() } }
        .gesture(swipe)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.revealed ? "Answer side. Double tap a grade below." : "Question. Double tap to show answer.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { model.reveal() }
        .accessibilityIdentifier("review-card")
    }

    private func stamp(_ progress: CGFloat) -> String {
        progress >= 0 ? "GOOD · \(model.interval(.good))" : "AGAIN · \(model.interval(.again))"
    }

    private var swipe: some Gesture {
        DragGesture()
            .onChanged { value in
                guard model.revealed else { return }
                drag = value.translation.width
                let past = abs(drag) >= Self.threshold
                if past != pastThreshold { pastThreshold = past }
            }
            .onEnded { value in
                guard model.revealed else { return }
                let width = value.translation.width
                pastThreshold = false
                withAnimation(.snappy) { drag = 0 }
                guard abs(width) >= Self.threshold else { return }
                swipeCount += 1
                Task { await model.answer(width > 0 ? .good : .again) }
            }
    }

    private var gradeBar: some View {
        HStack(spacing: 8) {
            grade("Again", .again, Theme.again, filled: false)
            grade("Hard", .hard, Theme.text2, filled: false)
            grade("Good", .good, Theme.accent, filled: true)
            grade("Easy", .easy, Theme.easy, filled: false)
        }
        .padding(.bottom, 8)
        .opacity(model.revealed ? 1 : 0.35)
        .allowsHitTesting(model.revealed)
    }

    private func grade(
        _ title: String, _ rating: Anki_Scheduler_CardAnswer.Rating, _ color: Color, filled: Bool
    ) -> some View {
        Button {
            Task { await model.answer(rating) }
        } label: {
            VStack(spacing: 2) {
                Text(title).font(.headline)
                Text(model.interval(rating)).font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(filled ? Theme.onAccent : color)
            .background(filled ? color : Theme.control, in: RoundedRectangle(cornerRadius: Theme.Radius.photo))
        }
        .accessibilityLabel("\(title), next review in \(model.interval(rating))")
        .accessibilityIdentifier("grade-\(title.lowercased())")
    }
}
