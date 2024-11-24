//
//  String.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 11/23/24.
//

import Foundation

extension String {
    
    var removingHTMLOccurances: String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}
