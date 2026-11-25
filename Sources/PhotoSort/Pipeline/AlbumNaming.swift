//
//  AlbumNaming.swift
//  PhotoSort
//
//  Created by alina on 22.11.2026.
//

import Foundation

struct AlbumName: Hashable, Sendable {
    let colors: Set<NamedColor>?
    let subjects: Set<Subject>?
}

struct AlbumNaming: Sendable {
    let prefix: String
    let calendar: Calendar

    init(prefix: String = "PhotoSort", calendar: Calendar = .current) {
        self.prefix = prefix
        self.calendar = calendar
    }

    func finalName(for key: AlbumName, period: DateInterval) -> String {
        var parts = [prefix]
        if let colors = key.colors, !colors.isEmpty {
            let colorNames = colors.map(\.displayName).sorted()
            parts.append(colorNames.joined(separator: ", "))
        }
        if let subjects = key.subjects, !subjects.isEmpty {
            let subjectNames = subjects.map { subjectName(for: $0) }.sorted()
            parts.append(subjectNames.joined(separator: ", "))
        }
        parts.append(periodName(for: period))
        return parts.joined(separator: " | ")
    }

    private func subjectName(for subject: Subject) -> String {
        if subject == .cats { return "Cats" }
        if subject == .dogs { return "Dogs" }
        return subject.label.capitalized
    }

    private func periodName(for period: DateInterval) -> String {
        let start = calendar.dateComponents(
            [.year, .month, .day],
            from: period.start
        )
        let end = calendar.dateComponents(
            [.year, .month, .day],
            from: period.end
        )
        if isFullYear(start: start, end: end) {
            return String(start.year!)
        }
        return "\(formattedDate(start)) – \(formattedDate(end))"
    }

    private func isFullYear(
        start: DateComponents,
        end: DateComponents
    ) -> Bool {
        start.year == end.year && start.month == 1 && start.day == 1
            && end.month == 12 && end.day == 31
    }

    private func formattedDate(_ components: DateComponents) -> String {
        String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}

extension NamedColor {
    var displayName: String {
        let characters = Array(rawValue)
        var result = ""

        for (index, character) in characters.enumerated() {
            if character.isUppercase, index > 0 {
                result.append(" ")
            }
            result.append(character)
        }
        guard let first = result.first else {
            return result
        }

        return first.uppercased() + result.dropFirst()
    }
}
