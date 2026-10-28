import SwiftUI

/// A card picture the user tapped, by its `cornhub://media/` URL.
struct ZoomedImage: Identifiable {
    let url: URL
    var id: URL { url }

    var uiImage: UIImage? {
        MediaSchemeHandler.fileURL(for: url).flatMap { try? Data(contentsOf: $0) }.flatMap(UIImage.init(data:))
    }
}

/// Full-screen picture: pinch or double-tap to zoom, swipe down or tap ✕ to close.
struct ImageViewer: View {
    let image: ZoomedImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var settledScale: CGFloat = 1
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.bg.ignoresSafeArea()
            if let picture = image.uiImage {
                Image(uiImage: picture)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(dragOffset)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { scale = max(1, settledScale * $0.magnification) }
                            .onEnded { _ in settledScale = scale }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { if scale <= 1 { dragOffset = CGSize(width: 0, height: max(0, $0.translation.height)) } }
                            .onEnded { value in
                                if scale <= 1, value.translation.height > 100 { dismiss() }
                                withAnimation(.snappy) { dragOffset = .zero }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.snappy) {
                            scale = scale > 1 ? 1 : 2
                            settledScale = scale
                        }
                    }
                    .accessibilityLabel("Card picture")
                    .accessibilityIdentifier("image-viewer-picture")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView("Picture not found", systemImage: "photo")
            }
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                    .frame(width: Theme.minTarget, height: Theme.minTarget)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(16)
            .accessibilityLabel("Close picture")
            .accessibilityIdentifier("image-viewer-close")
        }
        .accessibilityIdentifier("image-viewer")
    }
}
