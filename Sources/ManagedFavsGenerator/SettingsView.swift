import SwiftUI
import SwiftData

/// Settings View für App-Einstellungen
struct SettingsView: View {
    @Query(sort: \Profile.order) private var profiles: [Profile]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("activeProfileID") private var activeProfileIDString: String = ""
    @AppStorage("faviconProvider") private var faviconProvider: FaviconProvider = .google

    private var activeProfile: Profile? {
        if let id = UUID(uuidString: activeProfileIDString), let match = profiles.first(where: { $0.id == id }) {
            return match
        }
        return profiles.sorted(by: { $0.order < $1.order }).first
    }

    var body: some View {
        Form {
            Section {
                if let activeProfile {
                    LabeledContent("Toplevel Name") {
                        TextField("e.g., managedFavs", text: Binding(
                            get: { activeProfile.toplevelName },
                            set: {
                                activeProfile.toplevelName = $0
                                try? modelContext.save()
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 250)
                    }
                    .help("The toplevel name for the active profile's (\(activeProfile.name)) managed favorites structure")

                    Text("This name appears as the first entry in the exported JSON/Plist configuration for the \(activeProfile.name) profile. Each profile has its own toplevel name — switch profiles in the main window to edit another one.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No profile selected yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Configuration")
            }

            Divider()

            Section {
                Picker("Favicon Provider", selection: $faviconProvider) {
                    ForEach(FaviconProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .help("Choose which service to use for loading favicons")

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                            .imageScale(.small)
                        Text(faviconProvider.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Appearance")
            }

            Divider()

            Section {
                LabeledContent("Version") {
                    Text("1.1.0")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Build") {
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .frame(width: 550, height: 400)
    }
}

#Preview {
    SettingsView()
}
