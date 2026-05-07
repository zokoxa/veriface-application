import SwiftUI

/// An animated background with layered purple waves that slowly shift
/// through shades derived from the VeriFace shark logo.
struct AnimatedWaveBackground: View {
    /// Controls overall opacity of the waves (0 = invisible, 1 = full)
    var intensity: Double = 1.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                drawWaves(context: context, size: size, time: time)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Wave Drawing

    private func drawWaves(context: GraphicsContext, size: CGSize, time: Double) {
        let waveConfigs: [(color: Color, amplitude: CGFloat, frequency: CGFloat, speed: Double, phase: CGFloat, yOffset: CGFloat, opacity: Double)] = [
            // Back wave — lightest, slowest
            (Color(red: 0.85, green: 0.78, blue: 0.95), 30, 1.2, 0.3, 0, 0.55, 0.35 * intensity),
            // Mid wave — medium purple
            (Color(red: 0.72, green: 0.58, blue: 0.92), 25, 1.5, 0.5, 2.0, 0.62, 0.25 * intensity),
            // Front wave — deeper purple, fastest
            (Color(red: 0.55, green: 0.35, blue: 0.85), 20, 1.8, 0.7, 4.0, 0.70, 0.20 * intensity),
            // Accent wave — very subtle light wash near top
            (Color(red: 0.90, green: 0.85, blue: 1.0), 15, 0.8, 0.2, 1.0, 0.35, 0.20 * intensity),
        ]

        for config in waveConfigs {
            let path = wavePath(
                in: size,
                amplitude: config.amplitude,
                frequency: config.frequency,
                phase: config.phase + CGFloat(time * config.speed),
                yOffset: config.yOffset
            )
            context.fill(path, with: .color(config.color.opacity(config.opacity)))
        }
    }

    private func wavePath(in size: CGSize, amplitude: CGFloat, frequency: CGFloat, phase: CGFloat, yOffset: CGFloat) -> Path {
        var path = Path()
        let midY = size.height * yOffset
        let width = size.width
        let step: CGFloat = 2

        path.move(to: CGPoint(x: 0, y: size.height))

        var x: CGFloat = 0
        while x <= width {
            let relativeX = x / width
            let y = midY + sin((relativeX * frequency * .pi * 2) + phase) * amplitude
            if x == 0 {
                path.addLine(to: CGPoint(x: 0, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            x += step
        }

        path.addLine(to: CGPoint(x: width, y: size.height))
        path.closeSubpath()

        return path
    }
}

/// A ready-to-use background that layers the wave animation on top
/// of a soft purple gradient base.
struct BrandAnimatedBackground: View {
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.96, blue: 1.0),
                    Color(red: 0.94, green: 0.91, blue: 0.99),
                    Color(red: 0.96, green: 0.94, blue: 1.0),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Animated waves
            AnimatedWaveBackground(intensity: 1.0)
        }
        .ignoresSafeArea()
    }
}
