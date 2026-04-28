import SwiftUI

struct ClipContextMenu: View {
    let clip: Clip
    let store: ClipboardStore
    var onPaste: () -> Void = {}
    var onEdit: (() -> Void)? = nil

    @State private var isRenaming = false
    @State private var newName = ""

    var body: some View {
        Group {
            Button("Paste") { onPaste() }

            Button("Copy Again") {
                clip.writeToPasteboard()
            }

            Divider()

            Button(clip.isPinned ? "Unpin" : "Pin") {
                store.togglePin(clip)
            }

            if !store.pinboards.isEmpty {
                Menu("Move to Pinboard") {
                    Button("Remove from Pinboard") {
                        store.moveClipToPinboard(clip, pinboardId: nil)
                    }
                    Divider()
                    ForEach(store.sortedPinboards) { board in
                        Button(board.name) {
                            store.moveClipToPinboard(clip, pinboardId: board.id)
                        }
                    }
                }
            }

            if clip.type == .text || clip.type == .code {
                Button("Edit") {
                    onEdit?()
                }
            }

            if clip.type == .image || clip.type == .file {
                Button("Rename...") {
                    newName = clip.fileName ?? clip.displayTitle
                    isRenaming = true
                }
            }

            Divider()

            Button("Delete", role: .destructive) {
                store.deleteClip(clip)
            }
        }
        .alert("Rename", isPresented: $isRenaming) {
            TextField("Name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                clip.fileName = newName
            }
        }
    }
}

struct EditClipView: View {
    let clip: Clip
    let store: ClipboardStore
    @State private var text: String
    @Environment(\.dismiss) private var dismiss

    init(clip: Clip, store: ClipboardStore) {
        self.clip = clip
        self.store = store
        self._text = State(initialValue: clip.textContent ?? "")
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Clip")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)

            TextEditor(text: $text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white)
                .padding(8)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(minHeight: 150)

            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()

                Button("Save") {
                    store.updateClipText(clip, newText: text)
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color(red: 244/255, green: 162/255, blue: 97/255))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .frame(width: 400)
        .background(Color(red: 15/255, green: 23/255, blue: 42/255))
    }
}
