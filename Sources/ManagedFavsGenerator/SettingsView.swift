import SwiftUI

/// Settings View für App-Einstellungen
struct SettingsView: View {
    var body: some View {
        Form {
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
        .frame(width: 500, height: 200)
    }
}

#Preview {
    SettingsView()
}
