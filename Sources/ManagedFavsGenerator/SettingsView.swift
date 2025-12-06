import SwiftUI

/// Settings View für App-Einstellungen
struct SettingsView: View {
    @AppStorage("defaultToplevelName") private var defaultToplevelName = "managedFavs"
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Toplevel Name")
                        .font(.headline)
                    
                    TextField("Toplevel Name", text: $defaultToplevelName)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("This will be used as the default name for new sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("General")
            }
            
            Section {
                LabeledContent("Version") {
                    Text("1.0.0")
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
        .frame(width: 500, height: 300)
    }
}

#Preview {
    SettingsView()
}
