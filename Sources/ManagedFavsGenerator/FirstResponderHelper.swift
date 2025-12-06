import SwiftUI
import AppKit

/// Helper View für initiales Window Focus Management
///
/// Diese View wird versteckt in der View-Hierarchie platziert und sorgt dafür,
/// dass das Window beim ersten Erscheinen korrekt aktiviert wird.
///
/// **Hinweis:** Der Großteil des Focus-Managements wird jetzt im AppDelegate erledigt.
/// Diese View dient als zusätzliche Absicherung für Edge-Cases.
struct FirstResponderActivator: NSViewRepresentable {
    
    func makeNSView(context: Context) -> NSView {
        FirstResponderNSView()
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Aktivierung bei jedem Update-Cycle versuchen, falls Window nicht key ist
        if let window = nsView.window, !window.isKeyWindow {
            DispatchQueue.main.async {
                NSApplication.shared.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}

// MARK: - FirstResponderNSView

/// Unsichtbare NSView, die Window-Aktivierung beim Hinzufügen zur Hierarchie triggert
private class FirstResponderNSView: NSView {
    override var acceptsFirstResponder: Bool { true }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        guard let window = self.window else { return }
        
        // Mehrere Aktivierungs-Versuche mit steigenden Delays
        // Deckt verschiedene Timing-Szenarien im SwiftUI View-Lifecycle ab
        let delays: [Double] = [0.1, 0.3, 0.5]
        
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                NSApplication.shared.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
                
                // First Responder Chain refreshen
                if let contentView = window.contentView {
                    window.makeFirstResponder(contentView)
                }
            }
        }
    }
}
