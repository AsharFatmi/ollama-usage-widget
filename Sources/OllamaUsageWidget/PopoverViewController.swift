import AppKit

@MainActor
final class PopoverViewController: NSViewController {
    private weak var controller: MenuBarController?

    init(controller: MenuBarController) {
        self.controller = controller
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 200))
    }

    func reloadData() {}
}
