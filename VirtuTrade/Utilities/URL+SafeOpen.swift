//
//  URL+SafeOpen.swift
//  VirtuTrade
//
//  Created by Codex on 3/4/26.
//

import Foundation

extension URL {
    static func safeHTTPURL(from string: String?) -> URL? {
        guard let string else { return nil }

        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else {
            return nil
        }

        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return nil
        }

        return url
    }
}
