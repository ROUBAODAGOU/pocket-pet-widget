import SwiftUI

struct AdoptionView: View {
    @ObservedObject var store: AppStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @FocusState private var isNameFocused: Bool
    @State private var name = ""

    var body: some View {
        ScrollView {
            VStack(spacing: PocketPalSpacing.large) {
                PetAvatarView(
                    action: .wandering,
                    size: dynamicTypeSize.isAccessibilitySize ? 150 : 230
                )

                VStack(spacing: PocketPalSpacing.small) {
                    Text("adoption.title")
                        .font(.largeTitle.bold())
                        .foregroundStyle(PocketPalColors.ink)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("adoption-title")

                    Text("adoption.subtitle")
                        .font(.body)
                        .foregroundStyle(PocketPalColors.secondaryInk)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: PocketPalSpacing.small) {
                    TextField(String(localized: "adoption.name.placeholder"), text: $name)
                        .textFieldStyle(.plain)
                        .font(.title3.weight(.semibold))
                        .padding(PocketPalSpacing.medium)
                        .background(PocketPalColors.surface, in: RoundedRectangle(cornerRadius: PocketPalRadius.control))
                        .overlay {
                            RoundedRectangle(cornerRadius: PocketPalRadius.control)
                                .stroke(PocketPalColors.mint, lineWidth: 2)
                        }
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit(submit)
                        .accessibilityLabel(String(localized: "adoption.name.label"))
                        .accessibilityIdentifier("adoption-name-field")

                    HStack(alignment: .firstTextBaseline) {
                        if let error = store.operationErrorMessage {
                            Label(error, systemImage: "exclamationmark.circle.fill")
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .accessibilityIdentifier("adoption-error")
                        }
                        Spacer(minLength: PocketPalSpacing.small)
                        Text("\(visibleCharacterCount)/12")
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(
                                visibleCharacterCount > PetNameValidator.maximumVisibleCharacterCount
                                    ? .red
                                    : PocketPalColors.secondaryInk
                            )
                            .accessibilityLabel("已输入 \(visibleCharacterCount) 个可见字符，最多 12 个")
                            .accessibilityIdentifier("adoption-name-count")
                    }
                }

                Button(action: submit) {
                    HStack {
                        if store.isPerformingAction {
                            ProgressView()
                                .tint(PocketPalColors.ink)
                        }
                        Text("adoption.confirm")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.plain)
                .foregroundStyle(PocketPalColors.ink)
                .background(PocketPalColors.peach, in: RoundedRectangle(cornerRadius: PocketPalRadius.control))
                .disabled(store.isPerformingAction)
                .accessibilityHint(String(localized: "adoption.name.hint"))
                .accessibilityIdentifier("adoption-confirm-button")
            }
            .frame(maxWidth: 560)
            .padding(PocketPalSpacing.extraLarge)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("adoption.keyboard.dismiss") {
                    isNameFocused = false
                }
                .accessibilityIdentifier("adoption-keyboard-dismiss-button")
            }
        }
        .accessibilityIdentifier("adoption-screen")
    }

    private var visibleCharacterCount: Int {
        PetNameValidator.visibleCharacterCount(in: name)
    }

    private func submit() {
        isNameFocused = false
        store.adopt(name: name)
    }
}
