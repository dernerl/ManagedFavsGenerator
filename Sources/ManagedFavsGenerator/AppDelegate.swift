import AppKit
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "ManagedFavsGenerator", category: "AppDelegate")

/// Application Delegate für robustes Window- und Keyboard-Focus-Management
///
/// Dieser Delegate löst ein kritisches macOS-SwiftUI-Problem:
/// SwiftUI Windows empfangen manchmal keine Keyboard-Events, obwohl sie sichtbar sind.
/// Dies liegt an fehlender Activation Policy und unzuverlässigem First Responder Management.
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Application Lifecycle
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // KRITISCH: Activation Policy muss VOR dem ersten Window gesetzt werden
        // Ohne .regular kann macOS das Window als nicht keyboard-fähig behandeln
        NSApplication.shared.setActivationPolicy(.regular)
        logger.info("Application activation policy set to .regular")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Sofortige Aktivierung der App
        NSApplication.shared.activate(ignoringOtherApps: true)
        logger.info("Application activated")
        
        // Mehrfache verzögerte Aktivierungs-Versuche
        // Notwendig, da SwiftUI Zeit braucht, die View-Hierarchie aufzubauen
        scheduleWindowActivation()
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        activateAllWindows()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        activateAllWindows()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        activateAllWindows()
        return true
    }
    
    // MARK: - Window Activation
    
    /// Plant mehrere verzögerte Window-Aktivierungs-Versuche
    ///
    /// SwiftUI braucht unterschiedlich lange, um die View-Hierarchie aufzubauen.
    /// Mehrere Versuche mit steigenden Delays garantieren, dass mindestens einer erfolgreich ist.
    private func scheduleWindowActivation() {
        let delays: [Duration] = [.milliseconds(100), .milliseconds(300), .milliseconds(500)]
        
        Task {
            for delay in delays {
                try? await Task.sleep(for: delay)
                activateAllWindows()
            }
        }
    }
    
    /// Aktiviert alle sichtbaren Windows und setzt den Keyboard-Focus
    ///
    /// Diese Methode verwendet mehrere Techniken:
    /// 1. App-Level Activation
    /// 2. Window-Level makeKeyAndOrderFront
    /// 3. Window-Level Trick (floating → normal) um macOS zu zwingen, das Window neu zu evaluieren
    /// 4. First Responder auf das erste verfügbare TextField setzen
    private func activateAllWindows() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        let windows = NSApplication.shared.windows.filter { $0.isVisible && $0.canBecomeKey }
        
        guard !windows.isEmpty else {
            logger.debug("No visible windows to activate")
            return
        }
        
        for window in windows {
            activateWindow(window)
        }
        
        logger.debug("Activated \(windows.count) window(s)")
    }
    
    /// Aktiviert ein einzelnes Window und setzt den Focus auf das erste TextField
    private func activateWindow(_ window: NSWindow) {
        window.makeKeyAndOrderFront(nil)
        
        // Window-Level Trick: Kurzes Anheben zwingt macOS zur Neu-Evaluation
        window.level = .floating
        Task {
            try? await Task.sleep(for: .milliseconds(10))
            window.level = .normal
        }
        
        // First Responder Management
        guard let contentView = window.contentView else { return }
        
        // Erst auf Content View, dann auf erstes TextField
        window.makeFirstResponder(contentView)
        
        if let textField = findFirstTextField(in: contentView) {
            window.makeFirstResponder(textField)
            logger.debug("Set first responder to TextField: \(textField.identifier?.rawValue ?? "unnamed")")
        }
    }
    
    // MARK: - First Responder Search
    
    /// Findet das erste aktive TextField in der View-Hierarchie
    ///
    /// - Parameter view: Die Root-View, in der gesucht werden soll
    /// - Returns: Das erste gefundene NSTextField oder nil
    private func findFirstTextField(in view: NSView) -> NSTextField? {
        // Prüfe, ob die aktuelle View ein TextField ist
        if let textField = view as? NSTextField, 
           textField.isEnabled && 
           !textField.isHidden &&
           textField.acceptsFirstResponder {
            return textField
        }
        
        // Rekursiv durch alle Subviews suchen
        for subview in view.subviews {
            if let found = findFirstTextField(in: subview) {
                return found
            }
        }
        
        return nil
    }
}
