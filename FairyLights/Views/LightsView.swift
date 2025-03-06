import SwiftUI
import AppKit

struct LightsView: View {
    let width: CGFloat
    private let lightSpacing: CGFloat = 60
    private let verticalAmplitude: CGFloat = 10
    private let menuBarHeight = NSStatusBar.system.thickness
    private let bulbHeight: CGFloat = 30

    var body: some View {
        ZStack {
            let lightCount = Int((width / lightSpacing).rounded(.down)) + 1
            let startingOffset = (width - CGFloat(lightCount - 1) * lightSpacing) / 2

            // Draw the wire
            Path { path in
                path.move(to: CGPoint(x: startingOffset, y: menuBarHeight))

                for index in 1..<lightCount {
                    let xOffset = startingOffset + CGFloat(index) * lightSpacing
                    let sineOffset = sin(CGFloat(index) * .pi / 4) * verticalAmplitude
                    let yOffset = menuBarHeight + sineOffset

                    let previousX = startingOffset + CGFloat(index - 1) * lightSpacing
                    let controlX = (xOffset + previousX) / 2
                    let controlY = yOffset + 5

                    path.addQuadCurve(to: CGPoint(x: xOffset, y: yOffset),
                                      control: CGPoint(x: controlX, y: controlY))
                }
            }
            .stroke(Color.black, lineWidth: 3)

            // Draw the bulbs
            ForEach(0..<lightCount, id: \.self) { index in
                let xOffset = startingOffset + CGFloat(index) * lightSpacing
                let sineOffset = sin(CGFloat(index) * .pi / 4) * verticalAmplitude
                let wireY = menuBarHeight + sineOffset

                // Determine bulb orientation
                let isUpsideDown = Bool.random()
                let yAdjustment = isUpsideDown ? 0 : -bulbHeight
                let positionY = wireY + (bulbHeight / 2) + yAdjustment

                // Apply slight rotation
                let rotation = isUpsideDown ? CGFloat.random(in: -10...10) + 180 : CGFloat.random(in: -10...10)

                BulbView()
                    .rotationEffect(.degrees(rotation))
                    .frame(width: bulbHeight, height: bulbHeight)
                    .position(x: xOffset, y: positionY)
            }
        }
        .frame(width: width, height: menuBarHeight + bulbHeight + verticalAmplitude)
        .background(Color.clear)
    }
}
