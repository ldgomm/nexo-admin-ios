import SwiftUI

struct NexoAdminUXCard<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.10), lineWidth: 1)
        )
    }
}

struct NexoAdminUXHeroCard: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var systemImage: String = "sparkles.rectangle.stack"
    var badgeTitle: String? = nil
    var badgeSystemImage: String = "circle.fill"
    var isBusy: Bool = false

    var body: some View {
        NexoAdminUXCard(padding: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .frame(width: 46, height: 46)
                    .background(
                        Color.accentColor.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 5) {
                    Text(eyebrow.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)

                    Text(title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)

                Spacer(minLength: 8)

                topTrailingAccessory
            }
        }
    }

    @ViewBuilder
    private var topTrailingAccessory: some View {
        if isBusy {
            ProgressView()
                .controlSize(.small)
                .frame(minHeight: 28, alignment: .top)
        } else if let badgeTitle {
            NexoAdminUXStatusBadge(
                title: badgeTitle,
                systemImage: badgeSystemImage,
                tint: .accentColor
            )
            .lineLimit(1)
            .minimumScaleFactor(0.9)
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(2)
        }
    }
}

struct NexoAdminUXSectionHeader: View {
    let title: String
    let subtitle: String?
    let systemImage: String

    init(_ title: String, subtitle: String? = nil, systemImage: String = "circle.grid.2x2") {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(width: 28, height: 28)
                .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

struct NexoAdminUXStatusBadge: View {
    let title: String
    let systemImage: String
    var tint: Color = .secondary

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule(style: .continuous))
            .foregroundStyle(tint)
    }
}

struct NexoAdminUXMetricTile: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .frame(width: 32, height: 32)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .foregroundStyle(tint)
                Spacer(minLength: 6)
            }
            Text(value)
                .font(.title3.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.08), lineWidth: 1)
        )
    }
}

struct NexoAdminUXNavigationTile<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let destination: Destination

    init(title: String, subtitle: String, systemImage: String, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.destination = destination()
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .frame(width: 38, height: 38)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct NexoAdminUXInlineMessage: View {
    enum Tone {
        case info, success, warning, danger

        var tint: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .warning: return .orange
            case .danger: return .red
            }
        }

        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.seal.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .danger: return "xmark.octagon.fill"
            }
        }
    }

    let title: String
    let message: String
    var tone: Tone = .info

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: tone.icon)
                .font(.headline)
                .foregroundStyle(tone.tint)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct NexoAdminUXLoadingState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NexoAdminUXEmptyState: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 72, height: 72)
                .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

struct NexoAdminUXRefreshButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }
        .disabled(isLoading)
        .accessibilityLabel("Actualizar")
    }
}

struct NexoAdminUXActionButton: View {
    let title: String
    let systemImage: String
    var role: ButtonRole? = nil
    var isProminent: Bool = false
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isEnabled || isLoading)
    }
}

struct NexoAdminUXPlainRow: View {
    let title: String
    let value: String
    var systemImage: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
            }
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 10)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
    }
}
