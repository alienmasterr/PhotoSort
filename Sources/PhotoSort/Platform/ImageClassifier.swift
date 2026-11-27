//
//  ImageClassifier.swift
//  PhotoSort
//
//  Created by alina on 22.11.2026.
//

import CoreGraphics
import Foundation
import Vision

enum ImageClassiffierError: LocalizedError {
    case classificationUnavailable

    var errorDescription: String? {
        switch self {
        case .classificationUnavailable:
            return "Image classification unavailable"
        }
    }
}

struct ClassifiedLabel: Sendable, Hashable {
    let identifier: String
    let confidence: Float
}

protocol ImageClassifierProtocol: Sendable {
    func classify(_ image: CGImage) async throws -> [ClassifiedLabel]
    func supportedLabels() throws -> Set<String>
}

struct ImageClassifier: Sendable, ImageClassifierProtocol {
    private static let classifierConf: Float = 0.1
    func classify(_ image: CGImage) async throws -> [ClassifiedLabel] {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        do {
            try handler.perform([request])
        } catch {
            print("Vision classification error:", error)
            throw ImageClassiffierError.classificationUnavailable
        }

        return request.results?
            .filter { $0.confidence >= Self.classifierConf }
            .map {
                ClassifiedLabel(
                    identifier: $0.identifier,
                    confidence: $0.confidence
                )
            } ?? []
    }

    func supportedLabels() throws -> Set<String> {
        let request = VNClassifyImageRequest()
        let identifiers = try request.supportedIdentifiers()
        return Set(identifiers)
    }
}
