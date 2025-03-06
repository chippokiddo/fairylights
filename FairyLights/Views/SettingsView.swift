import SwiftUI
import Sparkle

struct SettingsView: View {
    let updater: SPUUpdater
    var checkForUpdates: () -> Void
    
    @State private var automaticUpdatesEnabled: Bool = false
    @State private var isCheckingForUpdates = false
    
    var body: some View {
        VStack(alignment: .leading) {
            SettingsForm
        }
        .padding()
        .frame(width: 400, height: 230)
        .onAppear {
            automaticUpdatesEnabled = updater.automaticallyChecksForUpdates
        }
    }
    
    // MARK: Settings Form
    private var SettingsForm: some View {
        Form {
            updateSection
        }
        .formStyle(.grouped)
        .animation(.easeInOut(duration: 0.3), value: automaticUpdatesEnabled)
    }
    
    // MARK: Update Section
    private var updateSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { automaticUpdatesEnabled },
                set: { newValue in
                    automaticUpdatesEnabled = newValue
                    updater.automaticallyChecksForUpdates = newValue
                }
            )) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.clockwise.square.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    Text("Check for Updates Automatically")
                }
            }
            
            if automaticUpdatesEnabled {
                VStack {
                    HStack {
                        Spacer()
                        Picker("Update Frequency", selection: Binding(
                            get: { updater.updateCheckInterval },
                            set: { updater.updateCheckInterval = $0 }
                        )) {
                            Text("Daily").tag(86400.0)
                            Text("Weekly").tag(604800.0)
                            Text("Monthly").tag(2592000.0)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 300)
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            HStack {
                Spacer()
                Button(action: {
                    isCheckingForUpdates = true
                    checkForUpdates()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isCheckingForUpdates = false
                    }
                }) {
                    if isCheckingForUpdates {
                        HStack(spacing: 5) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Checking...")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .regular))
                            Text("Check for Updates")
                                .font(.system(size: 13, weight: .regular))
                        }
                    }
                }
                .buttonStyle(.borderless)
                .disabled(isCheckingForUpdates)
                Spacer()
            }
            .padding(.top, 4)
        }
    }
}
