import SwiftUI

struct HomeView: View {
    @ObservedObject var store: AppStore
    var snapshot: WidgetSnapshot

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: PocketPalSpacing.large) {
                header

                PetAvatarView(
                    action: snapshot.action,
                    size: dynamicTypeSize.isAccessibilitySize ? 135 : 220
                )

                statusGrid

                InteractionButtons(
                    snapshot: snapshot,
                    isBusy: store.isPerformingAction,
                    perform: store.perform
                )

                if let feedback = store.feedbackMessage {
                    FeedbackBanner(
                        message: feedback,
                        systemImage: "sparkles",
                        tint: PocketPalColors.mint
                    )
                    .accessibilityIdentifier("interaction-feedback")
                }

                if let error = store.operationErrorMessage {
                    FeedbackBanner(
                        message: error,
                        systemImage: "exclamationmark.circle.fill",
                        tint: PocketPalColors.peach
                    )
                    .accessibilityIdentifier("interaction-error")
                }

                if store.showsWidgetGuide {
                    widgetGuide
                }
            }
            .frame(maxWidth: 680)
            .padding(PocketPalSpacing.large)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("home-screen")
        .accessibilityValue(
            "\(dynamicTypeDescription)，\(colorSchemeDescription)"
        )
    }

    private var header: some View {
        VStack(spacing: PocketPalSpacing.small) {
            Text(snapshot.petName)
                .font(.largeTitle.bold())
                .foregroundStyle(PocketPalColors.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("home-pet-name")

            Label(snapshot.action.displayName, systemImage: actionIcon)
                .font(.headline)
                .foregroundStyle(PocketPalColors.secondaryInk)
                .padding(.horizontal, PocketPalSpacing.medium)
                .padding(.vertical, PocketPalSpacing.small)
                .background(PocketPalColors.surface, in: Capsule())
                .accessibilityIdentifier("home-current-action")
        }
    }

    private var statusGrid: some View {
        LazyVGrid(
            columns: dynamicTypeSize.isAccessibilitySize
                ? [GridItem(.flexible())]
                : [GridItem(.flexible()), GridItem(.flexible())],
            spacing: PocketPalSpacing.medium
        ) {
            StatusCard(kind: .mood, value: snapshot.mood)
            StatusCard(kind: .hunger, value: snapshot.hunger)
            StatusCard(kind: .intimacy, value: snapshot.intimacy)
            StatusCard(kind: .coins, value: snapshot.coins)
        }
        .accessibilityIdentifier("home-status-grid")
    }

    private var widgetGuide: some View {
        VStack(alignment: .leading, spacing: PocketPalSpacing.small) {
            Label("guide.title", systemImage: "apps.iphone")
                .font(.headline)
            Text("guide.body")
                .font(.subheadline)
                .foregroundStyle(PocketPalColors.secondaryInk)
            Button("guide.dismiss") {
                store.dismissWidgetGuide()
            }
            .font(.subheadline.bold())
            .accessibilityIdentifier("dismiss-widget-guide")
        }
        .foregroundStyle(PocketPalColors.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PocketPalSpacing.large)
        .background(PocketPalColors.sky.opacity(0.45), in: RoundedRectangle(cornerRadius: PocketPalRadius.card))
        .accessibilityIdentifier("widget-guide")
    }

    private var actionIcon: String {
        switch snapshot.action {
        case .eating: "fork.knife"
        case .enjoyingPet: "hand.raised.fill"
        case .playing: "circle.grid.cross.fill"
        case .sleeping: "moon.zzz.fill"
        case .seekingFood: "takeoutbag.and.cup.and.straw.fill"
        case .resting: "cloud.fill"
        case .wandering: "pawprint.fill"
        }
    }

    private var dynamicTypeDescription: String {
        dynamicTypeSize == .accessibility5 ? "最大辅助字号" : "动态字号"
    }

    private var colorSchemeDescription: String {
        colorScheme == .dark ? "深色模式" : "浅色模式"
    }
}

private struct FeedbackBanner: View {
    var message: String
    var systemImage: String
    var tint: Color

    var body: some View {
        Label(message, systemImage: systemImage)
            .font(.subheadline)
            .foregroundStyle(PocketPalColors.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PocketPalSpacing.medium)
            .background(tint.opacity(0.42), in: RoundedRectangle(cornerRadius: PocketPalRadius.control))
    }
}
