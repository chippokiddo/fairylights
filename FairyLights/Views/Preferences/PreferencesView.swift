import SwiftUI

// MARK: - Preferences Tabs
enum PrefTab: String, CaseIterable {
    case general = "General"
    case lights = "Manage Lights"
    case about = "About"
    
    var systemImage: String {
        switch self {
        case .general: return "gear"
        case .lights: return "lightbulb"
        case .about: return "info"
        }
    }
}

// MARK: - Preferences View
struct PreferencesView: View {
    @EnvironmentObject var updateManager: UpdateManager
    @EnvironmentObject var lightsController: LightsController
    
    @State private var selectedTab: PrefTab = .general
    @State private var hoveredTab: PrefTab? = nil
    
    private var tabBar: some View {
        HStack {
            ForEach(PrefTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var content: some View {
        Group {
            switch selectedTab {
            case .general:
                GeneralView(updateManager: updateManager)
            case .lights:
                ManageLightsView(lightsController: lightsController)
            case .about:
                AboutView()
            }
        }
        .frame(width: 420, height: 320)
    }
    
    var body: some View {
        VStack {
            tabBar
            
            Divider()
                .opacity(0.25)
            
            content
        }
        .frame(width: 420, height: 420)
        .onAppear {
            DispatchQueue.main.async {
                enforceWindowStyle()
            }
        }
    }
    
    private func tabButton(for tab: PrefTab) -> some View {
        let isSelected = (selectedTab == tab)
        let isHovered = (hoveredTab == tab) && (selectedTab != tab)
        
        return Button(action: {
            selectedTab = tab
        }) {
            VStack(spacing: 6) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 20))
                Text(tab.rawValue)
                    .font(.caption)
            }
            .frame(width: 90, height: 62)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isHovered ? Color.primary.opacity(0.15) : Color.clear,
                        lineWidth: isHovered ? 1 : 0
                    )
            )
            .foregroundColor(isSelected ? .accentColor : .primary)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel(Text(tab.rawValue))
        }
        .buttonStyle(.plain)
        .onHover { inside in
            if inside && selectedTab != tab {
                hoveredTab = tab
            } else if hoveredTab == tab {
                hoveredTab = nil
            }
        }
    }
    
    private func enforceWindowStyle() {
        if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "preferencesWindow" }) {
            window.styleMask.remove([.resizable, .miniaturizable])
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        }
    }
}
