import Cocoa
import AVFoundation
import AVKit
import IOKit
import IOKit.ps
import IOKit.pwr_mgt

// ──────────────────────────────────────────────────────────────────────
//  Window level: sit BELOW desktop icons and widgets, ABOVE the static wallpaper.
// ──────────────────────────────────────────────────────────────────────
let kDesktopIconLevel = Int(CGWindowLevelForKey(.desktopIconWindow))
let kDefaultWallpaperLevel: Int = kDesktopIconLevel - 1

final class WallpaperWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class WallpaperEngine: NSObject {
    private var windows: [NSWindow] = []
    private var players: [AVQueuePlayer] = []
    private var loopers: [AVPlayerLooper] = []
    private var currentVideoPath: String
    private let fillMode: AVLayerVideoGravity
    private let pauseOnBattery: Bool
    private let pauseOnLowPower: Bool
    private let sanityMode: Bool
    private let windowLevel: Int
    private let configPath: String
    private var isPaused = false
    private var configTimer: Timer?

    init(videoPath: String, fillMode: AVLayerVideoGravity, pauseOnBattery: Bool,
         pauseOnLowPower: Bool, sanityMode: Bool, windowLevel: Int, configPath: String) {
        self.currentVideoPath = videoPath
        self.fillMode = fillMode
        self.pauseOnBattery = pauseOnBattery
        self.pauseOnLowPower = pauseOnLowPower
        self.sanityMode = sanityMode
        self.windowLevel = windowLevel
        self.configPath = configPath
        super.init()
    }

    func start() {
        rebuildWindows()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(screensChanged),
                       name: NSApplication.didChangeScreenParametersNotification, object: nil)
        nc.addObserver(self, selector: #selector(powerStateChanged),
                       name: NSNotification.Name.NSProcessInfoPowerStateDidChange, object: nil)

        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(self, selector: #selector(displaySleep),
                       name: NSWorkspace.screensDidSleepNotification, object: nil)
        ws.addObserver(self, selector: #selector(displayWake),
                       name: NSWorkspace.screensDidWakeNotification, object: nil)

        // Lock/unlock — hide our window so the native lock screen aerial plays
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(self, selector: #selector(screenLocked),
                        name: NSNotification.Name("com.apple.screenIsLocked"), object: nil)
        dnc.addObserver(self, selector: #selector(screenUnlocked),
                        name: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil)

        applyPowerPolicy()

        // Signal handling
        let sigTerm = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        sigTerm.setEventHandler { [weak self] in self?.shutdown() }
        sigTerm.resume()
        let sigInt = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigInt.setEventHandler { [weak self] in self?.shutdown() }
        sigInt.resume()
        signal(SIGTERM, SIG_IGN); signal(SIGINT, SIG_IGN)

        // Single config watcher timer — NOT in rebuildWindows to avoid duplicates
        configTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self,
                                           selector: #selector(checkConfig), userInfo: nil, repeats: true)

        if sanityMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in self?.shutdown() }
        }
    }

    // MARK: - Config hot-reload

    @objc private func checkConfig() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let newVideo = json["video"] as? String,
              !newVideo.isEmpty,
              newVideo != currentVideoPath,
              FileManager.default.fileExists(atPath: newVideo) else { return }

        log("config changed: \(newVideo)")
        currentVideoPath = newVideo

        // Completely rebuild windows/players to avoid AVFoundation state corruption (grey/black screens)
        DispatchQueue.main.async { [weak self] in
            self?.rebuildWindows()
        }
    }

    // MARK: - Window management

    private func rebuildWindows() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        players.removeAll()
        loopers.removeAll()

        let effectiveLevel = NSWindow.Level(rawValue: windowLevel)
        let videoURL = URL(fileURLWithPath: currentVideoPath)
        log("screens=\(NSScreen.screens.count) level=\(windowLevel)")

        for screen in NSScreen.screens {
            let frame: NSRect
            if sanityMode {
                let w: CGFloat = 320, h: CGFloat = 180, pad: CGFloat = 24
                frame = NSRect(x: screen.frame.maxX - w - pad,
                               y: screen.frame.maxY - h - pad - 40,
                               width: w, height: h)
            } else {
                frame = screen.frame
            }

            let window = WallpaperWindow(contentRect: frame, styleMask: .borderless,
                                          backing: .buffered, defer: false, screen: screen)
            window.level = effectiveLevel
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
            window.isOpaque = true
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.backgroundColor = .black
            window.isReleasedWhenClosed = false
            window.canHide = false

            // Each screen gets its own player + looper + item
            let asset = AVURLAsset(url: videoURL)
            let item = AVPlayerItem(asset: asset)
            let player = AVQueuePlayer()
            player.isMuted = true
            player.actionAtItemEnd = .none
            player.automaticallyWaitsToMinimizeStalling = false
            if #available(macOS 10.12, *) {
                player.preventsDisplaySleepDuringVideoPlayback = false
            }
            let looper = AVPlayerLooper(player: player, templateItem: item)

            let layer = AVPlayerLayer(player: player)
            layer.frame = CGRect(origin: .zero, size: frame.size)
            layer.videoGravity = fillMode
            layer.backgroundColor = NSColor.black.cgColor
            layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

            let view = NSView(frame: CGRect(origin: .zero, size: frame.size))
            view.wantsLayer = true
            view.layer = layer
            window.contentView = view

            window.orderFront(nil)
            player.play()

            windows.append(window)
            players.append(player)
            loopers.append(looper)
        }
    }

    // MARK: - Lifecycle

    private func shutdown() {
        configTimer?.invalidate()
        players.forEach { $0.pause() }
        windows.forEach { $0.orderOut(nil) }
        NSApp.terminate(nil)
    }

    @objc private func screensChanged() { rebuildWindows(); applyPowerPolicy() }

    @objc private func screenLocked() {
        log("screen locked — pausing and hiding")
        players.forEach { $0.pause() }
        windows.forEach { $0.orderOut(nil) }

        // Refresh the aerial extension NOW, so by the time the lock screen appears, it has loaded the new file
        DispatchQueue.global(qos: .background).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            proc.arguments = ["WallpaperAerialsExtension"]
            try? proc.run()
            proc.waitUntilExit()
            log("killed WallpaperAerialsExtension for fresh lock screen")
        }
    }

    @objc private func screenUnlocked() {
        log("screen unlocked — resuming")
        if !isPaused { players.forEach { $0.play() } }
        windows.forEach { $0.orderFront(nil) }
    }

    @objc private func displaySleep() {
        log("display sleep — pausing and hiding")
        players.forEach { $0.pause() }
        windows.forEach { $0.orderOut(nil) }
    }

    @objc private func displayWake() {
        log("display wake")
        // The screen might still be locked here, but if not, ensure we resume
        if !isPaused { players.forEach { $0.play() } }
    }

    @objc private func powerStateChanged() { applyPowerPolicy() }

    // MARK: - Power

    private func isOnBattery() -> Bool {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return false }
        for src in sources {
            if let desc = IOPSGetPowerSourceDescription(info, src)?.takeUnretainedValue() as? [String: Any],
               let state = desc[kIOPSPowerSourceStateKey] as? String {
                return state == kIOPSBatteryPowerValue
            }
        }
        return false
    }

    private func applyPowerPolicy() {
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        let battery = isOnBattery()
        let shouldPause = (pauseOnLowPower && lowPower) || (pauseOnBattery && battery)
        log("power: lowPower=\(lowPower) battery=\(battery) shouldPause=\(shouldPause)")
        if shouldPause { isPaused = true; players.forEach { $0.pause() } }
        else { isPaused = false; players.forEach { $0.play() } }
    }
}

// MARK: - Logging

func log(_ msg: String) {
    FileHandle.standardError.write("[engine] \(msg)\n".data(using: .utf8)!)
}

// MARK: - Config

struct Config {
    var video: String
    var fill: String
    var pauseOnBattery: Bool
    var pauseOnLowPower: Bool
}

func loadConfig(path: String) -> Config {
    var cfg = Config(video: "", fill: "fill", pauseOnBattery: false, pauseOnLowPower: false)
    guard let data = FileManager.default.contents(atPath: path),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return cfg }
    if let v = obj["video"] as? String { cfg.video = v }
    if let f = obj["fill"] as? String { cfg.fill = f }
    if let b = obj["pauseOnBattery"] as? Bool { cfg.pauseOnBattery = b }
    if let l = obj["pauseOnLowPower"] as? Bool { cfg.pauseOnLowPower = l }
    return cfg
}

// MARK: - Main

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write("usage: WallpaperEngine <config.json> [--sanity]\n".data(using: .utf8)!)
    exit(2)
}
let sanity = args.contains("--sanity")
var parsedLevel: Int? = nil
if sanity, let i = args.firstIndex(of: "--level"), i + 1 < args.count, let v = Int(args[i + 1]) {
    parsedLevel = v
}
let effectiveLevel = parsedLevel ?? kDefaultWallpaperLevel
let cfg = loadConfig(path: args[1])

guard !cfg.video.isEmpty, FileManager.default.fileExists(atPath: cfg.video) else {
    FileHandle.standardError.write("video not found: \(cfg.video)\n".data(using: .utf8)!)
    exit(3)
}

let gravity: AVLayerVideoGravity = {
    switch cfg.fill {
    case "fit": return .resizeAspect
    case "stretch": return .resize
    default: return .resizeAspectFill
    }
}()

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let engine = WallpaperEngine(
    videoPath: cfg.video,
    fillMode: gravity,
    pauseOnBattery: cfg.pauseOnBattery,
    pauseOnLowPower: cfg.pauseOnLowPower,
    sanityMode: sanity,
    windowLevel: effectiveLevel,
    configPath: args[1]
)
engine.start()
app.run()
