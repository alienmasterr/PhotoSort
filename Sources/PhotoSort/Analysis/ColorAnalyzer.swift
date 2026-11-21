//
//  ColorAnalyzer.swift
//  PhotoSort
//
//  Created by alina on 21.11.2026.
//

// поняття не маю, як працює теорія кольору, тому в роботі з кольором використовувала допомогу ші
import CoreGraphics

struct ColorAnalysis: Sendable {
    let color: NamedColor
    let share: Double
}

struct ColorAnalyzer {
    private let minimumColorShare: Double

    init(minimumColorShare: Double = 0.6) {
        self.minimumColorShare = minimumColorShare
    }

    func analyze(_ image: CGImage) -> ColorAnalysis? {
        let width = 64
        let height = 64
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let success = pixels.withUnsafeMutableBytes { buffer -> Bool in
            let info = CGBitmapInfo.byteOrder32Big.union(
                CGBitmapInfo(
                    rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            )

            guard
                let context = CGContext(
                    data: buffer.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: info.rawValue
                )
            else {
                return false
            }

            context.interpolationQuality = .high
            context.draw(
                image,
                in: CGRect(x: 0, y: 0, width: width, height: height)
            )
            return true
        }

        guard success else { return nil }

        var colors: [NamedColor: Double] = [:]
        var totalWeight = 0.0

        for i in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = Double(pixels[i + 3]) / 255
            if alpha == 0 { continue }

            let red = min(Double(pixels[i]) / 255 / alpha, 1)
            let green = min(Double(pixels[i + 1]) / 255 / alpha, 1)
            let blue = min(Double(pixels[i + 2]) / 255 / alpha, 1)

            let color = colorForPixel(red: red, green: green, blue: blue)
            let saturation = rgbToHSB(red: red, green: green, blue: blue)
                .saturation
            let weight = max(saturation, 0.15) * alpha

            colors[color, default: 0] += weight
            totalWeight += weight
        }

        guard totalWeight > 0,
            let dominant = colors.max(by: { $0.value < $1.value })
        else {
            return nil
        }

        let share = dominant.value / totalWeight
        if share < minimumColorShare { return nil }
        return ColorAnalysis(color: dominant.key, share: share)
    }

    private func rgbToHSB(
        red: Double,
        green: Double,
        blue: Double
    ) -> (hue: Double, saturation: Double, brightness: Double) {

        let maxValue = max(red, green, blue)
        let minValue = min(red, green, blue)
        let diff = maxValue - minValue
        let brightness = maxValue
        let saturation = maxValue == 0 ? 0 : diff / maxValue
        var hue = 0.0

        if diff > 0 {
            switch maxValue {
            case red:
                hue = (green - blue) / diff
                if green < blue { hue += 6 }
            case green:
                hue = (blue - red) / diff + 2
            default:
                hue = (red - green) / diff + 4
            }
            hue /= 6
        }

        return (hue, saturation, brightness)
    }

    private func colorForPixel(
        red: Double,
        green: Double,
        blue: Double
    ) -> NamedColor {
        let hsb = rgbToHSB(red: red, green: green, blue: blue)

        if hsb.brightness <= 0.15 { return .black }
        if hsb.saturation <= 0.18 {
            return hsb.brightness >= 0.85 ? .white : .gray
        }
        if hsb.hue < 0.04 || hsb.hue >= 0.94 { return .red }
        if hsb.hue < 0.11 { return hsb.brightness < 0.55 ? .brown : .orange }
        if hsb.hue < 0.17 { return .yellow }
        if hsb.hue < 0.38 { return .green }
        if hsb.hue < 0.48 { return .lightBlue }
        if hsb.hue < 0.67 { return .darkBlue }
        if hsb.hue < 0.80 { return .purple }
        return .pink
    }
}
