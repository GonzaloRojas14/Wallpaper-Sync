import Cocoa
import AVFoundation
import QuartzCore

// MARK: - Design Tokens
//
// Semantic, sistema-aware. Respetan modo claro/oscuro y el accent color
// elegido por el usuario en Configuración del Sistema. Inspirado en el HIG
// de macOS Tahoe (Liquid Glass): translucencia, deferencia al contenido,
// poco color saturado en chrome.
struct Theme {
    static var accent: NSColor    { NSColor.controlAccentColor }
    static var accent2: NSColor   { NSColor.systemPink }
    static var cardBg: NSColor    { NSColor(name: nil) { $0.name == .darkAqua ? NSColor(white: 1, alpha: 0.06) : NSColor(white: 0, alpha: 0.04) } }
    static var cardHover: NSColor { NSColor(name: nil) { $0.name == .darkAqua ? NSColor(white: 1, alpha: 0.10) : NSColor(white: 0, alpha: 0.07) } }
    static var cardBorder: NSColor { NSColor.separatorColor }
    static var textPri: NSColor   { NSColor.labelColor }
    static var textSec: NSColor   { NSColor.secondaryLabelColor }
    static var textTer: NSColor   { NSColor.tertiaryLabelColor }
    static let cardRadius: CGFloat = 16
    static let cardW: CGFloat = 240
    static let cardH: CGFloat = 175
    static let thumbH: CGFloat = 145
    static let gap: CGFloat = 18
    static let pad: CGFloat = 28
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
    var isActive: Bool = false { didSet { updateActiveState() } }
    var isHovered: Bool = false { didSet { updateHoverState() } }
    var onClick: (() -> Void)?
    var onDelete: (() -> Void)?
    var thumbHeight: CGFloat = Theme.thumbH

    private let thumbContainer = NSView()
    private let thumbView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let activePill = NSView()
    private let activeIcon = NSImageView()
    private let activeText = NSTextField(labelWithString: "Activo")
    private var trackingArea: NSTrackingArea?

    init(path: String, name: String) {
        self.videoPath = path
        self.videoName = name
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = Theme.cardRadius
        layer?.masksToBounds = false  // sombra fuera de bounds
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.18
        layer?.shadowRadius = 10
        layer?.shadowOffset = CGSize(width: 0, height: -3)
        setupViews()
        loadThumb()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        // Thumbnail clipped a esquinas redondeadas
        thumbContainer.wantsLayer = true
        thumbContainer.layer?.cornerRadius = Theme.cardRadius
        thumbContainer.layer?.masksToBounds = true
        thumbContainer.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        addSubview(thumbContainer)

        thumbView.imageScaling = .scaleProportionallyUpOrDown
        thumbView.wantsLayer = true
        thumbView.layer?.contentsGravity = .resizeAspectFill
        thumbContainer.addSubview(thumbView)

        nameLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        nameLabel.textColor = Theme.textPri
        nameLabel.alignment = .center
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.maximumNumberOfLines = 1
        nameLabel.stringValue = videoName
        addSubview(nameLabel)

        // Pill "Activo" — barra cápsula con SF Symbol play
        activePill.wantsLayer = true
        activePill.layer?.backgroundColor = Theme.accent.cgColor
        activePill.layer?.cornerRadius = 10
        activePill.isHidden = true
        addSubview(activePill)

        if let img = NSImage(systemSymbolName: "play.fill", accessibilityDescription: "Activo") {
            let cfg = NSImage.SymbolConfiguration(pointSize: 9, weight: .bold)
            activeIcon.image = img.withSymbolConfiguration(cfg)
            activeIcon.contentTintColor = .white
        }
        activePill.addSubview(activeIcon)

        activeText.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        activeText.textColor = .white
        activePill.addSubview(activeText)
    }

    private func loadThumb() {
        ThumbCache.shared.get(videoPath, size: NSSize(width: Theme.cardW, height: Theme.thumbH)) { [weak self] img in
            self?.thumbView.image = img
        }
    }

    private func updateActiveState() {
        if isActive {
            layer?.borderWidth = 2
            layer?.borderColor = Theme.accent.cgColor
            activePill.isHidden = false
        } else {
            layer?.borderWidth = 0
            activePill.isHidden = true
        }
        needsDisplay = true
    }

    private func updateHoverState() {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            ctx.allowsImplicitAnimation = true
            if isHovered {
                layer?.shadowOpacity = 0.32
                layer?.shadowRadius = 14
                layer?.transform = CATransform3DMakeScale(1.025, 1.025, 1)
            } else {
                layer?.shadowOpacity = 0.18
                layer?.shadowRadius = 10
                layer?.transform = CATransform3DIdentity
            }
        }
        needsDisplay = true
    }

    override func layout() {
        super.layout()
        let b = bounds
        thumbContainer.frame = NSRect(x: 0, y: b.height - thumbHeight, width: b.width, height: thumbHeight)
        thumbView.frame = thumbContainer.bounds
        nameLabel.frame = NSRect(x: 10, y: 4, width: b.width - 20, height: b.height - thumbHeight - 6)

        // Pill arriba a la derecha del thumbnail
        let pillW: CGFloat = 64, pillH: CGFloat = 20
        activePill.frame = NSRect(x: b.width - pillW - 8, y: b.height - pillH - 8, width: pillW, height: pillH)
        activeIcon.frame = NSRect(x: 8, y: 5, width: 11, height: 11)
        activeText.frame = NSRect(x: 22, y: 3, width: 38, height: 14)

        // Sombra rebatida con shadowPath (perf + permite scaled transforms)
        layer?.shadowPath = CGPath(roundedRect: bounds, cornerWidth: Theme.cardRadius, cornerHeight: Theme.cardRadius, transform: nil)
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

// MARK: - Icon Button (con hover-tint)
//
// Botón sin bordes que cambia el tint al pasarle el mouse encima. Lo usamos
// para los íconos de Instagram y donaciones en la barra inferior.
class IconButton: NSButton {
    var idleTint: NSColor = NSColor.secondaryLabelColor
    var hoverTint: NSColor = NSColor.controlAccentColor
    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let t = trackingArea { removeTrackingArea(t) }
        trackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self)
        addTrackingArea(trackingArea!)
    }
    override func mouseEntered(with event: NSEvent) { contentTintColor = hoverTint }
    override func mouseExited(with event: NSEvent) { contentTintColor = idleTint }
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
    private var aerialSetupOverlay: NSView?

    lazy var appSupportURL: URL = {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WallpaperSync")
        try? FileManager.default.createDirectory(at: url.appendingPathComponent("library"), withIntermediateDirectories: true)
        return url
    }()

    lazy var bundleResourcesURL: URL = {
        Bundle.main.resourceURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }()

    private let statusIcon = NSImageView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let activeInfoLabel = NSTextField(labelWithString: "")
    private let powerSaveBtn = NSButton()
    private let searchField = NSSearchField()
    private var allCards: [WallpaperCard] = []

    override init() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 880, height: 620),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                          backing: .buffered, defer: false)
        super.init()

        window.title = "Wallpaper Sync"
        // Min width 760 deja espacio para traffic lights + título + search +
        // controles de la derecha sin solapamiento. Por debajo de eso ocultamos
        // el search field dinámicamente.
        window.minSize = NSSize(width: 760, height: 500)
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.collectionBehavior = [.fullScreenPrimary]
        // No forzar darkAqua: dejamos que el sistema decida (Liquid Glass se ve
        // bien en ambos modos). El usuario puede cambiarlo en System Settings.

        let cv = window.contentView!
        cv.wantsLayer = true

        // Capa base translúcida — material idiomático de macOS Tahoe
        let bgEffect = NSVisualEffectView(frame: cv.bounds)
        bgEffect.autoresizingMask = [.width, .height]
        bgEffect.material = .underWindowBackground
        bgEffect.blendingMode = .behindWindow
        bgEffect.state = .followsWindowActiveState
        cv.addSubview(bgEffect)

        // Header — material headerView, alineado debajo del titlebar nativo
        let headerH: CGFloat = 56
        let header = NSVisualEffectView(frame: NSRect(x: 0, y: cv.bounds.height - headerH, width: cv.bounds.width, height: headerH))
        header.autoresizingMask = [.width, .minYMargin]
        header.material = .headerView
        header.blendingMode = .withinWindow
        header.state = .active
        cv.addSubview(header)

        // Separador hairline debajo del header
        let headerSep = NSBox(frame: NSRect(x: 0, y: 0, width: cv.bounds.width, height: 1))
        headerSep.boxType = .custom
        headerSep.borderWidth = 0
        headerSep.fillColor = NSColor.separatorColor
        headerSep.autoresizingMask = [.width]
        header.addSubview(headerSep)

        // Título — empieza después de las traffic lights (≈ x=78) para no
        // taparlas. La columna izquierda del header reserva 0–250 para
        // [icono · "Biblioteca"]; el search ocupa el centro flexible.
        let titleX: CGFloat = 84
        let titleIcon = NSImageView()
        if let img = NSImage(systemSymbolName: "play.rectangle.fill", accessibilityDescription: nil) {
            let cfg = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            titleIcon.image = img.withSymbolConfiguration(cfg)
            titleIcon.contentTintColor = Theme.accent
        }
        titleIcon.frame = NSRect(x: titleX, y: 18, width: 22, height: 22)
        header.addSubview(titleIcon)

        let titleLabel = NSTextField(labelWithString: "Biblioteca")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = Theme.textPri
        titleLabel.frame = NSRect(x: titleX + 30, y: 18, width: 140, height: 22)
        header.addSubview(titleLabel)

        // Search field — flex center. Crece con la ventana via .width mask.
        // En ventanas chicas se oculta en updateHeaderLayout().
        searchField.placeholderString = "Buscar wallpapers"
        searchField.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        searchField.target = self
        searchField.action = #selector(searchChanged)
        searchField.sendsSearchStringImmediately = true
        searchField.sendsWholeSearchString = false
        let searchLeft: CGFloat = titleX + 30 + 150  // = 264
        searchField.frame = NSRect(x: searchLeft, y: 16, width: max(180, cv.bounds.width - searchLeft - 310), height: 24)
        searchField.autoresizingMask = [.width]
        header.addSubview(searchField)

        // Power save — switch nativo con icono bolt
        let psBolt = NSImageView()
        if let img = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil) {
            let cfg = NSImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
            psBolt.image = img.withSymbolConfiguration(cfg)
            psBolt.contentTintColor = Theme.textSec
        }
        psBolt.frame = NSRect(x: cv.bounds.width - 290, y: 20, width: 14, height: 16)
        psBolt.autoresizingMask = [.minXMargin]
        header.addSubview(psBolt)

        let psLabel = NSTextField(labelWithString: "Ahorro")
        psLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        psLabel.textColor = Theme.textSec
        psLabel.frame = NSRect(x: cv.bounds.width - 272, y: 20, width: 60, height: 16)
        psLabel.autoresizingMask = [.minXMargin]
        header.addSubview(psLabel)

        powerSaveBtn.setButtonType(.switch)
        if #available(macOS 10.15, *) {
            powerSaveBtn.controlSize = .small
        }
        powerSaveBtn.title = ""
        powerSaveBtn.target = self
        powerSaveBtn.action = #selector(togglePowerSaveHUD)
        powerSaveBtn.frame = NSRect(x: cv.bounds.width - 210, y: 20, width: 30, height: 16)
        powerSaveBtn.autoresizingMask = [.minXMargin]
        header.addSubview(powerSaveBtn)

        // Botón Importar — borderedProminent style HIG-compliant
        let importBtn = NSButton(title: "  Importar", target: self, action: #selector(importVideo))
        importBtn.bezelStyle = .rounded
        if #available(macOS 11.0, *) {
            importBtn.image = NSImage(systemSymbolName: "plus", accessibilityDescription: nil)
            importBtn.imagePosition = .imageLeading
            importBtn.imageScaling = .scaleProportionallyDown
        }
        importBtn.controlSize = .regular
        importBtn.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        if #available(macOS 11.0, *) {
            importBtn.bezelColor = Theme.accent
        }
        importBtn.contentTintColor = .white
        importBtn.frame = NSRect(x: cv.bounds.width - 130, y: 16, width: 110, height: 26)
        importBtn.autoresizingMask = [.minXMargin]
        header.addSubview(importBtn)

        // Bottom bar — material translúcido + separador
        let bottomH: CGFloat = 36
        let bottomBar = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: cv.bounds.width, height: bottomH))
        bottomBar.autoresizingMask = [.width, .maxYMargin]
        bottomBar.material = .titlebar
        bottomBar.blendingMode = .withinWindow
        bottomBar.state = .active
        cv.addSubview(bottomBar)

        let bottomSep = NSBox(frame: NSRect(x: 0, y: bottomH - 1, width: cv.bounds.width, height: 1))
        bottomSep.boxType = .custom
        bottomSep.borderWidth = 0
        bottomSep.fillColor = NSColor.separatorColor
        bottomSep.autoresizingMask = [.width]
        bottomBar.addSubview(bottomSep)

        // Estado del motor: SF Symbol semántico (verde/rojo).
        statusIcon.frame = NSRect(x: 14, y: 10, width: 14, height: 14)
        bottomBar.addSubview(statusIcon)

        statusLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = Theme.textSec
        statusLabel.frame = NSRect(x: 32, y: 10, width: 130, height: 14)
        bottomBar.addSubview(statusLabel)

        activeInfoLabel.font = NSFont.monospacedSystemFont(ofSize: 10.5, weight: .regular)
        activeInfoLabel.textColor = Theme.textTer
        activeInfoLabel.alignment = .center
        // Reservamos ~80 px en el extremo derecho para los íconos (Instagram + donar)
        activeInfoLabel.frame = NSRect(x: 170, y: 10, width: cv.bounds.width - 250, height: 14)
        activeInfoLabel.autoresizingMask = [.width]
        bottomBar.addSubview(activeInfoLabel)

        // Iconos sociales / donación — extremo derecho de la bottom bar.
        // Anclados a la derecha vía .minXMargin para que se queden fijos cuando
        // la ventana se agranda.
        let igBtn = IconButton()
        igBtn.title = ""
        igBtn.isBordered = false
        igBtn.imagePosition = .imageOnly
        if let img = NSImage(systemSymbolName: "at", accessibilityDescription: "Instagram") {
            let cfg = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            igBtn.image = img.withSymbolConfiguration(cfg)
        }
        igBtn.contentTintColor = Theme.textSec
        igBtn.idleTint = Theme.textSec
        igBtn.hoverTint = NSColor(red: 0.91, green: 0.27, blue: 0.55, alpha: 1) // rosa Instagram
        igBtn.toolTip = "Instagram · @gonza._007"
        igBtn.target = self
        igBtn.action = #selector(openInstagram)
        igBtn.frame = NSRect(x: cv.bounds.width - 56, y: 8, width: 22, height: 22)
        igBtn.autoresizingMask = [.minXMargin]
        bottomBar.addSubview(igBtn)

        let donateBtn = IconButton()
        donateBtn.title = ""
        donateBtn.isBordered = false
        donateBtn.imagePosition = .imageOnly
        if let img = NSImage(systemSymbolName: "heart.fill", accessibilityDescription: "Donar") {
            let cfg = NSImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
            donateBtn.image = img.withSymbolConfiguration(cfg)
        }
        donateBtn.contentTintColor = Theme.textSec
        donateBtn.idleTint = Theme.textSec
        donateBtn.hoverTint = NSColor.systemPink
        donateBtn.toolTip = "Invitame un café · ceneka.net/gonza_007"
        donateBtn.target = self
        donateBtn.action = #selector(openDonate)
        donateBtn.frame = NSRect(x: cv.bounds.width - 28, y: 8, width: 22, height: 22)
        donateBtn.autoresizingMask = [.minXMargin]
        bottomBar.addSubview(donateBtn)

        // Scroll + Grid (entre header y bottom)
        scrollView.frame = NSRect(x: 0, y: bottomH, width: cv.bounds.width, height: cv.bounds.height - headerH - bottomH)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.scrollerStyle = .overlay
        gridView.frame = NSRect(x: 0, y: 0, width: scrollView.contentView.bounds.width, height: 800)
        scrollView.documentView = gridView
        cv.addSubview(scrollView)

        // Hacer que el documentView siga el ancho del clipView — sin esto, en
        // fullscreen el grid se queda con el ancho inicial y deja espacio
        // muerto a la derecha en lugar de meter más columnas.
        scrollView.contentView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(
            self, selector: #selector(syncGridWidth),
            name: NSView.frameDidChangeNotification,
            object: scrollView.contentView
        )

        reloadLibrary()
        // Ancho inicial correcto incluso si la ventana arrancó más grande
        // que el frame de design.
        DispatchQueue.main.async { [weak self] in self?.syncGridWidth() }
    }

    @objc private func syncGridWidth() {
        let w = scrollView.contentView.bounds.width
        guard w > 0, abs(gridView.frame.width - w) > 0.5 else { return }
        var f = gridView.frame
        f.size.width = w
        gridView.frame = f
        gridView.layoutCards()
    }

    @objc func searchChanged() {
        let q = searchField.stringValue.trimmingCharacters(in: .whitespaces).lowercased()
        gridView.cards.forEach { $0.removeFromSuperview() }
        let filtered = q.isEmpty ? allCards : allCards.filter { $0.videoName.lowercased().contains(q) }
        gridView.cards = filtered
        filtered.forEach { gridView.addSubview($0) }
        gridView.layoutCards()
    }

    func reloadLibrary() {
        // Read active name and power save
        let cfgPath = appSupportURL.appendingPathComponent("config.json").path
        if let data = try? Data(contentsOf: URL(fileURLWithPath: cfgPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let name = json["activeName"] as? String {
                activeName = name
            }
            if let ps = json["powerSavingMode"] as? Bool {
                powerSaveBtn.state = ps ? .on : .off
            }
        }

        // Clear
        gridView.cards.forEach { $0.removeFromSuperview() }
        gridView.cards.removeAll()
        allCards.removeAll()
        gridView.bannerView?.removeFromSuperview()
        gridView.bannerView = nil

        let libPath = appSupportURL.appendingPathComponent("library").path
        let files = (try? FileManager.default.contentsOfDirectory(atPath: libPath)) ?? []
        let movFiles = files.filter { $0.hasSuffix(".mov") }.sorted()

        // Estado del motor — SF Symbol con color semántico
        let engineRunning = (try? String(contentsOfFile: appSupportURL.appendingPathComponent("logs/engine.pid").path))
            .flatMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .map { kill(Int32($0), 0) == 0 } ?? false
        let symbolName = engineRunning ? "circle.fill" : "exclamationmark.circle.fill"
        if let img = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) {
            let cfg = NSImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
            statusIcon.image = img.withSymbolConfiguration(cfg)
            statusIcon.contentTintColor = engineRunning ? NSColor.systemGreen : NSColor.systemRed
        }
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
            allCards.append(card)
        }
        // Reaplica el filtro actual de búsqueda sobre las nuevas cards
        let q = searchField.stringValue.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            let visible = allCards.filter { $0.videoName.lowercased().contains(q) }
            allCards.filter { !visible.contains($0) }.forEach { $0.removeFromSuperview() }
            gridView.cards = visible
        }

        // Check if aerial is set up
        let aerialsDir = NSString(string: "~/Library/Application Support/com.apple.wallpaper/aerials/videos").expandingTildeInPath
        var hasAerial = false
        if let afiles = try? FileManager.default.contentsOfDirectory(atPath: aerialsDir) {
            hasAerial = afiles.contains(where: { $0.hasSuffix(".mov") && !$0.contains("backup") && !$0.contains("tmp") })
        }

        if !hasAerial {
            // Overlay modal con fondo blurreado: bloquea visualmente la app
            // hasta que el usuario configure el aerial. El banner inline
            // quedaba demasiado tímido y la gente lo ignoraba.
            showAerialSetupOverlay()
        } else {
            hideAerialSetupOverlay()
        }
        if hasAerial && movFiles.isEmpty {
            let emptyBanner = makeBanner(
                symbol: "tray.fill",
                tint: Theme.accent,
                title: "Tu biblioteca está vacía",
                body: "Importá un video (.mp4, .mov, .gif) para usarlo como wallpaper animado.",
                buttonTitle: "Importar Video",
                buttonSymbol: "plus",
                action: #selector(importVideo)
            )
            gridView.bannerView = emptyBanner
            gridView.addSubview(emptyBanner)
        }

        gridView.layoutCards()
    }

    private func makeBanner(symbol: String, tint: NSColor, title: String, body: String, buttonTitle: String, buttonSymbol: String?, action: Selector) -> NSView {
        let banner = NSView(frame: NSRect(x: 0, y: 0, width: 100, height: 168))
        banner.wantsLayer = true
        banner.layer?.backgroundColor = Theme.cardBg.cgColor
        banner.layer?.cornerRadius = 14
        banner.layer?.borderWidth = 1
        banner.layer?.borderColor = tint.withAlphaComponent(0.35).cgColor

        // Pastilla del símbolo a la izquierda
        let symbolBg = NSView()
        symbolBg.wantsLayer = true
        symbolBg.layer?.backgroundColor = tint.withAlphaComponent(0.15).cgColor
        symbolBg.layer?.cornerRadius = 10
        symbolBg.frame = NSRect(x: 18, y: 116, width: 36, height: 36)
        banner.addSubview(symbolBg)

        let symView = NSImageView()
        if let img = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
            let cfg = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            symView.image = img.withSymbolConfiguration(cfg)
            symView.contentTintColor = tint
        }
        symView.frame = NSRect(x: 26, y: 124, width: 22, height: 22)
        banner.addSubview(symView)

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = Theme.textPri
        titleLabel.frame = NSRect(x: 64, y: 128, width: 600, height: 20)
        banner.addSubview(titleLabel)

        let bodyLabel = NSTextField(wrappingLabelWithString: body)
        bodyLabel.font = NSFont.systemFont(ofSize: 12)
        bodyLabel.textColor = Theme.textSec
        bodyLabel.frame = NSRect(x: 18, y: 40, width: 700, height: 80)
        bodyLabel.maximumNumberOfLines = 10
        bodyLabel.usesSingleLineMode = false
        banner.addSubview(bodyLabel)

        let btn = NSButton(title: buttonSymbol == nil ? buttonTitle : "  " + buttonTitle,
                           target: self, action: action)
        btn.bezelStyle = .rounded
        btn.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        if #available(macOS 11.0, *) {
            if let s = buttonSymbol, let img = NSImage(systemSymbolName: s, accessibilityDescription: nil) {
                btn.image = img
                btn.imagePosition = .imageLeading
            }
            btn.bezelColor = Theme.accent
        }
        btn.contentTintColor = .white
        btn.frame = NSRect(x: 18, y: 8, width: 200, height: 28)
        banner.addSubview(btn)

        return banner
    }

    // MARK: - Aerial setup overlay (modal con backdrop blurreado)

    private func showAerialSetupOverlay() {
        if aerialSetupOverlay != nil { return }
        FileHandle.standardError.write("[hud] aerial setup overlay shown\n".data(using: .utf8)!)
        let cv = window.contentView!

        // Backdrop translúcido que cubre toda la ventana — material
        // .fullScreenUI dispara el blur agresivo idiomático de macOS.
        let overlay = NSVisualEffectView(frame: cv.bounds)
        overlay.autoresizingMask = [.width, .height]
        overlay.material = .fullScreenUI
        overlay.blendingMode = .withinWindow
        overlay.state = .active
        overlay.wantsLayer = true

        // Eater de clicks: evita que se interactúe con la grilla detrás.
        let eater = NSView(frame: overlay.bounds)
        eater.autoresizingMask = [.width, .height]
        overlay.addSubview(eater)

        // Tarjeta central
        let cardW: CGFloat = 480
        let cardH: CGFloat = 380
        let card = NSView(frame: NSRect(
            x: (overlay.bounds.width - cardW) / 2,
            y: (overlay.bounds.height - cardH) / 2,
            width: cardW, height: cardH))
        card.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.9).cgColor
        card.layer?.cornerRadius = 18
        card.layer?.borderWidth = 1
        card.layer?.borderColor = NSColor.separatorColor.cgColor
        card.layer?.shadowColor = NSColor.black.cgColor
        card.layer?.shadowOpacity = 0.35
        card.layer?.shadowRadius = 32
        card.layer?.shadowOffset = CGSize(width: 0, height: -8)
        card.layer?.masksToBounds = false
        card.layer?.shadowPath = CGPath(roundedRect: card.bounds, cornerWidth: 18, cornerHeight: 18, transform: nil)
        overlay.addSubview(card)

        // Pastilla del símbolo
        let symbolBgSize: CGFloat = 64
        let symbolBg = NSView(frame: NSRect(
            x: (cardW - symbolBgSize) / 2,
            y: cardH - 92,
            width: symbolBgSize, height: symbolBgSize))
        symbolBg.wantsLayer = true
        symbolBg.layer?.backgroundColor = NSColor.systemYellow.withAlphaComponent(0.18).cgColor
        symbolBg.layer?.cornerRadius = 16
        card.addSubview(symbolBg)

        let symView = NSImageView()
        if let img = NSImage(systemSymbolName: "moon.stars.fill", accessibilityDescription: nil) {
            let cfg = NSImage.SymbolConfiguration(pointSize: 30, weight: .medium)
            symView.image = img.withSymbolConfiguration(cfg)
            symView.contentTintColor = NSColor.systemYellow
        }
        symView.frame = NSRect(x: (cardW - 36) / 2, y: cardH - 78, width: 36, height: 36)
        card.addSubview(symView)

        // Título
        let title = NSTextField(labelWithString: "Configurá la pantalla de bloqueo")
        title.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        title.textColor = Theme.textPri
        title.alignment = .center
        title.frame = NSRect(x: 24, y: cardH - 134, width: cardW - 48, height: 26)
        card.addSubview(title)

        // Subtítulo
        let subtitle = NSTextField(labelWithString: "Para sincronizar el video con tu lock screen, macOS necesita un fondo aerial descargado.")
        subtitle.font = NSFont.systemFont(ofSize: 13)
        subtitle.textColor = Theme.textSec
        subtitle.alignment = .center
        subtitle.maximumNumberOfLines = 3
        subtitle.usesSingleLineMode = false
        subtitle.lineBreakMode = .byWordWrapping
        subtitle.frame = NSRect(x: 32, y: cardH - 188, width: cardW - 64, height: 44)
        card.addSubview(subtitle)

        // Pasos numerados
        let steps: [(String, String)] = [
            ("1", "Abrí Configuración del Sistema → Fondo de Pantalla"),
            ("2", "Buscá un fondo animado (ej: \"Tahoe Day\")"),
            ("3", "Tocá el ícono de descarga (☁︎)"),
            ("4", "Activá \"Mostrar como salvapantallas\""),
        ]
        var stepY = cardH - 215
        for (num, text) in steps {
            stepY -= 26

            // Bullet con el número
            let bullet = NSTextField(labelWithString: num)
            bullet.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .bold)
            bullet.textColor = Theme.accent
            bullet.alignment = .center
            bullet.frame = NSRect(x: 36, y: stepY, width: 18, height: 18)
            card.addSubview(bullet)

            let stepLabel = NSTextField(labelWithString: text)
            stepLabel.font = NSFont.systemFont(ofSize: 12.5)
            stepLabel.textColor = Theme.textPri
            stepLabel.frame = NSRect(x: 60, y: stepY, width: cardW - 80, height: 18)
            card.addSubview(stepLabel)
        }

        // Botón primario
        let btn = NSButton(title: "  Abrir Configuración del Sistema", target: self, action: #selector(openWallpaperSettings))
        btn.bezelStyle = .rounded
        btn.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        if #available(macOS 11.0, *) {
            btn.image = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: nil)
            btn.imagePosition = .imageLeading
            btn.bezelColor = Theme.accent
        }
        btn.contentTintColor = .white
        btn.frame = NSRect(x: (cardW - 260) / 2, y: 24, width: 260, height: 32)
        card.addSubview(btn)

        cv.addSubview(overlay, positioned: .above, relativeTo: nil)
        aerialSetupOverlay = overlay
    }

    private func hideAerialSetupOverlay() {
        guard aerialSetupOverlay != nil else { return }
        FileHandle.standardError.write("[hud] aerial setup overlay hidden\n".data(using: .utf8)!)
        aerialSetupOverlay?.removeFromSuperview()
        aerialSetupOverlay = nil
    }

    @objc func openWallpaperSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Wallpaper-Settings.extension")!)
    }

    @objc func openInstagram() {
        NSWorkspace.shared.open(URL(string: "https://instagram.com/gonza._007")!)
    }

    @objc func openDonate() {
        NSWorkspace.shared.open(URL(string: "https://ceneka.net/gonza_007")!)
    }

    private func useWallpaper(_ name: String) {
        activeName = name
        gridView.cards.forEach { $0.isActive = ($0.videoName == name) }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.runCommand("bin/wallpaper", args: ["use", name])
        }
        // Force refresh active info
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in self?.reloadLibrary() }
    }

    @objc func togglePowerSaveHUD() {
        let isPowerSave = (powerSaveBtn.state == .on)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.runCommand("bin/wallpaper", args: ["powersave", isPowerSave ? "on" : "off"])
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

        // Menu bar icon — SF Symbol monocromo, se adapta a la barra clara/oscura
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem.button {
            if #available(macOS 11.0, *),
               let img = NSImage(systemSymbolName: "play.rectangle.fill", accessibilityDescription: "Wallpaper Sync") {
                let cfg = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
                let configured = img.withSymbolConfiguration(cfg) ?? img
                configured.isTemplate = true
                btn.image = configured
            } else {
                btn.title = "🎬"
            }
            btn.action = #selector(statusItemClicked(_:))
            btn.target = self
            btn.sendAction(on: [.leftMouseUp, .rightMouseUp])
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

    @objc func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Abrir HUD", action: #selector(toggleWindow), keyEquivalent: ""))
            
            let pSave = NSMenuItem(title: "Ahorro de Energía (Modo estático)", action: #selector(togglePowerSaveMenu), keyEquivalent: "")
            let cfgPath = mainController.appSupportURL.appendingPathComponent("config.json").path
            if let data = try? Data(contentsOf: URL(fileURLWithPath: cfgPath)),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let ps = json["powerSavingMode"] as? Bool, ps {
                pSave.state = .on
            } else {
                pSave.state = .off
            }
            menu.addItem(pSave)
            
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Salir", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil // remove so left click works natively
        } else {
            toggleWindow()
        }
    }

    @objc func togglePowerSaveMenu() {
        let cfgPath = mainController.appSupportURL.appendingPathComponent("config.json").path
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: cfgPath)),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        
        let current = json["powerSavingMode"] as? Bool ?? false
        let newState = !current
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.mainController.runCommand("bin/wallpaper", args: ["powersave", newState ? "on" : "off"])
            DispatchQueue.main.async {
                self?.mainController.reloadLibrary()
            }
        }
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
