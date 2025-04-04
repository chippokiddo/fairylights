import SwiftUI

struct ManageLightsView: View {
    @AppStorage("lightMode") private var lightMode: String = LightMode.classic.rawValue
    @AppStorage("solidColorChoice") private var solidColorChoice: String = "default"
    
    @ObservedObject var lightsController: LightsController
    
    var body: some View {
        Form {
            Section {
                Toggle("Toggle Lights", isOn:
                    Binding<Bool>(
                        get: { lightsController.isLightsOn },
                        set: { newValue in
                            lightsController.toggleLights()
                        }
                    )
                )
            }
            
            Section {
                Picker("Color", selection: $solidColorChoice) {
                    Text("Default").tag("default")
                    ForEach(BulbColor.allCases, id: \.self) { color in
                        Text(color.rawValue.capitalized).tag(color.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section {
                Picker("Light Mode", selection: $lightMode) {
                    ForEach(LightMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue.capitalized).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .onChange(of: lightMode) {
            lightsController.syncLightMode()
        }
        .onChange(of: solidColorChoice) {
            lightsController.syncSolidColor()
        }
    }
}
