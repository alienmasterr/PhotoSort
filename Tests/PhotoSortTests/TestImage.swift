//
//  TestImage.swift
//  PhotoSort
//
//  Created by alina on 22.11.2026.
//

import CoreGraphics

struct RGB: Sendable {
    let red: Double
    let green: Double
    let blue: Double
}

enum ImageFactory {
    static func make(width: Int, height: Int, draw: (CGContext) -> Void)
        -> CGImage
    {
        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            preconditionFailure("Cannot create a CGContext")
        }
        draw(context)
        guard let image = context.makeImage() else {
            preconditionFailure("Cannot create a CGImage")
        }
        return image
    }

    static func solid(_ rgb: RGB, size: Int = 64) -> CGImage {
        make(width: size, height: size) { context in
            fill(context, rgb, CGRect(x: 0, y: 0, width: size, height: size))
        }
    }

    static func split(left: RGB, right: RGB, leftColumns: Int, size: Int = 64)
        -> CGImage
    {
        make(width: size, height: size) { context in
            fill(
                context,
                left,
                CGRect(x: 0, y: 0, width: leftColumns, height: size)
            )
            fill(
                context,
                right,
                CGRect(
                    x: leftColumns,
                    y: 0,
                    width: size - leftColumns,
                    height: size
                )
            )
        }
    }

    static func transparent(size: Int = 64) -> CGImage {
        make(width: size, height: size) { _ in }
    }

    private static func fill(_ context: CGContext, _ rgb: RGB, _ rect: CGRect) {
        context.setFillColor(
            red: rgb.red,
            green: rgb.green,
            blue: rgb.blue,
            alpha: 1
        )
        context.fill(rect)
    }
}

struct TestImage: Sendable {
    static let plainWidth = 24
    static let catWidth = 20
    static let uncertainCatWidth = 30
    static let red = TestImage(rgb: RGB(red: 1, green: 0, blue: 0))
    static let green = TestImage(rgb: RGB(red: 0, green: 1, blue: 0))
    static let blue = TestImage(rgb: RGB(red: 0.1, green: 0.2, blue: 0.8))
    let rgb: RGB
    var width = TestImage.plainWidth
    var asCat: TestImage { TestImage(rgb: rgb, width: Self.catWidth) }
    var asUncertainCat: TestImage {
        TestImage(rgb: rgb, width: Self.uncertainCatWidth)
    }
    func makeCGImage() -> CGImage {
        ImageFactory.make(width: width, height: Self.plainWidth) { context in
            context.setFillColor(
                red: rgb.red,
                green: rgb.green,
                blue: rgb.blue,
                alpha: 1
            )
            context.fill(
                CGRect(x: 0, y: 0, width: width, height: Self.plainWidth)
            )
        }
    }
}
