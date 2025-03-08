import SwiftUI

struct AboutView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Match style with SettingsView
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
                    Text("Version \(Bundle.main.appVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(Bundle.main.copyrightText)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                // Buttons
                HStack(spacing: 20) {
                    AboutButton(
                        title: "GitHub",
                        systemImage: "link",
                        url: "https://github.com/chippokiddo/fairylights"
                    )
                    
                    AboutButton(
                        title: "Support",
                        systemImage: "cup.and.saucer",
                        url: "https://www.buymeacoffee.com/chippo"
                    )
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(30)
        }
        .frame(width: 400, height: 320)
        .animation(.easeInOut(duration: 0.2), value: true)
    }
}

struct AboutButton: View {
    let title: String
    let systemImage: String
    let url: String
    @State private var isHovered: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
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

extension Bundle {
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var copyrightText: String {
        return Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? "Copyright © chip"
    }
}
