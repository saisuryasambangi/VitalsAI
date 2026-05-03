import SwiftUI

struct StreamingInsightView: View {
    @State private var messageIndex = 0

    private let messages = [
        "Reading your step count...",
        "Checking heart rate trends...",
        "Reviewing your sleep patterns...",
        "Comparing to health benchmarks...",
        "Composing your insight..."
    ]

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                    .symbolEffect(.pulse, options: .repeating)

                VStack(spacing: 12) {
                    Text("Analyzing your health data...")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(messages[messageIndex])
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .animation(.easeInOut(duration: 0.4), value: messageIndex)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                ProgressView()
                    .progressViewStyle(.linear)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, 32)
        }
        .task {
            await rotateMessages()
        }
    }

    private func rotateMessages() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { break }
            messageIndex = (messageIndex + 1) % messages.count
        }
    }
}

#Preview {
    StreamingInsightView()
}
