import SwiftUI

struct WeightChart: View {
    let values: [Double]

    var body: some View {
        Canvas { context, size in
            guard values.count > 1, size.width > 0, size.height > 0 else { return }

            let minimum = values.min() ?? 0
            let maximum = values.max() ?? 0
            let padding = max((maximum - minimum) * 0.25, 0.6)
            let low = minimum - padding
            let high = maximum + padding
            let usableHeight = size.height - 12
            let stepX = size.width / CGFloat(values.count - 1)

            func point(for index: Int) -> CGPoint {
                let ratio = (values[index] - low) / max(high - low, 0.001)
                return CGPoint(
                    x: CGFloat(index) * stepX,
                    y: size.height - 6 - CGFloat(ratio) * usableHeight
                )
            }

            for line in 0..<3 {
                let y = 6 + usableHeight * CGFloat(line) / 2
                var grid = Path()
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(
                    grid,
                    with: .color(Color.white.opacity(0.055)),
                    lineWidth: 1
                )
            }

            var line = Path()
            line.move(to: point(for: 0))
            if values.count > 2 {
                for index in 1..<(values.count - 1) {
                    let current = point(for: index)
                    let next = point(for: index + 1)
                    let midpoint = CGPoint(
                        x: (current.x + next.x) / 2,
                        y: (current.y + next.y) / 2
                    )
                    line.addQuadCurve(to: midpoint, control: current)
                }
            }
            line.addLine(to: point(for: values.count - 1))

            var fill = line
            fill.addLine(to: CGPoint(x: size.width, y: size.height))
            fill.addLine(to: CGPoint(x: 0, y: size.height))
            fill.closeSubpath()

            context.fill(
                fill,
                with: .linearGradient(
                    Gradient(colors: [
                        Theme.red.opacity(0.26),
                        Theme.red.opacity(0.015)
                    ]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )

            context.stroke(
                line,
                with: .linearGradient(
                    Gradient(colors: [Theme.red, Color.white.opacity(0.82)]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: 0)
                ),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )

            let last = point(for: values.count - 1)
            let dotRect = CGRect(x: last.x - 4, y: last.y - 4, width: 8, height: 8)
            context.fill(Path(ellipseIn: dotRect), with: .color(Theme.red))
            context.stroke(
                Path(ellipseIn: dotRect.insetBy(dx: -2.5, dy: -2.5)),
                with: .color(Color.white),
                lineWidth: 1.2
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("График веса")
        .accessibilityValue(
            values.last.map { Formatters.kg($0) } ?? "нет данных"
        )
    }
}
