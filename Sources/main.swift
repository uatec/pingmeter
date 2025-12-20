import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Setup the button image
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Hello World App")
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
    }
    
    @objc func helloWorldClicked() {
        print("Hello World clicked")
        // Optionally show an alert
        let alert = NSAlert()
        alert.messageText = "Hello World"
        alert.informativeText = "You clicked the menu item!"
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
app.setActivationPolicy(.accessory) // Hide from Dock, show only in menu bar

// Run the app
app.run()
