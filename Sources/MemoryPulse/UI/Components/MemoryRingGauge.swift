import SwiftUI

public struct MemoryRingGauge: View {
    public let percentage: Double
    public let pressureLevel: MemoryPressureLevel
    public var size: CGFloat = 130

    @State private var isPulsing = false

    public init(percentage: Double, pressureLevel: MemoryPressureLevel, size: CGFloat = 130) {
        self.percentage = percentage
        self.pressureLevel = pressureLevel
        self.size = size
    }

    private var gradient: LinearGradient {
        switch pressureLevel {
        case .normal:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.85, blue: 0.6), Color(red: 0.1, green: 0.7, blue: 0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .warning:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.75, blue: 0.2), Color(red: 1.0, green: 0.45, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .critical:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.35, blue: 0.35), Color(red: 0.9, green: 0.1, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    public var body: some View {
        ZStack {
            // Track background ring
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 11)
                .frame(width: size, height: size)

            // Dynamic progress ring
            Circle()
                .trim(from: 0.0, to: CGFloat(min(percentage / 100.0, 1.0)))
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: 11, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentage)
                .frame(width: size, height: size)
                .shadow(color: pressureLevel.color.opacity(0.35), radius: 8, x: 0, y: 0)

            // Center details
            VStack(spacing: 2) {
                Text("\(Int(percentage))%")
                    .font(.system(size: size * 0.24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("RAM")
                    .font(.system(size: size * 0.09, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)

                HStack(spacing: 3) {
                    Circle()
                        .fill(pressureLevel.color)
                        .frame(width: 6, height: 6)
                        .scaleEffect(isPulsing ? 1.25 : 0.85)
                        .animation(
                            pressureLevel == .critical ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
                            value: isPulsing
                        )

                    Text(pressureLevel.rawValue)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
        }
        .onAppear {
            if pressureLevel == .critical {
                isPulsing = true
            }
        }
    }
}
