import SwiftUI

struct SwipeDeleteRow<Content: View>: View {
    let canDelete: Bool
    let onDelete: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var isOpen = false

    private let deleteWidth: CGFloat = 88
    private let openThreshold: CGFloat = 44

    var body: some View {
        ZStack(alignment: .trailing) {
            if canDelete {
                Button(role: .destructive, action: delete) {
                    Label(String(localized: "Удалить"), systemImage: "trash")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: deleteWidth)
                        .frame(maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .background(Color.red, in: RoundedRectangle(cornerRadius: EditorTheme.cardRadius, style: .continuous))
                .opacity(offset < 0 ? 1 : 0)
            }

            content()
                .offset(x: offset)
                .gesture(canDelete ? swipeGesture : nil)
        }
        .clipShape(RoundedRectangle(cornerRadius: EditorTheme.cardRadius, style: .continuous))
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .onChanged { value in
                let translation = value.translation.width
                if translation < 0 {
                    offset = max(translation, -deleteWidth)
                } else if isOpen {
                    offset = min(-deleteWidth + translation, 0)
                }
            }
            .onEnded { value in
                let translation = value.translation.width
                withAnimation(.snappy) {
                    if isOpen {
                        isOpen = translation > openThreshold
                        offset = isOpen ? -deleteWidth : 0
                    } else {
                        isOpen = translation < -openThreshold
                        offset = isOpen ? -deleteWidth : 0
                    }
                }
            }
    }

    private func delete() {
        withAnimation(.snappy) {
            offset = 0
            isOpen = false
        }
        onDelete()
    }
}
