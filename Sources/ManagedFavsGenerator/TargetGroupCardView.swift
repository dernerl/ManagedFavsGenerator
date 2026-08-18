import SwiftUI

/// Editor-Karte für einen Target Group: Name, Merge-Modus und die (flache) Liste der Favoriten,
/// die nur für diese Zielgruppe exportiert werden.
struct TargetGroupCardView: View {
    @Bindable var group: TargetGroup
    let items: [Favorite]
    let onAddItem: () -> Void
    let onRemoveItem: (Favorite) -> Void
    let onRemoveGroup: () -> Void
    @State private var isHovering = false

    private var sortedItems: [Favorite] {
        items.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.blue)
                    .imageScale(.medium)

                AppKitTextField(text: $group.name, placeholder: "Group Name")
                    .frame(height: 22)

                Spacer()

                Button(action: onRemoveGroup) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                        .imageScale(.medium)
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1.0 : 0.6)
                .help("Delete this target group")
            }

            Picker("", selection: $group.includeBase) {
                Text("Merge into base set").tag(true)
                Text("Replace base set").tag(false)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .help(group.includeBase
                  ? "Base favorites stay, this group is appended as a subfolder — assign as an additive, lower-priority Cloud policy."
                  : "This group's own toplevel folder replaces the base set entirely for its audience — assign as the highest-priority Cloud policy (ManagedFavorites does not merge across policies).")

            ForEach(sortedItems) { item in
                HStack(alignment: .top, spacing: 8) {
                    VStack(spacing: 6) {
                        AppKitTextField(
                            text: Binding(get: { item.name }, set: { item.name = $0 }),
                            placeholder: "Name"
                        )
                        .frame(height: 20)

                        AppKitTextField(
                            text: Binding(get: { item.url ?? "" }, set: { item.url = $0.isEmpty ? nil : $0 }),
                            placeholder: "URL"
                        )
                        .frame(height: 20)
                    }

                    Button {
                        onRemoveItem(item)
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Remove this favorite from the group")
                }
            }

            Button(action: onAddItem) {
                Label("Add Favorite", systemImage: "plus")
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(isHovering ? 0.12 : 0.08), radius: isHovering ? 12 : 8, y: isHovering ? 6 : 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
