import SwiftUI

/// Settings View für App-Einstellungen
struct SettingsView: View {
    @State private var viewModel = FavoritesViewModel()
    @AppStorage("faviconProvider") private var faviconProvider: FaviconProvider = .google
    
    var body: some View {
        Form {
            Section {
                LabeledContent("Toplevel Name") {
                    TextField("e.g., managedFavs", text: $viewModel.toplevelName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 250)
                }
                .help("The toplevel name for your managed favorites structure")
                
                Text("This name appears as the first entry in the exported JSON/Plist configuration.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        .frame(width: 550, height: 380)
    }
}

#Preview {
    SettingsView()
}
