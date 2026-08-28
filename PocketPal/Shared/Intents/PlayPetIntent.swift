import AppIntents

struct PlayPetIntent: AppIntent {
    static let title: LocalizedStringResource = "和 PocketPal 玩耍"
    static let description = IntentDescription("和彩虹球玩耍，增加心情、亲密度和金币。")

    func perform() async -> some IntentResult & ProvidesDialog {
        let outcome = IntentDependencies.perform(.play)
        return .result(dialog: PetIntentDialog.make(for: .play, outcome: outcome))
    }
}
