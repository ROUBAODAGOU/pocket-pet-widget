import AppIntents

struct PetPetIntent: AppIntent {
    static let title: LocalizedStringResource = "抚摸 PocketPal"
    static let description = IntentDescription("轻轻抚摸小动物，增加心情和亲密度。")

    func perform() async -> some IntentResult & ProvidesDialog {
        let outcome = IntentDependencies.perform(.pet)
        return .result(dialog: PetIntentDialog.make(for: .pet, outcome: outcome))
    }
}
