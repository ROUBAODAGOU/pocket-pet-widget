import SwiftUI

struct PetAvatarView: View {
    var action: PetAction
    var size: CGFloat = 220

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor.opacity(0.55))
                .padding(size * 0.03)

            Ellipse()
                .fill(PocketPalColors.faceInk.opacity(0.10))
                .frame(width: size * 0.52, height: size * 0.10)
                .offset(y: size * 0.37)

            tail
            bodyShape
            head
            actionAccent
        }
        .frame(width: size, height: size)
        .offset(y: isFloating ? -size * 0.025 : size * 0.015)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 1.15).repeatForever(autoreverses: true),
            value: isFloating
        )
        .onAppear {
            isFloating = !reduceMotion
        }
        .onChange(of: reduceMotion) { _, newValue in
            isFloating = !newValue
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var tail: some View {
        Capsule()
            .fill(PocketPalColors.cream)
            .frame(width: size * 0.40, height: size * 0.13)
            .rotationEffect(.degrees(action == .playing ? -28 : 22))
            .offset(x: size * 0.25, y: size * 0.18)
    }

    private var bodyShape: some View {
        Ellipse()
            .fill(PocketPalColors.cream)
            .frame(width: size * 0.56, height: size * 0.48)
            .offset(y: size * 0.18)
            .overlay(alignment: .bottom) {
                HStack(spacing: size * 0.16) {
                    paw
                    paw
                }
                .offset(y: -size * 0.015)
            }
    }

    private var paw: some View {
        Capsule()
            .fill(PocketPalColors.creamHighlight)
            .frame(width: size * 0.16, height: size * 0.10)
    }

    private var head: some View {
        ZStack {
            HStack(spacing: size * 0.30) {
                CatEarShape()
                    .fill(PocketPalColors.cream)
                    .overlay {
                        CatEarShape()
                            .fill(PocketPalColors.peach.opacity(0.75))
                            .padding(size * 0.035)
                    }
                CatEarShape()
                    .fill(PocketPalColors.cream)
                    .overlay {
                        CatEarShape()
                            .fill(PocketPalColors.peach.opacity(0.75))
                            .padding(size * 0.035)
                    }
            }
            .frame(width: size * 0.60, height: size * 0.26)
            .offset(y: -size * 0.23)

            Circle()
                .fill(PocketPalColors.creamHighlight)
                .frame(width: size * 0.62, height: size * 0.62)

            face
        }
        .offset(y: -size * 0.08)
    }

    private var face: some View {
        VStack(spacing: size * 0.045) {
            HStack(spacing: size * 0.16) {
                eye
                eye
            }

            HStack(spacing: size * 0.025) {
                Circle()
                    .fill(PocketPalColors.peach.opacity(0.55))
                    .frame(width: size * 0.075, height: size * 0.04)
                mouth
                Circle()
                    .fill(PocketPalColors.peach.opacity(0.55))
                    .frame(width: size * 0.075, height: size * 0.04)
            }
        }
        .offset(y: size * 0.035)
    }

    @ViewBuilder
    private var eye: some View {
        if action == .sleeping || action == .enjoyingPet {
            Capsule()
                .fill(PocketPalColors.faceInk)
                .frame(width: size * 0.09, height: size * 0.018)
        } else {
            Circle()
                .fill(PocketPalColors.faceInk)
                .frame(width: size * 0.09, height: size * 0.11)
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(.white.opacity(0.9))
                        .frame(width: size * 0.025, height: size * 0.025)
                        .padding(size * 0.014)
                }
        }
    }

    private var mouth: some View {
        PetMouthShape(isHappy: action != .resting && action != .seekingFood)
            .stroke(PocketPalColors.faceInk, style: StrokeStyle(lineWidth: max(2, size * 0.012), lineCap: .round))
            .frame(width: size * 0.11, height: size * 0.07)
    }

    @ViewBuilder
    private var actionAccent: some View {
        switch action {
        case .eating, .seekingFood:
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.13, weight: .bold))
                .foregroundStyle(PocketPalColors.peach)
                .background(Circle().fill(PocketPalColors.creamHighlight).padding(-size * 0.03))
                .offset(x: -size * 0.25, y: size * 0.24)
        case .enjoyingPet:
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.13, weight: .bold))
                .foregroundStyle(PocketPalColors.peach)
                .offset(x: size * 0.28, y: -size * 0.28)
        case .playing:
            Circle()
                .fill(
                    LinearGradient(
                        colors: [PocketPalColors.peach, PocketPalColors.sky, PocketPalColors.mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.22, height: size * 0.22)
                .overlay(Circle().stroke(.white.opacity(0.75), lineWidth: size * 0.018))
                .offset(x: size * 0.29, y: size * 0.27)
        case .sleeping:
            Text("Zzz")
                .font(.system(size: size * 0.12, weight: .bold, design: .rounded))
                .foregroundStyle(PocketPalColors.sky)
                .offset(x: size * 0.29, y: -size * 0.28)
        case .resting:
            Image(systemName: "drop.fill")
                .font(.system(size: size * 0.10, weight: .bold))
                .foregroundStyle(PocketPalColors.sky)
                .offset(x: size * 0.28, y: -size * 0.20)
        case .wandering:
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.12, weight: .semibold))
                .foregroundStyle(PocketPalColors.lavender)
                .offset(x: -size * 0.30, y: -size * 0.26)
        }
    }

    private var backgroundColor: Color {
        switch action {
        case .eating, .seekingFood: PocketPalColors.peach
        case .enjoyingPet: PocketPalColors.lavender
        case .playing: PocketPalColors.sky
        case .sleeping: PocketPalColors.lavender
        case .resting: PocketPalColors.sky
        case .wandering: PocketPalColors.mint
        }
    }

    private var accessibilityDescription: String {
        if action == .resting {
            return "奶油团子猫有点难过，正在发呆"
        }
        return "奶油团子猫，正在\(action.displayName)"
    }
}

private struct CatEarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.height * 0.25)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.height * 0.82)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.height * 0.25)
        )
        return path
    }
}

private struct PetMouthShape: Shape {
    var isHappy: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.height * 0.25))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: isHappy ? rect.maxY : rect.height * 0.12),
            control: CGPoint(x: rect.width * 0.25, y: isHappy ? rect.maxY : rect.minY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.height * 0.25),
            control: CGPoint(x: rect.width * 0.75, y: isHappy ? rect.maxY : rect.minY)
        )
        return path
    }
}
