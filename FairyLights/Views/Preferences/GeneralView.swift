import SwiftUI

struct GeneralView: View {
    @AppStorage("automaticUpdateChecks") private var automaticUpdateChecks = false
    @AppStorage("lightMode") private var lightMode: String = LightMode.classic.rawValue
    @AppStorage("updateCheckFrequency") private var updateCheckFrequency: Double = 604800.0 // Default to weekly
    
    @ObservedObject var updateManager: UpdateManager
    @ObservedObject var lightsController: LightsController
    
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
            
            lightModeSelection
        }
        .formStyle(.grouped)
        .onChange(of: lightMode) {
            lightsController.syncLightMode()
        }
        .animation(.easeInOut(duration: 0.2), value: automaticUpdateChecks)
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
            updateManager.checkForUpdates()
        } label: {
            HStack {
                Spacer()
                Group {
                    if updateManager.status == .checking {
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
        .disabled(updateManager.status == .checking)
    }
    
    @ViewBuilder
    private var updateStatusView: some View {
        switch updateManager.status {
        case .available(let version, _):
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
            
        case .error(let message):
            HStack {
                Spacer()
                Label("Error: \(message)", systemImage: "exclamationmark.triangle")
                    .symbolVariant(.fill)
                    .foregroundStyle(.orange)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            
        case .upToDate:
            HStack {
                Spacer()
                Label("You're up to date", systemImage: "checkmark.circle")
                    .symbolVariant(.fill)
                    .foregroundStyle(.green)
                Spacer()
            }
            
        default:
            EmptyView()
        }
    }
    
    private var lightModeSelection: some View {
        Section {
            Picker("Light Mode", selection: $lightMode) {
                ForEach(LightMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue.capitalized).tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
