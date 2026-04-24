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
        // Dynamic columns: tighter min width
        let cols = max(2, Int(availWidth / (190 + Theme.gap)))
        let cardW = (availWidth - CGFloat(cols - 1) * Theme.gap) / CGFloat(cols)
        let thumbH = cardW * 0.58
        let cardH = thumbH + 28

        var y: CGFloat = Theme.pad

        for (i, card) in cards.enumerated() {
            let col = i % cols
            let row = i / cols
            let x = Theme.pad + CGFloat(col) * (cardW + Theme.gap)
            let cy = y + CGFloat(row) * (cardH + Theme.gap)
            card.frame = NSRect(x: x, y: cy, width: cardW, height: cardH)

            // Update thumb height inside card
            card.thumbHeight = thumbH
            card.needsLayout = true
        }

        let rows = cards.isEmpty ? 0 : (cards.count - 1) / cols + 1
        y += CGFloat(rows) * (cardH + Theme.gap)

        if let banner = bannerView {
            banner.frame = NSRect(x: Theme.pad, y: y + 4, width: availWidth, height: 130)
            y += 142
        }

        frame.size.height = max(y + Theme.pad, superview?.bounds.height ?? 0)
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

    private let statusDot = NSView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let activeInfoLabel = NSTextField(labelWithString: "")

    override init() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 880, height: 620),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                          backing: .buffered, defer: false)
        super.init()

        window.title = "Wallpaper Sync"
        window.minSize = NSSize(width: 560, height: 420)
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.appearance = NSAppearance(named: .darkAqua)
        window.collectionBehavior = [.fullScreenPrimary]

        let cv = window.contentView!
        cv.wantsLayer = true

        // Gradient background
        let grad = CAGradientLayer()
        grad.colors = [
            NSColor(red: 0.06, green: 0.05, blue: 0.13, alpha: 1).cgColor,
            NSColor(red: 0.10, green: 0.08, blue: 0.19, alpha: 1).cgColor,
            NSColor(red: 0.07, green: 0.06, blue: 0.15, alpha: 1).cgColor,
        ]
        grad.startPoint = CGPoint(x: 0, y: 1)
        grad.endPoint = CGPoint(x: 1, y: 0)
        grad.frame = cv.bounds
        grad.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        cv.layer = CALayer()
        cv.wantsLayer = true
        cv.layer?.addSublayer(grad)

        // Glow orbs for depth
        let orbData: [(NSColor, CGFloat, CGFloat, CGFloat)] = [
            (NSColor(red:0.40,green:0.20,blue:0.85,alpha:0.10), -60, -30, 450),
            (NSColor(red:0.75,green:0.15,blue:0.45,alpha:0.06), 600, 250, 500),
            (NSColor(red:0.15,green:0.50,blue:0.90,alpha:0.07), 250, -60, 380),
        ]
        for (c, ox, oy, s) in orbData {
            let orb = CAGradientLayer()
            orb.type = .radial
            orb.colors = [c.cgColor, NSColor.clear.cgColor]
            orb.frame = CGRect(x: ox, y: oy, width: s, height: s)
            orb.startPoint = CGPoint(x: 0.5, y: 0.5)
            orb.endPoint = CGPoint(x: 1, y: 1)
            grad.addSublayer(orb)
        }

        // Header — just import button, title is in native title bar
        let header = NSView(frame: NSRect(x: 0, y: cv.bounds.height - 48, width: cv.bounds.width, height: 48))
        header.autoresizingMask = [.width, .minYMargin]
        cv.addSubview(header)

        let importBtn = NSButton(title: "＋ Importar", target: self, action: #selector(importVideo))
        importBtn.bezelStyle = .rounded
        importBtn.wantsLayer = true
        importBtn.layer?.backgroundColor = Theme.accent.cgColor
        importBtn.layer?.cornerRadius = 8
        importBtn.contentTintColor = .white
        importBtn.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        importBtn.frame = NSRect(x: cv.bounds.width - 130, y: 10, width: 110, height: 28)
        importBtn.autoresizingMask = [.minXMargin]
        header.addSubview(importBtn)

        // Bottom status bar
        let bottomBar = NSView(frame: NSRect(x: 0, y: 0, width: cv.bounds.width, height: 32))
        bottomBar.wantsLayer = true
        bottomBar.layer?.backgroundColor = NSColor(white: 0, alpha: 0.3).cgColor
        bottomBar.autoresizingMask = [.width]
        cv.addSubview(bottomBar)

        statusDot.wantsLayer = true
        statusDot.layer?.cornerRadius = 4
        statusDot.frame = NSRect(x: 12, y: 10, width: 8, height: 8)
        bottomBar.addSubview(statusDot)

        statusLabel.font = NSFont.systemFont(ofSize: 10.5, weight: .medium)
        statusLabel.textColor = Theme.textSec
        statusLabel.frame = NSRect(x: 26, y: 6, width: 120, height: 16)
        bottomBar.addSubview(statusLabel)

        activeInfoLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        activeInfoLabel.textColor = NSColor(white: 1, alpha: 0.4)
        activeInfoLabel.alignment = .center
        activeInfoLabel.frame = NSRect(x: 150, y: 6, width: cv.bounds.width - 180, height: 16)
        activeInfoLabel.autoresizingMask = [.width]
        bottomBar.addSubview(activeInfoLabel)

        // Scroll + Grid
        scrollView.frame = NSRect(x: 0, y: 32, width: cv.bounds.width, height: cv.bounds.height - 48 - 32)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.scrollerStyle = .overlay
        gridView.frame = NSRect(x: 0, y: 0, width: scrollView.bounds.width, height: 800)
        scrollView.documentView = gridView
        cv.addSubview(scrollView)

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

        let libPath = appSupportURL.appendingPathComponent("library").path
        let files = (try? FileManager.default.contentsOfDirectory(atPath: libPath)) ?? []
        let movFiles = files.filter { $0.hasSuffix(".mov") }.sorted()

        // Engine status in bottom bar
        let engineRunning = (try? String(contentsOfFile: appSupportURL.appendingPathComponent("logs/engine.pid").path))
            .flatMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .map { kill(Int32($0), 0) == 0 } ?? false
        statusDot.layer?.backgroundColor = engineRunning
            ? NSColor(red: 0.3, green: 0.9, blue: 0.5, alpha: 1).cgColor
            : NSColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1).cgColor
        statusLabel.stringValue = engineRunning ? "Motor activo" : "Motor detenido"

        // Active video info in bottom bar
        if !activeName.isEmpty {
            let vp = (libPath as NSString).appendingPathComponent(activeName + ".mov")
            if FileManager.default.fileExists(atPath: vp) {
                DispatchQueue.global(qos: .utility).async { [weak self] in
                    let asset = AVURLAsset(url: URL(fileURLWithPath: vp))
                    let tracks = asset.tracks(withMediaType: .video)
                    let sz = tracks.first?.naturalSize ?? .zero
                    let dur = CMTimeGetSeconds(asset.duration)
                    let fs = (try? FileManager.default.attributesOfItem(atPath: vp)[.size] as? Int) ?? 0
                    DispatchQueue.main.async {
                        self?.activeInfoLabel.stringValue = "▶ \(self?.activeName ?? "")  ·  \(Int(sz.width))×\(Int(sz.height))  ·  HEVC  ·  \(fs/(1024*1024))MB  ·  \(Int(dur))s"
                    }
                }
            }
        } else {
            activeInfoLabel.stringValue = ""
        }

        // Cards
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

        // Check if aerial is set up
        let aerialsDir = NSString(string: "~/Library/Application Support/com.apple.wallpaper/aerials/videos").expandingTildeInPath
        var hasAerial = false
        if let afiles = try? FileManager.default.contentsOfDirectory(atPath: aerialsDir) {
            hasAerial = afiles.contains(where: { $0.hasSuffix(".mov") && !$0.contains("backup") && !$0.contains("tmp") })
        }

        if !hasAerial {
            let banner = makeBanner(
                icon: "⚠️",
                title: "Configuración necesaria para la pantalla de bloqueo",
                body: "1. Abrí Configuración del Sistema → Fondo de Pantalla\n2. Buscá un fondo animado (ej: \"Tahoe Day\")\n3. Hacé click en \"Descargar\" (ícono de nube ☁️)\n4. Activá \"Mostrar como salvapantallas\"",
                buttonTitle: "Abrir Configuración",
                action: #selector(openWallpaperSettings)
            )
            gridView.bannerView = banner
            gridView.addSubview(banner)
        } else if movFiles.isEmpty {
            let emptyBanner = makeBanner(
                icon: "🎬",
                title: "Tu biblioteca está vacía",
                body: "Importá un video (.mp4, .mov, .gif) para usarlo como wallpaper animado.",
                buttonTitle: "＋ Importar Video",
                action: #selector(importVideo)
            )
            gridView.bannerView = emptyBanner
            gridView.addSubview(emptyBanner)
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
