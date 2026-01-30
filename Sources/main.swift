import AppKit
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var recentPings: [Double] = []
    let windowSize = 5

    var launchAtLoginItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Setup the button
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Ping Meter")
            button.title = " -- ms"
            button.imagePosition = .imageLeft
        }
        
        // Create the menu
        let menu = NSMenu()
        
        // Add "Hello World" item
        let helloItem = NSMenuItem(title: "Hello World", action: #selector(helloWorldClicked), keyEquivalent: "")
        helloItem.target = self
        menu.addItem(helloItem)
        
        // Add "Launch at Login" item
        launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.target = self
        launchAtLoginItem.state = LaunchAgentManager.shared.isEnabled() ? .on : .off
        menu.addItem(launchAtLoginItem)
        
        // Add separator
        menu.addItem(NSMenuItem.separator())
        
        // Add "Exit" item
        let exitItem = NSMenuItem(title: "Exit", action: #selector(exitClicked), keyEquivalent: "q")
        exitItem.target = self
        menu.addItem(exitItem)
        
        // Assign menu to status item
        statusItem.menu = menu
        
        // Start pinging
        startPingTimer()
    }
    
    func startPingTimer() {
        // Fire every 1 second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.performPing()
        }
    }
    
    func performPing() {
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            task.launchPath = "/sbin/ping"
            task.arguments = ["-c", "1", "1.1.1.1"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                    self.parsePingOutput(output)
                } else {
                    self.parsePingOutput("") // Treat empty output as failure
                }
            } catch {
                print("Failed to run ping: \(error)")
                DispatchQueue.main.async {
                    self.handlePingFailure()
                }
            }
        }
    }
    
    func parsePingOutput(_ output: String) {
        // Example output: ... time=14.5 ms ...
        // We look for "time=" and then the number
        
        let components = output.components(separatedBy: "time=")
        if components.count > 1 {
            let valuePart = components[1]
            // Extract the number (take characters until space)
            let numberString = valuePart.components(separatedBy: " ")[0]
            
            if let timeMs = Double(numberString) {
                DispatchQueue.main.async {
                    self.updateAverage(timeMs)
                }
            } else {
                DispatchQueue.main.async {
                    self.handlePingFailure()
                }
            }
        } else {
            // "time=" not found, likely a timeout or error
            DispatchQueue.main.async {
                self.handlePingFailure()
            }
        }
    }
    
    func handlePingFailure() {
        // Clear recent pings so that when we reconnect, we start fresh
        // instead of averaging with old values.
        recentPings.removeAll()
        
        if let button = statusItem.button {
            button.title = " -.- ms"
        }
    }
    
    func updateAverage(_ newTime: Double) {
        recentPings.append(newTime)
        if recentPings.count > windowSize {
            recentPings.removeFirst()
        }
        
        let average = recentPings.reduce(0, +) / Double(recentPings.count)
        
        if let button = statusItem.button {
            button.title = String(format: " %.1f ms", average)
        }
    }
    
    @objc func helloWorldClicked() {
        let alert = NSAlert()
        alert.messageText = "Hello World"
        alert.informativeText = "Ping Meter is running!"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func toggleLaunchAtLogin() {
        if LaunchAgentManager.shared.isEnabled() {
            LaunchAgentManager.shared.disable()
            launchAtLoginItem.state = .off
        } else {
            LaunchAgentManager.shared.enable()
            launchAtLoginItem.state = .on
        }
    }
    
    @objc func exitClicked() {
        NSApplication.shared.terminate(nil)
    }
}

class LaunchAgentManager {
    static let shared = LaunchAgentManager()
    
    private let label = "io.neutrino.pingmeter"
    
    private var plistUrl: URL? {
        guard let libraryDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else { return nil }
        let launchAgentsDir = libraryDir.appendingPathComponent("LaunchAgents")
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
        
        return launchAgentsDir.appendingPathComponent("\(label).plist")
    }
    
    func isEnabled() -> Bool {
        guard let url = plistUrl else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    func enable() {
        guard let url = plistUrl else { return }
        guard let executablePath = Bundle.main.executablePath else { return }
        
        let plistContent: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "KeepAlive": false
        ]
        
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plistContent, format: .xml, options: 0)
            try data.write(to: url)
        } catch {
            print("Failed to enable launch at login: \(error)")
        }
    }
    
    func disable() {
        guard let url = plistUrl else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

// Create the app and delegate
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)

// Run the app
app.run()
