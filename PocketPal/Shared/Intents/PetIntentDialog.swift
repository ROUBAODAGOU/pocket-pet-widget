import AppIntents

enum PetIntentDialog {
    static func make(
        for interaction: PetInteraction,
        outcome: PetIntentExecutionOutcome
    ) -> IntentDialog {
        switch outcome {
        case .success:
            switch interaction {
            case .feed: IntentDialog("喂食成功，小家伙正在开心吃饭。")
            case .pet: IntentDialog("抚摸成功，小家伙舒服地眯起眼睛。")
            case .play: IntentDialog("玩耍成功，还捡到了两枚金币。")
            }
        case .failure(.noPet):
            IntentDialog("还没有宠物，请先打开 PocketPal 完成领养。")
        case .failure(.noSnacks):
            IntentDialog("星星饼干用完了，请打开背包补充。")
        case .failure(.notHungry):
            IntentDialog("现在还不饿，晚一点再喂吧。")
        case .failure(.cooldown):
            IntentDialog("小家伙正在休息，稍后再试。")
        case .failure(.storage):
            IntentDialog("这次互动没有完成，请打开 PocketPal 检查本地数据。")
        }
    }
}
