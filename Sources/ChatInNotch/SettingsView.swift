import FoundationModels
import SwiftUI

/// Settings window: for now just information, nothing to configure.
struct SettingsView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    }

    var body: some View {
        VStack(spacing: 14) {
            AppIconImage(side: 84)
            VStack(spacing: 2) {
                Text("Chat in Notch").font(.title3.weight(.semibold))
                Text("Version \(version)").font(.caption).foregroundStyle(.secondary)
            }
            let status = ModelStatus.current
            Label(
                status.isReady ? "On-device model ready" : status.text,
                systemImage: status.isReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
            )
            .font(.callout)
            .foregroundStyle(status.isReady ? Color.green : Color.orange)
            Text("Chat with Apple Foundation Models, offline and private.\nConversations stay on this Mac.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Show conversations in Finder") {
                NSWorkspace.shared.open(AppPaths.support)
            }
            .controlSize(.small)
        }
        .padding(24)
        .frame(width: 320)
        .fixedSize()
    }
}
