import SwiftUI

struct SettingsView: View {
    @ObservedObject var updateManager: UpdateManager
    @AppStorage("automaticUpdateChecks") private var automaticUpdateChecks = false
    @AppStorage("updateCheckFrequency") private var updateCheckFrequency: Double = 604800.0
    
    @State private var isCheckingManually = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Form {
            Section {
                updateToggleRow
                
                if automaticUpdateChecks {
                    frequencyPicker
                }
            }
            
            Section {
                checkForUpdatesButton
                updateStatusView
            }
        }
        .formStyle(.grouped)
        .animation(.easeInOut(duration: 0.2), value: automaticUpdateChecks)
        .animation(.easeInOut(duration: 0.3), value: updateManager.isUpdateAvailable)
        .animation(.easeInOut(duration: 0.3), value: updateManager.errorMessage)
        .frame(width: 400, height: 230)
    }
    
    private var updateToggleRow: some View {
        Toggle(isOn: $automaticUpdateChecks) {
            Label {
                Text("Automatic Updates")
            } icon: {
                Image(systemName: "arrow.clockwise")
                    .symbolVariant(.circle.fill)
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private var frequencyPicker: some View {
        Picker("Check Frequency", selection: $updateCheckFrequency) {
            Text("Daily").tag(86400.0)
            Text("Weekly").tag(604800.0)
            Text("Monthly").tag(2592000.0)
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 6)
        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var checkForUpdatesButton: some View {
        Button {
            isCheckingManually = true
            Task {
                updateManager.checkForUpdates()
                try? await Task.sleep(for: .seconds(0.5))
                isCheckingManually = false
            }
        } label: {
            HStack {
                Spacer()
                Group {
                    if updateManager.isChecking || isCheckingManually {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 5)
                        Text("Checking for Updates...")
                    } else {
                        Text("Check for Updates")
                    }
                }
                .font(.body)
                .foregroundStyle(colorScheme == .dark ? .white : .blue)
                Spacer()
            }
        }
        .buttonStyle(.borderless)
        .disabled(updateManager.isChecking || isCheckingManually)
    }
    
    @ViewBuilder
    private var updateStatusView: some View {
        if updateManager.isUpdateAvailable, let version = updateManager.latestVersion {
            Button {
                updateManager.downloadUpdate()
            } label: {
                HStack {
                    Spacer()
                    Label("Version \(version) Available", systemImage: "arrow.down.app")
                        .symbolVariant(.fill)
                        .foregroundStyle(.blue)
                    Spacer()
                }
            }
            .buttonStyle(.borderless)
        } else if let error = updateManager.errorMessage {
            HStack {
                Spacer()
                Label("Error: \(error)", systemImage: "exclamationmark.triangle")
                    .symbolVariant(.fill)
                    .foregroundStyle(.orange)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Spacer()
            }
        } else if updateManager.hasCheckedForUpdates && !updateManager.isChecking && !isCheckingManually {
            HStack {
                Spacer()
                Label("You're up to date", systemImage: "checkmark.circle")
                    .symbolVariant(.fill)
                    .foregroundStyle(.green)
                Spacer()
            }
        }
    }
}
