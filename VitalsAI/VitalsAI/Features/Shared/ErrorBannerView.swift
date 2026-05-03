import SwiftUI

struct ErrorBannerView: View {
    let message: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.body)

            VStack(alignment: .leading, spacing: 3) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if let retry = retryAction {
                Button("Try Again", action: retry)
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }
        }
        .padding(14)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.orange.opacity(0.3), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    VStack(spacing: 12) {
        ErrorBannerView(message: "HealthKit access was denied.")
        ErrorBannerView(message: "Could not reach the server.", retryAction: { })
    }
    .padding()
}
