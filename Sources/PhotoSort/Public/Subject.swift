//
//  Subject.swift
//  PhotoSort
//
//  Created by alina on 22.11.2026.
//

public struct Subject: Sendable, Hashable {
    public let label: String

    public init(label: String) {
        self.label = label.trimmingCharacters(in: .whitespaces).lowercased()
    }

    public static let cats = Subject(label: "cat")
    public static let dogs = Subject(label: "dog")
}
