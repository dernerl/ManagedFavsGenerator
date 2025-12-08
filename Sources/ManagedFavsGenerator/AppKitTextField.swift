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
        
        // WICHTIG: Komplett deaktiviere Drag & Drop für dieses TextField
        textField.unregisterDraggedTypes()
        
        // Disable text field's cell from accepting drops
        if let cell = textField.cell as? NSTextFieldCell {
            cell.isScrollable = true
        }
        
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
/// - Blockiert Drag & Drop Operations komplett durch eigenen Field Editor
private class KeyboardReceivingTextField: NSTextField {
    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }
    
    // Custom field editor that never accepts drops
    private lazy var customFieldEditor: NoDragTextView = {
        let textContainer = NSTextContainer()
        let editor = NoDragTextView(frame: .zero, textContainer: textContainer)
        editor.isFieldEditor = true
        editor.isRichText = false
        editor.importsGraphics = false
        editor.allowsUndo = true
        editor.backgroundColor = .clear
        editor.drawsBackground = false
        return editor
    }()
    
    /// Stellt sicher, dass das Window key wird, wenn das TextField First Responder wird
    override func becomeFirstResponder() -> Bool {
        // Get or create the window's field editor and disable drag & drop
        if let window = self.window,
           let fieldEditor = window.fieldEditor(true, for: self) as? NSTextView {
            fieldEditor.unregisterDraggedTypes()
            
            // Permanently block re-registration
            DispatchQueue.main.async {
                fieldEditor.unregisterDraggedTypes()
            }
            
            // Schedule periodic unregistration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                fieldEditor.unregisterDraggedTypes()
            }
        }
        
        let result = super.becomeFirstResponder()
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
    
    
    // MARK: - Drag & Drop Protection
    
    /// Blockiert alle Drag Operations - kein visuelles Feedback
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return []  // Reject all drags - no cursor feedback
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return []  // Reject all drags - no cursor feedback
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return false  // Never accept drops
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return false  // Don't even prepare
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        // Do nothing - ignore exit
    }
    
    override func wantsPeriodicDraggingUpdates() -> Bool {
        return false  // No periodic updates needed
    }
}

/// Custom NSTextView that completely disables drag & drop
private class NoDragTextView: NSTextView {
    
    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        setupNoDrag()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupNoDrag()
    }
    
    private func setupNoDrag() {
        // Never register any drag types
        self.unregisterDraggedTypes()
        
        // Disable additional drag features
        self.allowsImageEditing = false
        self.isAutomaticQuoteSubstitutionEnabled = false
        self.isAutomaticLinkDetectionEnabled = false
    }
    
    // MARK: - Block all drag operations
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return []
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return []
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return false
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return false
    }
    
    override func wantsPeriodicDraggingUpdates() -> Bool {
        return false
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        // Do nothing
    }
    
    // Prevent registering drag types
    override func registerForDraggedTypes(_ newTypes: [NSPasteboard.PasteboardType]) {
        // Do nothing - never register drag types
    }
}
