import SwiftUI
import AppKit

/// AppKit-basiertes TextField als Workaround für SwiftUI Keyboard-Event-Probleme
///
/// **Problem:** SwiftUI TextFields auf macOS empfangen manchmal keine Keyboard-Events,
/// obwohl der Cursor blinkt. Dies liegt am unzuverlässigen First Responder Chain in SwiftUI.
///
/// **Lösung:** Native NSTextField via NSViewRepresentable mit explizitem Focus-Management
///
/// **Features:**
/// - Garantierte Keyboard-Event-Empfang
/// - Bidirektionales Binding mit SwiftUI State
/// - Return-Key Handling via onCommit
/// - Automatische Window-Aktivierung
///
/// **Verwendung:**
/// ```swift
/// @State private var text = ""
///
/// AppKitTextField(
///     text: $text,
///     placeholder: "Enter text..."
/// )
/// .frame(height: 22)
/// ```
struct AppKitTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var onCommit: (() -> Void)? = nil
    
    // MARK: - NSViewRepresentable
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = KeyboardReceivingTextField()
        textField.delegate = context.coordinator
        textField.placeholderString = placeholder
        textField.stringValue = text
        textField.bezelStyle = .roundedBezel
        textField.focusRingType = .default
        textField.font = .systemFont(ofSize: NSFont.systemFontSize)
        
        // KRITISCH: TextField muss explizit First Responder werden können
        textField.refusesFirstResponder = false
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        // Nur updaten wenn sich der Text wirklich geändert hat
        // Verhindert unnötige Updates während des Tippens
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        nsView.placeholderString = placeholder
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onCommit: onCommit)
    }
    
    // MARK: - Coordinator
    
    /// Koordinator für Kommunikation zwischen NSTextField und SwiftUI
    class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String
        var onCommit: (() -> Void)?
        
        init(text: Binding<String>, onCommit: (() -> Void)?) {
            _text = text
            self.onCommit = onCommit
        }
        
        /// Called bei jeder Textänderung
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            text = textField.stringValue
        }
        
        /// Behandelt spezielle Keyboard-Commands (z.B. Return-Key)
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                onCommit?()
                return true
            }
            return false
        }
    }
}

// MARK: - KeyboardReceivingTextField

/// Custom NSTextField mit aggressivem First Responder Management
///
/// Diese Subclass garantiert, dass das TextField Keyboard-Events empfängt durch:
/// - Explizites `acceptsFirstResponder = true`
/// - Automatische Window-Aktivierung beim Focus-Wechsel
/// - Window-Aktivierung beim Hinzufügen zur View-Hierarchie
private class KeyboardReceivingTextField: NSTextField {
    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }
    
    /// Stellt sicher, dass das Window key wird, wenn das TextField First Responder wird
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        
        // Sicherstellen, dass das Window auch key ist
        self.window?.makeKeyAndOrderFront(nil)
        
        return result
    }
    
    /// Aktiviert das Window, sobald das TextField zur View-Hierarchie hinzugefügt wird
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        // Beim Hinzufügen zum Window, aktiviere das Window asynchron
        // Verhindert Timing-Probleme während des View-Aufbaus
        if let window = self.window {
            DispatchQueue.main.async {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}
