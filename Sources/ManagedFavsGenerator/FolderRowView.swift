import SwiftUI

/// View für Ordner-Darstellung
struct FolderRowView: View {
    @Bindable var folder: Favorite
    let onRemove: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Folder Icon + Title
                HStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.yellow)
                        .frame(width: 20, height: 20)
                        .imageScale(.medium)
                    
                    Label("Folder", systemImage: "folder.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .imageScale(.small)
                        .labelStyle(.titleOnly)
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                        .imageScale(.medium)
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1.0 : 0.6)
                .help("Delete this folder")
            }
            
            AppKitTextField(
                text: $folder.name,
                placeholder: "Folder Name"
            )
            .frame(height: 22)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(isHovering ? 0.12 : 0.08), radius: isHovering ? 12 : 8, y: isHovering ? 6 : 4)
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
