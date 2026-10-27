import PhotosUI
import SwiftUI

/// Full-screen Add card, also used to edit an existing note.
struct NoteEditorScreen: View {
    @State private var model: NoteEditorModel
    let onSaved: (Anki_Notes_Note) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Int?
    @State private var selections: [Int: TextSelection] = [:]
    @State private var recorder = AudioRecorder()
    @State private var photoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var newTag = ""
    @State private var addingTag = false

    init(backend: Backend, mode: NoteEditorModel.Mode, onSaved: @escaping (Anki_Notes_Note) -> Void = { _ in }) {
        _model = State(initialValue: NoteEditorModel(backend: backend, mode: mode))
        self.onSaved = onSaved
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if model.isLoaded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !model.isEditing { chips }
                        fieldBlocks
                        tagsRow
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)
                if !model.isEditing {
                    autoFill.padding(.horizontal, 16).padding(.top, 8)
                }
                submitButton
            } else if let message = model.errorMessage {
                ContentUnavailableView("Could not open the editor", systemImage: "exclamationmark.triangle", description: Text(message))
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .task { await model.load() }
        .sensoryFeedback(.success, trigger: model.addedCount)
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await insertPhoto(from: item) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in Task { await insertPicture(data) } }.ignoresSafeArea()
        }
        .toolbar { keyboardToolbar }
        .alert("New tag", isPresented: $addingTag) {
            TextField("Tag", text: $newTag).textInputAutocapitalization(.never)
            Button("Add") {
                model.addTag(newTag)
                newTag = ""
            }
            Button("Cancel", role: .cancel) { newTag = "" }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { model.errorMessage != nil && model.isLoaded }, set: { if !$0 { model.errorMessage = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .alert("Recording", isPresented: Binding(
            get: { recorder.failure != nil }, set: { if !$0 { recorder.failure = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(recorder.failure ?? "")
        }
    }

    // MARK: Header and chips

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark").frame(width: Theme.minTarget, height: Theme.minTarget)
            }
            .accessibilityLabel("Close")
            .accessibilityIdentifier("editor-close")
            Spacer()
            Text(model.isEditing ? "Edit note" : "New card").font(.display(20, relativeTo: .headline)).foregroundStyle(Theme.text)
            Spacer()
            Color.clear.frame(width: Theme.minTarget, height: Theme.minTarget)
        }
        .padding(.horizontal, 8)
        .foregroundStyle(Theme.text)
    }

    private var chips: some View {
        HStack(spacing: 8) {
            Menu {
                Picker("Deck", selection: $model.deckID) {
                    ForEach(model.decks, id: \.id) { Text($0.name).tag($0.id) }
                }
            } label: {
                chip(model.deckName, symbol: "rectangle.stack")
            }
            .accessibilityLabel("Deck: \(model.deckName)")
            .accessibilityIdentifier("editor-deck-chip")
            Menu {
                Picker("Note type", selection: Binding(get: { model.notetypeID }, set: { model.chooseNotetype($0) })) {
                    ForEach(model.notetypes, id: \.id) { Text($0.name).tag($0.id) }
                }
            } label: {
                chip(model.notetypeName, symbol: "doc.text")
            }
            .accessibilityLabel("Note type: \(model.notetypeName)")
            .accessibilityIdentifier("editor-notetype-chip")
            Spacer(minLength: 0)
        }
    }

    private func chip(_ title: String, symbol: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
            Text(title).lineLimit(1)
            Image(systemName: "chevron.down").font(.caption2)
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 12)
        .frame(minHeight: Theme.minTarget)
        .background(Theme.control, in: Capsule())
        .foregroundStyle(Theme.text)
    }

    // MARK: Fields

    @ViewBuilder private var fieldBlocks: some View {
        if model.isChinese, model.fields.count >= 5 {
            HStack(alignment: .bottom, spacing: 12) {
                fieldBlock(ChineseNotetype.Field.hanzi, large: true)
                pictureTile
            }
            HStack(alignment: .top, spacing: 12) {
                fieldBlock(ChineseNotetype.Field.pinyin, accent: true)
                fieldBlock(ChineseNotetype.Field.english)
            }
            ForEach([ChineseNotetype.Field.example, ChineseNotetype.Field.examplePinyin,
                     ChineseNotetype.Field.exampleEnglish, ChineseNotetype.Field.audio], id: \.self) { fieldBlock($0) }
        } else {
            ForEach(model.fields.indices, id: \.self) { fieldBlock($0) }
        }
    }

    private func fieldBlock(_ index: Int, large: Bool = false, accent: Bool = false) -> some View {
        let name = model.fieldNames.indices.contains(index) ? model.fieldNames[index] : "Field \(index + 1)"
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name).inkLabel().foregroundStyle(Theme.muted)
                Spacer()
                if !model.isEditing {
                    Button { model.toggleSticky(index) } label: {
                        Image(systemName: model.isSticky(index) ? "pin.fill" : "pin")
                            .frame(width: Theme.minTarget, height: 28)
                    }
                    .foregroundStyle(model.isSticky(index) ? Theme.accent : Theme.muted)
                    .accessibilityLabel("Keep \(name) after adding")
                    .accessibilityValue(model.isSticky(index) ? "On" : "Off")
                }
            }
            TextField(name, text: fieldBinding(index), selection: selectionBinding(index), axis: .vertical)
                .font(large ? .display(DisplaySize.hanziField, relativeTo: .largeTitle) : .body)
                .foregroundStyle(accent ? Theme.accent : Theme.text)
                .focused($focused, equals: index)
                .padding(12)
                .frame(minHeight: Theme.minTarget)
                .background(Theme.control, in: RoundedRectangle(cornerRadius: Theme.Radius.photo))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.photo)
                        .strokeBorder(focused == index ? Theme.accent : .clear, lineWidth: 2)
                }
                .accessibilityLabel(name)
                .accessibilityIdentifier("editor-field-\(index)")
        }
    }

    private func fieldBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { model.fields.indices.contains(index) ? model.fields[index] : "" },
            set: { if model.fields.indices.contains(index) { model.fields[index] = $0 } })
    }

    private func selectionBinding(_ index: Int) -> Binding<TextSelection?> {
        Binding(get: { selections[index] }, set: { selections[index] = $0 })
    }

    private var pictureTile: some View {
        let pictureIndex = model.pictureIndex(fallback: nil)
        let hasPicture = pictureIndex.map { !model.fields[$0].isEmpty } ?? false
        return Menu {
            Button("Photo library", systemImage: "photo") { showPhotoPicker = true }
            if CameraPicker.isAvailable { Button("Camera", systemImage: "camera") { showCamera = true } }
        } label: {
            Image(systemName: hasPicture ? "photo.badge.checkmark" : "photo.badge.plus")
                .font(.title2)
                .foregroundStyle(hasPicture ? Theme.accent : Theme.text2)
                .frame(width: 88, height: 88)
                .background(Theme.control, in: RoundedRectangle(cornerRadius: Theme.Radius.photo))
        }
        .accessibilityLabel(hasPicture ? "Picture added. Change picture" : "Add picture")
        .accessibilityIdentifier("editor-picture-tile")
    }

    private var autoFill: some View {
        Button { Task { await model.autoFill() } } label: {
            Label(model.isAutoFilling ? "Filling…" : "Auto-fill example, audio and picture", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: Theme.minTarget)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(Theme.accent)
        .disabled(model.isAutoFilling || !model.canSubmit)
        .accessibilityHint("Fills empty example and audio fields from the first field")
        .accessibilityIdentifier("editor-autofill")
    }

    // MARK: Tags

    private var tagsRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tags").inkLabel().foregroundStyle(Theme.muted)
            FlowLayout(spacing: 8) {
                ForEach(model.tags, id: \.self) { tag in
                    Button { model.removeTag(tag) } label: {
                        HStack(spacing: 4) {
                            Text(tag)
                            Image(systemName: "xmark").font(.caption2)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .frame(minHeight: Theme.minTarget)
                        .background(Theme.control, in: Capsule())
                    }
                    .foregroundStyle(Theme.text)
                    .accessibilityLabel("Tag \(tag). Remove")
                }
                Menu {
                    Button("New tag…", systemImage: "plus") { addingTag = true }
                    ForEach(model.knownTags.filter { !model.tags.contains($0) }.prefix(20), id: \.self) { tag in
                        Button(tag) { model.addTag(tag) }
                    }
                } label: {
                    Label("tag", systemImage: "plus")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .frame(minHeight: Theme.minTarget)
                        .overlay(Capsule().strokeBorder(Theme.accent))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityLabel("Add tag")
                .accessibilityIdentifier("editor-add-tag")
            }
        }
    }

    // MARK: Submit

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            Text(model.isEditing ? "Save" : "Add card").font(.headline).frame(maxWidth: .infinity, minHeight: Theme.minTarget)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(Theme.accent)
        .foregroundStyle(Theme.onAccent)
        .disabled(!model.canSubmit)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        // The floating keyboard accessory sits over the bottom of the content; keep the button clear of it.
        .padding(.bottom, focused == nil ? 0 : 56)
        .accessibilityIdentifier("editor-submit")
    }

    private func submit() async {
        if model.isEditing {
            if let saved = await model.save() {
                onSaved(saved)
                dismiss()
            }
        } else if await model.add() {
            focused = 0
        }
    }

    // MARK: Formatting and media

    @ToolbarContentBuilder private var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Button { format(.bold) } label: { Image(systemName: "bold") }.accessibilityLabel("Bold")
            Button { format(.italic) } label: { Image(systemName: "italic") }.accessibilityLabel("Italic")
            Button { format(.underline) } label: { Image(systemName: "underline") }.accessibilityLabel("Underline")
            Button { format(.cloze(model.nextClozeNumber)) } label: { Image(systemName: "curlybraces") }
                .accessibilityLabel("Cloze")
            Spacer()
            Button { showPhotoPicker = true } label: { Image(systemName: "photo") }.accessibilityLabel("Photo library")
            if CameraPicker.isAvailable {
                Button { showCamera = true } label: { Image(systemName: "camera") }.accessibilityLabel("Camera")
            }
            Button { Task { await toggleRecording() } } label: {
                Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic")
                    .foregroundStyle(recorder.isRecording ? Theme.again : Theme.accent)
            }
            .accessibilityLabel(recorder.isRecording ? "Stop recording" : "Record audio")
        }
    }

    private func format(_ style: FieldFormatting.Style) {
        guard let index = focused, model.fields.indices.contains(index) else { return }
        var text = model.fields[index]
        FieldFormatting.apply(style, to: &text, selection: selections[index])
        model.fields[index] = text
        selections[index] = nil
    }

    private func insertPhoto(from item: PhotosPickerItem) async {
        defer { photoItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            model.errorMessage = "That photo could not be loaded."
            return
        }
        let jpeg = UIImage(data: data)?.jpegData(compressionQuality: 0.8) ?? data
        await insertPicture(jpeg)
    }

    private func insertPicture(_ data: Data) async {
        guard let index = model.pictureIndex(fallback: focused ?? 0),
            let name = await model.storeMedia(name: "photo.jpg", data: data)
        else { return }
        model.append("<img src=\"\(name)\">", toField: index)
    }

    private func toggleRecording() async {
        if recorder.isRecording {
            guard let data = recorder.stop(), let index = model.audioIndex(fallback: focused ?? 0),
                let name = await model.storeMedia(name: "recording.m4a", data: data)
            else { return }
            model.append("[sound:\(name)]", toField: index)
        } else {
            await recorder.start()
        }
    }
}

/// Wraps chips onto as many lines as needed.
private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: maxX, height: y + rowHeight), origins)
    }
}
