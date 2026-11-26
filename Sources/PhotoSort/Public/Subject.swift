//
//  Subject.swift
//  PhotoSort
//
//  Created by alina on 22.11.2026.
//

import Foundation

/// A subject used to classify and sort photos.
public struct Subject: Sendable, Hashable {
    
    /// The normalized subject label.
    public let label: String

    /// Creates a subject with the given label.
    public init(label: String) {
        self.label = label.trimmingCharacters(in: .whitespaces).lowercased()
    }

    /// A subject representing cats.
    public static let cats = Subject(label: "cat")
    
    /// A subject representing dogs.
    public static let dogs = Subject(label: "dog")
}
