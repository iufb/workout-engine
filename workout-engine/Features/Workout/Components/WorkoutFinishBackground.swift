import SwiftUI

struct WorkoutFinishBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    PhaseColors.background(for: .work),
                    PhaseColors.background(for: .work).opacity(0.88),
                    PhaseColors.background(for: .rest).opacity(0.55),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    PhaseColors.background(for: .prepare).opacity(0.35),
                    .clear,
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 420
            )

            LinearGradient(
                colors: [.white.opacity(0.14), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    WorkoutFinishBackground()
}
