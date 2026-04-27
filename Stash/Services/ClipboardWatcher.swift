import AppKit

final class ClipboardWatcher {
    var onCopy: (() -> Void)?

    private var timer: Timer?
    private var lastChangeCount: Int
    private let getChangeCount: () -> Int

    init() {
        let pb = NSPasteboard.general
        self.lastChangeCount = pb.changeCount
        self.getChangeCount = { NSPasteboard.general.changeCount }
    }

    init(changeCountProvider: @escaping () -> Int) {
        self.lastChangeCount = changeCountProvider()
        self.getChangeCount = changeCountProvider
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    deinit {
        stop()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func checkForChanges() {
        let current = getChangeCount()
        guard current != lastChangeCount else { return }
        lastChangeCount = current
        onCopy?()
    }
}
