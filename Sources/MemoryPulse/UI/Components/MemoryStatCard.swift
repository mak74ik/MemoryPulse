import SwiftUI

public struct MemoryStatCard: View {
    public let title: String
    public let value: String
    public let subtitle: String
    public let icon: String
    public let tintColor: Color

    public init(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        tintColor: Color
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.tintColor = tintColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(tintColor)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}
