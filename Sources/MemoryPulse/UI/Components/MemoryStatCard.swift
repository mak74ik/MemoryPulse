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
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(tintColor)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(subtitle)
                .font(.system(size: 9.5))
                .foregroundColor(.secondary.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(minWidth: 100, maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
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
