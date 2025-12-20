import AppKit
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var recentPings: [Double] = []
    let windowSize = 5

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
                if let output = String(data: data, encoding: .utf8) {
                    self.parsePingOutput(output)
                }
            } catch {
                print("Failed to run ping: \(error)")
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
            }
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
    
    @objc func exitClicked() {
        NSApplication.shared.terminate(nil)
    }
}

// Create the app and delegate
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)

// Run the app
app.run()
