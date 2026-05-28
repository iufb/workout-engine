import SwiftUI

struct ConfettiPiece: Identifiable {
    let id: Int
    let origin: CGPoint
    let size: CGSize
    let color: Color
    let rotationSpeed: Double
    let fallSpeed: CGFloat
    let horizontalDrift: CGFloat
    let driftPhase: Double
}

struct ConfettiView: View {
    @State private var startDate = Date()
    @State private var pieces: [ConfettiPiece] = []

    var body: some View {
        TimelineView(.animation(minimumInterval: WorkoutTheme.confettiAnimationInterval)) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                for piece in pieces {
                    draw(piece, elapsed: elapsed, in: size, context: &context)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            startDate = Date()
            pieces = Self.makePieces(count: WorkoutTheme.confettiPieceCount)
        }
    }

    private func draw(
        _ piece: ConfettiPiece,
        elapsed: TimeInterval,
        in size: CGSize,
        context: inout GraphicsContext
    ) {
        let x = piece.origin.x * size.width
            + sin(elapsed * piece.driftPhase) * piece.horizontalDrift
        let y = piece.origin.y * size.height + CGFloat(elapsed) * piece.fallSpeed

        guard y < size.height + piece.size.height else { return }

        var pieceContext = context
        pieceContext.translateBy(x: x, y: y)
        pieceContext.rotate(by: .degrees(elapsed * piece.rotationSpeed))
        let rect = CGRect(
            x: -piece.size.width / 2,
            y: -piece.size.height / 2,
            width: piece.size.width,
            height: piece.size.height
        )
        pieceContext.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(piece.color))
    }

    private static func makePieces(count: Int) -> [ConfettiPiece] {
        let palette: [Color] = [
            PhaseColors.background(for: .prepare),
            PhaseColors.background(for: .work),
            PhaseColors.background(for: .rest),
            .white,
            Color(red: 1, green: 0.92, blue: 0.4),
        ]

        return (0..<count).map { index in
            let seed = Double(index)
            let originX = pseudoRandom(seed * 1.7)
            let originY = -0.05 - pseudoRandom(seed * 2.3) * 0.25
            let width = 6 + pseudoRandom(seed * 3.1) * 8
            let height = 10 + pseudoRandom(seed * 4.7) * 14
            let colorIndex = Int(pseudoRandom(seed * 5.9) * Double(palette.count)) % palette.count

            return ConfettiPiece(
                id: index,
                origin: CGPoint(x: originX, y: originY),
                size: CGSize(width: width, height: height),
                color: palette[colorIndex],
                rotationSpeed: (pseudoRandom(seed * 6.3) - 0.5) * 280,
                fallSpeed: 120 + CGFloat(pseudoRandom(seed * 7.1)) * 180,
                horizontalDrift: 12 + CGFloat(pseudoRandom(seed * 8.4)) * 36,
                driftPhase: 1.2 + pseudoRandom(seed * 9.2) * 2.4
            )
        }
    }

    private static func pseudoRandom(_ seed: Double) -> Double {
        let value = sin(seed * 12.9898) * 43758.5453
        return value - floor(value)
    }
}

#Preview {
    ZStack {
        WorkoutFinishBackground()
        ConfettiView()
    }
}
