import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    var checkForUpdates: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            SettingsForm
        }
        .padding()
        .frame(width: 400, height: 150)
    }
    
    // MARK: - Settings Form
    private var SettingsForm: some View {
        Form {
            updateSection
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Update Section
    private var updateSection: some View {
        Section {
            // Toggle for automatic updates
            Toggle("Check for Updates Automatically", isOn: $appState.checkForUpdatesAutomatically)
            
            if appState.checkForUpdatesAutomatically {
                Text("Updates will be checked once a day.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
