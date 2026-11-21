//
//  SubjectMatcher.swift
//  PhotoSort
//
//  Created by alina on 21.11.2026.
//

import Vision

func printSupportedLabels() {
    do {
        let request = VNClassifyImageRequest()
        request.revision = VNClassifyImageRequestRevision1

        let labels = try request.supportedIdentifiers()
        for label in labels {
            print(label)
        }
    } catch {
        print("Error fetching supported identifiers: \(error)")
    }
}
