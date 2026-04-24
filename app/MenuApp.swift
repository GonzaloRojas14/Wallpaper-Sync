import Cocoa
import AVFoundation
import QuartzCore

// MARK: - Design Tokens
struct Theme {
    static let bg        = NSColor(red: 0.08, green: 0.08, blue: 0.14, alpha: 1)
    static let cardBg    = NSColor(red: 0.12, green: 0.12, blue: 0.20, alpha: 1)
    static let cardHover = NSColor(red: 0.16, green: 0.16, blue: 0.26, alpha: 1)
    static let accent    = NSColor(red: 0.55, green: 0.36, blue: 1.0, alpha: 1)
    static let accent2   = NSColor(red: 0.91, green: 0.27, blue: 0.37, alpha: 1)
    static let textPri   = NSColor.white
    static let textSec   = NSColor(white: 1, alpha: 0.55)
    static let cardRadius: CGFloat = 14
    static let cardW: CGFloat = 240
    static let cardH: CGFloat = 175
    static let thumbH: CGFloat = 145
    static let gap: CGFloat = 16
    static let pad: CGFloat = 24
}

// MARK: - Thumbnail Cache
class ThumbCache {
    static let shared = ThumbCache()
    private var cache: [String: NSImage] = [:]

    func get(_ path: String, size: NSSize, completion: @escaping (NSImage) -> Void) {
        if let img = cache[path] { completion(img); return }
        DispatchQueue.global(qos: .userInitiated).async {
            let url = URL(fileURLWithPath: path)
            let asset = AVURLAsset(url: url)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            gen.maximumSize = CGSize(width: size.width * 2, height: size.height * 2)
            let time = CMTime(seconds: 1.0, preferredTimescale: 600)
            if let cgImg = try? gen.copyCGImage(at: time, actualTime: nil) {
                let img = NSImage(cgImage: cgImg, size: size)
                self.cache[path] = img
                DispatchQueue.main.async { completion(img) }
            }
        }
    }
}

// MARK: - Wallpaper Card
class WallpaperCard: NSView {
    let videoPath: String
    let videoName: String
    var isActive: Bool = false { didSet { needsDisplay = true; updateBorder() } }
    var isHovered: Bool = false { didSet { needsDisplay = true } }
    var onClick: (() -> Void)?
    var onDelete: (() -> Void)?
    var thumbHeight: CGFloat = Theme.thumbH

    private let thumbView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let checkBadge = NSTextField(labelWithString: "✓")
    private var trackingArea: NSTrackingArea?

    init(path: String, name: String) {
        self.videoPath = path
        self.videoName = name
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = Theme.cardRadius
        layer?.masksToBounds = true
        layer?.borderWidth = 0
        setupViews()
        loadThumb()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        thumbView.imageScaling = .scaleProportionallyUpOrDown
        thumbView.wantsLayer = true
        thumbView.layer?.cornerRadius = Theme.cardRadius
        thumbView.layer?.masksToBounds = true
        thumbView.layer?.contentsGravity = .resizeAspectFill
        addSubview(thumbView)

        nameLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        nameLabel.textColor = Theme.textPri
        nameLabel.alignment = .center
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.maximumNumberOfLines = 1
        addSubview(nameLabel)
        nameLabel.stringValue = videoName

        checkBadge.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        checkBadge.textColor = .white
        checkBadge.wantsLayer = true
        checkBadge.layer?.backgroundColor = Theme.accent.cgColor
        checkBadge.layer?.cornerRadius = 12
        checkBadge.alignment = .center
        checkBadge.isHidden = true
        addSubview(checkBadge)
    }

    private func loadThumb() {
        ThumbCache.shared.get(videoPath, size: NSSize(width: Theme.cardW, height: Theme.thumbH)) { [weak self] img in
            self?.thumbView.image = img
        }
    }

    private func updateBorder() {
        if isActive {
            layer?.borderWidth = 3
            layer?.borderColor = Theme.accent.cgColor
            checkBadge.isHidden = false
        } else {
            layer?.borderWidth = 0
            checkBadge.isHidden = true
        }
    }

    override func layout() {
        super.layout()
        let b = bounds
        thumbView.frame = NSRect(x: 0, y: b.height - thumbHeight, width: b.width, height: thumbHeight)
        nameLabel.frame = NSRect(x: 8, y: 2, width: b.width - 16, height: b.height - thumbHeight - 4)
        checkBadge.frame = NSRect(x: b.width - 30, y: b.height - 30, width: 24, height: 24)
    }

    override func draw(_ dirtyRect: NSRect) {
        let bg = isHovered ? Theme.cardHover : Theme.cardBg
        bg.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: Theme.cardRadius, yRadius: Theme.cardRadius).fill()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let t = trackingArea { removeTrackingArea(t) }
        trackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self)
        addTrackingArea(trackingArea!)
    }
    override func mouseEntered(with e: NSEvent) { isHovered = true }
    override func mouseExited(with e: NSEvent) { isHovered = false }
    override func mouseUp(with e: NSEvent) { onClick?() }

    override func menu(for event: NSEvent) -> NSMenu? {
        let m = NSMenu()
        let del = NSMenuItem(title: "Eliminar \"\(videoName)\"", action: #selector(deleteItem), keyEquivalent: "")
        del.target = self
        m.addItem(del)
        return m
    }
    @objc func deleteItem() { onDelete?() }
}

// MARK: - Grid Container
class GridView: NSView {
    var cards: [WallpaperCard] = []
    var bannerView: NSView?

    override var isFlipped: Bool { true }

    func layoutCards() {
        let availWidth = bounds.width - Theme.pad * 2
        // Dynamic columns: fit as many as possible with min card width 220
        let cols = max(1, Int(availWidth / (220 + Theme.gap)))
        let cardW = (availWidth - CGFloat(cols - 1) * Theme.gap) / CGFloat(cols)
        let thumbH = cardW * 0.6
        let cardH = thumbH + 30

        var startY: CGFloat = Theme.pad
        // Account for banner
        if let banner = bannerView {
            banner.frame = NSRect(x: Theme.pad, y: Theme.pad, width: availWidth, height: banner.frame.height)
            startY = banner.frame.maxY + Theme.gap
        }

        for (i, card) in cards.enumerated() {
            let col = i % cols
            let row = i / cols
            let x = Theme.pad + CGFloat(col) * (cardW + Theme.gap)
            let y = startY + CGFloat(row) * (cardH + Theme.gap)
            card.frame = NSRect(x: x, y: y, width: cardW, height: cardH)

            // Update thumb height inside card
            card.thumbHeight = thumbH
            card.needsLayout = true
        }
        let rows = cards.isEmpty ? 0 : (cards.count - 1) / cols + 1
        let contentH = startY + CGFloat(rows) * (cardH + Theme.gap) + Theme.pad
        frame.size.height = max(contentH, superview?.bounds.height ?? 0)
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        layoutCards()
    }
}

// MARK: - Main Window Controller
class MainController: NSObject {
    let window: NSWindow
    private let scrollView = NSScrollView()
    private let gridView = GridView()
    private var activeName = ""

    lazy var appSupportURL: URL = {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WallpaperSync")
        try? FileManager.default.createDirectory(at: url.appendingPathComponent("library"), withIntermediateDirectories: true)
        return url
    }()

    lazy var bundleResourcesURL: URL = {
        Bundle.main.resourceURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }()

    override init() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 820, height: 560),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                          backing: .buffered, defer: false)
        super.init()

        window.title = "Wallpaper Sync"
        window.minSize = NSSize(width: 560, height: 400)
        window.center()
        window.isReleasedWhenClosed = false
        window.backgroundColor = Theme.bg
        window.titlebarAppearsTransparent = true
        window.appearance = NSAppearance(named: .darkAqua)
        window.collectionBehavior = [.fullScreenPrimary]

        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = Theme.bg.cgColor
        window.contentView = contentView

        // Header
        let header = NSView(frame: NSRect(x: 0, y: contentView.bounds.height - 60, width: contentView.bounds.width, height: 60))
        header.autoresizingMask = [.width, .minYMargin]
        header.wantsLayer = true
        contentView.addSubview(header)

        let title = NSTextField(labelWithString: "🎬 Wallpaper Sync")
        title.font = NSFont.systemFont(ofSize: 22, weight: .bold)
        title.textColor = Theme.textPri
        title.frame = NSRect(x: Theme.pad, y: 14, width: 300, height: 30)
        header.addSubview(title)

        let importBtn = NSButton(title: "＋ Importar", target: self, action: #selector(importVideo))
        importBtn.bezelStyle = .rounded
        importBtn.wantsLayer = true
        importBtn.layer?.backgroundColor = Theme.accent.cgColor
        importBtn.layer?.cornerRadius = 8
        importBtn.contentTintColor = .white
        importBtn.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        importBtn.frame = NSRect(x: contentView.bounds.width - 130, y: 14, width: 110, height: 32)
        importBtn.autoresizingMask = [.minXMargin]
        header.addSubview(importBtn)

        // Scroll + Grid
        scrollView.frame = NSRect(x: 0, y: 0, width: contentView.bounds.width, height: contentView.bounds.height - 60)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        gridView.frame = scrollView.bounds
        scrollView.documentView = gridView
        contentView.addSubview(scrollView)

        reloadLibrary()
    }

    func reloadLibrary() {
        // Read active name
        let cfgPath = appSupportURL.appendingPathComponent("config.json").path
        if let data = try? Data(contentsOf: URL(fileURLWithPath: cfgPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let name = json["activeName"] as? String {
            activeName = name
        }

        // Clear
        gridView.cards.forEach { $0.removeFromSuperview() }
        gridView.cards.removeAll()
        gridView.bannerView?.removeFromSuperview()
        gridView.bannerView = nil

        // Check if aerial is set up
        let aerialsDir = NSString(string: "~/Library/Application Support/com.apple.wallpaper/aerials/videos").expandingTildeInPath
        var hasAerial = false
        if let files = try? FileManager.default.contentsOfDirectory(atPath: aerialsDir) {
            hasAerial = files.contains(where: { $0.hasSuffix(".mov") && !$0.contains("backup") && !$0.contains("tmp") })
        }

        if !hasAerial {
            let banner = makeBanner(
                icon: "⚠️",
                title: "Configuración necesaria para la pantalla de bloqueo",
                body: """
                Para que tu wallpaper aparezca también en la pantalla de bloqueo, \
                necesitás descargar un fondo animado del sistema:

                1. Abrí Configuración del Sistema → Fondo de Pantalla
                2. Buscá un fondo animado (ej: "Tahoe Day")
                3. Hacé click en "Descargar" (ícono de nube ☁️)
                4. Activá "Mostrar como salvapantallas"
                5. ¡Listo! Wallpaper Sync lo reemplaza automáticamente.

                Esto se hace una sola vez.
                """,
                buttonTitle: "Abrir Configuración",
                action: #selector(openWallpaperSettings)
            )
            gridView.bannerView = banner
            gridView.addSubview(banner)
        }

        // Load videos
        let libPath = appSupportURL.appendingPathComponent("library").path
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: libPath) else { return }
        let movFiles = files.filter { $0.hasSuffix(".mov") }.sorted()

        if movFiles.isEmpty {
            let emptyBanner = makeBanner(
                icon: "🎬",
                title: "Tu biblioteca está vacía",
                body: "Importá un video (.mp4, .mov, .gif) para usarlo como wallpaper animado.",
                buttonTitle: "＋ Importar Video",
                action: #selector(importVideo)
            )
            if gridView.bannerView == nil {
                gridView.bannerView = emptyBanner
                gridView.addSubview(emptyBanner)
            }
        }

        for file in movFiles {
            let name = (file as NSString).deletingPathExtension
            let path = (libPath as NSString).appendingPathComponent(file)
            let card = WallpaperCard(path: path, name: name)
            card.isActive = (name == activeName)
            card.onClick = { [weak self] in self?.useWallpaper(name) }
            card.onDelete = { [weak self] in self?.deleteWallpaper(name) }
            gridView.addSubview(card)
            gridView.cards.append(card)
        }
        gridView.layoutCards()
    }

    private func makeBanner(icon: String, title: String, body: String, buttonTitle: String, action: Selector) -> NSView {
        let banner = NSView(frame: NSRect(x: 0, y: 0, width: 100, height: 160))
        banner.wantsLayer = true
        banner.layer?.backgroundColor = NSColor(red: 0.18, green: 0.15, blue: 0.30, alpha: 1).cgColor
        banner.layer?.cornerRadius = 12
        banner.layer?.borderWidth = 1
        banner.layer?.borderColor = Theme.accent.withAlphaComponent(0.3).cgColor

        let iconLabel = NSTextField(labelWithString: icon)
        iconLabel.font = NSFont.systemFont(ofSize: 28)
        iconLabel.frame = NSRect(x: 16, y: 120, width: 40, height: 36)
        banner.addSubview(iconLabel)

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = Theme.textPri
        titleLabel.frame = NSRect(x: 56, y: 124, width: 600, height: 24)
        banner.addSubview(titleLabel)

        let bodyLabel = NSTextField(wrappingLabelWithString: body)
        bodyLabel.font = NSFont.systemFont(ofSize: 12)
        bodyLabel.textColor = Theme.textSec
        bodyLabel.frame = NSRect(x: 16, y: 36, width: 700, height: 84)
        bodyLabel.maximumNumberOfLines = 10
        bodyLabel.usesSingleLineMode = false
        banner.addSubview(bodyLabel)

        let btn = NSButton(title: buttonTitle, target: self, action: action)
        btn.bezelStyle = .rounded
        btn.wantsLayer = true
        btn.layer?.backgroundColor = Theme.accent.cgColor
        btn.layer?.cornerRadius = 6
        btn.contentTintColor = .white
        btn.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        btn.frame = NSRect(x: 16, y: 6, width: 180, height: 26)
        banner.addSubview(btn)

        return banner
    }

    @objc func openWallpaperSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Wallpaper-Settings.extension")!)
    }

    private func useWallpaper(_ name: String) {
        activeName = name
        gridView.cards.forEach { $0.isActive = ($0.videoName == name) }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.runCommand("bin/wallpaper", args: ["use", name])
        }
    }

    private func deleteWallpaper(_ name: String) {
        let alert = NSAlert()
        alert.messageText = "¿Eliminar \"\(name)\"?"
        alert.informativeText = "Se va a eliminar de la biblioteca."
        alert.addButton(withTitle: "Eliminar")
        alert.addButton(withTitle: "Cancelar")
        alert.alertStyle = .warning
        if alert.runModal() == .alertFirstButtonReturn {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.runCommand("bin/wallpaper", args: ["remove", name])
                DispatchQueue.main.async { self?.reloadLibrary() }
            }
        }
    }

    @objc func importVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .init(filenameExtension: "mp4")!, .init(filenameExtension: "mov")!,
            .init(filenameExtension: "m4v")!, .init(filenameExtension: "gif")!,
        ]
        panel.allowsMultipleSelection = true
        panel.title = "Seleccioná videos para importar"
        panel.prompt = "Importar"
        if panel.runModal() == .OK {
            for url in panel.urls {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.runCommand("bin/wallpaper", args: ["set", url.path])
                    DispatchQueue.main.async { self?.reloadLibrary() }
                }
            }
        }
    }

    func runCommand(_ executable: String, args: [String]) {
        let process = Process()
        process.executableURL = bundleResourcesURL.appendingPathComponent(executable)
        process.arguments = args
        var env = ProcessInfo.processInfo.environment
        env["APP_BUNDLE_RESOURCES"] = bundleResourcesURL.path
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + (env["PATH"] ?? "")
        process.environment = env
        do { try process.run(); process.waitUntilExit() }
        catch { print("Error: \(error)") }
    }
}

// MARK: - App Delegate (Menu Bar + Window)
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var mainController: MainController!

    func applicationDidFinishLaunching(_ n: Notification) {
        mainController = MainController()
        mainController.window.delegate = self

        // Menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem.button {
            btn.title = "🎬"
            btn.action = #selector(toggleWindow)
            btn.target = self
        }

        // Start minimized — only menu bar icon visible, no dock icon
        // (window stays hidden until user clicks 🎬)

        // Check dependencies, then start engine
        checkDependencies {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.mainController.runCommand("bin/wallpaper", args: ["start"])
            }
        }
    }

    private func ffmpegPath() -> String? {
        for p in ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg"] {
            if FileManager.default.fileExists(atPath: p) { return p }
        }
        return nil
    }

    private func brewPath() -> String? {
        for p in ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"] {
            if FileManager.default.fileExists(atPath: p) { return p }
        }
        return nil
    }

    private func checkDependencies(then onReady: @escaping () -> Void) {
        if ffmpegPath() != nil { onReady(); return }

        // ffmpeg not found — ask to install
        let alert = NSAlert()
        alert.messageText = "Se necesita ffmpeg"
        alert.informativeText = "Wallpaper Sync necesita ffmpeg para convertir videos.\n\n¿Querés que lo instale automáticamente?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Instalar ffmpeg")
        alert.addButton(withTitle: "Más tarde")

        if alert.runModal() != .alertFirstButtonReturn { onReady(); return }

        if let brew = brewPath() {
            installFFmpeg(brew: brew, then: onReady)
        } else {
            installHomebrew(then: onReady)
        }
    }

    private func installFFmpeg(brew: String, then onReady: @escaping () -> Void) {
        let progress = NSAlert()
        progress.messageText = "Instalando ffmpeg…"
        progress.informativeText = "Esto puede tardar un par de minutos.\nNo cierres esta ventana."
        progress.addButton(withTitle: "Esperando…")
        progress.buttons[0].isEnabled = false

        // Show non-modal
        DispatchQueue.main.async { progress.beginSheetModal(for: self.mainController.window) { _ in } }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: brew)
            proc.arguments = ["install", "ffmpeg"]
            var env = ProcessInfo.processInfo.environment
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + (env["PATH"] ?? "")
            proc.environment = env
            try? proc.run()
            proc.waitUntilExit()

            DispatchQueue.main.async {
                self?.mainController.window.endSheet(self?.mainController.window.attachedSheet ?? NSWindow())
                if self?.ffmpegPath() != nil {
                    let ok = NSAlert()
                    ok.messageText = "✓ ffmpeg instalado"
                    ok.informativeText = "¡Listo! Ya podés importar y usar tus videos."
                    ok.runModal()
                } else {
                    let fail = NSAlert()
                    fail.messageText = "No se pudo instalar ffmpeg"
                    fail.informativeText = "Abrí Terminal y corré:\nbrew install ffmpeg"
                    fail.alertStyle = .warning
                    fail.runModal()
                }
                onReady()
            }
        }
    }

    private func installHomebrew(then onReady: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = "Se necesita Homebrew"
        alert.informativeText = "Homebrew es el gestor de paquetes de macOS.\nSe va a abrir Terminal para instalarlo.\n\nDespués de instalar Homebrew, corré:\nbrew install ffmpeg"
        alert.addButton(withTitle: "Abrir Terminal")
        alert.addButton(withTitle: "Cancelar")

        if alert.runModal() == .alertFirstButtonReturn {
            // Open Terminal with the Homebrew install script
            let script = "/bin/bash -c \\\"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\\\" && brew install ffmpeg"
            let appleScript = "tell application \"Terminal\" to do script \"\(script)\""
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            proc.arguments = ["-e", appleScript]
            try? proc.run()
        }
        onReady()
    }

    @objc func toggleWindow() {
        if mainController.window.isVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }

    private func showWindow() {
        NSApp.setActivationPolicy(.regular)  // Show in dock
        mainController.reloadLibrary()
        mainController.window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hideWindow() {
        mainController.window.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)  // Hide from dock
    }

    // When user clicks the red X, hide to menu bar instead of quitting
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hideWindow()
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }
}

// MARK: - Main
let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // Start as menu bar only (no dock icon)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
