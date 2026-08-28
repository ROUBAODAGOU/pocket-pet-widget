import AppIntents

struct FeedPetIntent: AppIntent {
    static let title: LocalizedStringResource = "给 PocketPal 喂食"
    static let description = IntentDescription("使用一块星星饼干给小动物喂食。")

    func perform() async -> some IntentResult & ProvidesDialog {
        let outcome = IntentDependencies.perform(.feed)
        return .result(dialog: PetIntentDialog.make(for: .feed, outcome: outcome))
    }
}
