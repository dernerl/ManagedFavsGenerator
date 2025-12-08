import SwiftUI

struct ImportJSONView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var jsonText: String = ""
    let onImport: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                
                Text("Import JSON Configuration")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Paste your JSON configuration below")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)
            
            // Text Editor
            VStack(alignment: .leading, spacing: 8) {
                Text("JSON Content:")
                    .font(.headline)
                
                TextEditor(text: $jsonText)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 250)
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                
                Text("Expected format: JSON array with managed favorites")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button {
                    onImport(jsonText)
                    dismiss()
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.bottom)
        }
        .padding()
        .frame(width: 600, height: 480)
    }
}

#Preview {
    ImportJSONView { jsonString in
        print("Importing: \(jsonString)")
    }
}
