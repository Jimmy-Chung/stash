import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @ObservedObject var store: ClipboardStore
    @State private var isAddingPinboard = false
    @State private var newPinboardName = ""
    @State private var editingPinboard: Pinboard?
    @State private var editingName = ""
    @FocusState private var isEditingFocused: Bool
    @FocusState private var isNewPinboardFocused: Bool

    private let accentColor = Color(red: 244/255, green: 162/255, blue: 97/255)

    var body: some View {
        VStack(spacing: 0) {
            // All clips
            SidebarItem(
                icon: "tray.full",
                name: "All Clips",
                count: store.clips.count,
                isActive: store.activePinboardId == nil,
                accentColor: accentColor
            ) {
                DispatchQueue.main.async {
                    store.activePinboardId = nil
                    store.selectedIndex = 0
                }
            }

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 6)

            // Pinboards header
            HStack {
                Text("Pinboards")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .textCase(.uppercase)
                Spacer()
                Button(action: { isAddingPinboard = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 4)

            // Pinboard list
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 2) {
                    ForEach(store.sortedPinboards) { board in
                        pinboardRow(board)
                    }
                }
                .padding(.horizontal, 4)
            }

            // New pinboard input
            if isAddingPinboard {
                HStack(spacing: 6) {
                    TextField("Name", text: $newPinboardName, onCommit: addPinboard)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .focused($isNewPinboardFocused)

                    Button(action: addPinboard) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10))
                            .foregroundColor(accentColor)
                    }
                    .buttonStyle(.plain)

                    Button(action: { isAddingPinboard = false; newPinboardName = "" }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            }

            Spacer()
        }
        .frame(width: 184)
        .padding(.top, 12)
        .background(Color.white.opacity(0.03))
        .onChange(of: isAddingPinboard) { newValue in
            if newValue {
                isNewPinboardFocused = true
            }
        }
    }

    @ViewBuilder
    private func pinboardRow(_ board: Pinboard) -> some View {
        let isActive = store.activePinboardId == board.id
        let clipCount = store.clips.filter { $0.pinboardId == board.id }.count

        Button(action: {
            if editingPinboard?.id != board.id {
                DispatchQueue.main.async {
                    store.activePinboardId = board.id
                    store.selectedIndex = 0
                }
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: board.icon)
                    .font(.system(size: 12))
                    .foregroundColor(isActive ? accentColor : .white.opacity(0.5))

                if editingPinboard?.id == board.id {
                    TextField(board.name, text: $editingName, onCommit: { renamePinboard(board) })
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .focused($isEditingFocused)
                } else {
                    Text(board.name)
                        .font(.system(size: 12))
                        .foregroundColor(isActive ? .white : .white.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()

                if isActive {
                    Text("\(clipCount)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(accentColor.opacity(0.7))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isActive ? accentColor.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onDrop(of: [.text], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            provider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, _ in
                guard let data = data as? Data,
                      let idString = String(data: data, encoding: .utf8),
                      let id = UUID(uuidString: idString),
                      let clip = store.clips.first(where: { $0.id == id }) else { return }
                DispatchQueue.main.async {
                    store.moveClipToPinboard(clip, pinboardId: board.id)
                }
            }
            return true
        }
        .contextMenu {
            Button("Rename") {
                editingPinboard = board
                editingName = board.name
                DispatchQueue.main.async {
                    isEditingFocused = true
                }
            }
            Divider()
            Button("Delete", role: .destructive) {
                DispatchQueue.main.async {
                    store.deletePinboard(board)
                }
            }
        }
    }

    private func addPinboard() {
        let name = newPinboardName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        isNewPinboardFocused = false
        isAddingPinboard = false
        newPinboardName = ""
        DispatchQueue.main.async {
            store.createPinboard(name: name)
        }
    }

    private func renamePinboard(_ board: Pinboard) {
        let name = editingName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            editingPinboard = nil
            return
        }
        store.renamePinboard(board, newName: name)
        editingPinboard = nil
    }
}

private struct SidebarItem: View {
    let icon: String
    let name: String
    let count: Int
    let isActive: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(isActive ? accentColor : .white.opacity(0.5))
                Text(name)
                    .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? .white : .white.opacity(0.7))
                Spacer()
                Text("\(count)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(isActive ? accentColor.opacity(0.7) : .white.opacity(0.4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isActive ? accentColor.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }
}
