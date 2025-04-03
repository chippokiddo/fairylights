import SwiftUI

// MARK: - AboutView
struct AboutView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Match style with GeneralView
            Form { }
                .formStyle(.grouped)
                .opacity(0)
            
            VStack(spacing: 20) {
                // App Icon
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 5)
                
                Text("Fairy Lights")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 10)
                
                VStack(spacing: 5) {
                    Text("Version \(version)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(copyright)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                // Buttons
                HStack(spacing: 20) {
                    AboutButton(
                        url: "https://github.com/chippokiddo/fairylights",
                        title: "GitHub",
                        systemImage: "link"
                    )
                    
                    AboutButton(
                        url: "https://www.buymeacoffee.com/chippo",
                        title: "Support",
                        systemImage: "cup.and.saucer"
                    )
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(30)
        }
        .animation(.easeInOut(duration: 0.2), value: true)
    }
    
    // MARK: - App Version
    private var version: String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(shortVersion) (\(buildNumber))"
    }
    
    // MARK: - Copyright Text
    private var copyright: String {
        Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "© chip"
    }
}

// MARK: - About Button
private struct AboutButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered: Bool = false
    
    let url: String
    let title: String
    let systemImage: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(colorScheme == .dark ? .white : .blue)
                Text(title)
                    .foregroundColor(colorScheme == .dark ? .white : .blue)
            }
            .font(.callout)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHovered ? Color.gray : Color.clear, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
