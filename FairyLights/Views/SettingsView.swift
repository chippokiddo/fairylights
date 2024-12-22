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
            HStack {
                Image(systemName: "arrow.clockwise.square.fill")
                    .foregroundColor(.secondary)
                    .font(.title2)
                Toggle("Check for Updates Automatically", isOn: $appState.checkForUpdatesAutomatically)
            }
            
            if appState.checkForUpdatesAutomatically {
                Text("Updates will be checked once a day.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Window Adjustment
    private func adjustWindowAppearance() {
        if let window = NSApp.windows.first(where: { $0.title == "Settings" }) {
            window.styleMask.remove(.miniaturizable)
            window.canHide = false
        }
    }
}
