//
//  NewsArticle.swift
//  VirtuTrade
//
//  Created by Codex on 3/3/26.
//

import Foundation

struct NewsArticle: Identifiable, Hashable {
    let id: String
    let title: String
    let url: String
    let imageurl: String
    let source: String
    let published_on: TimeInterval
    
    var publishedDate: Date {
        Date(timeIntervalSince1970: published_on)
    }
}
