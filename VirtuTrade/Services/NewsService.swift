//
//  NewsService.swift
//  VirtuTrade
//
//  Created by Codex on 3/3/26.
//

import Foundation

@MainActor
final class NewsService: ObservableObject {
    @Published private(set) var articles: [NewsArticle] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    private let session: URLSession
    private var hasLoaded: Bool = false
    private let endpoint = URL(string: "https://min-api.cryptocompare.com/data/v2/news/?lang=EN")!
    private let preferredSources = [
        "coindesk",
        "decrypt",
        "cointelegraph",
        "the block",
        "bitcoin magazine",
        "cryptoslate"
    ]
    private let minimumPreferredSourceArticles = 10
    private let fallbackMaxPerSource = 3
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    var latestArticle: NewsArticle? {
        articles.first
    }
    
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await fetchNews()
    }
    
    func refresh() async {
        await fetchNews()
    }
    
    private func fetchNews() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (data, response) = try await session.data(from: endpoint)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            let decodedResponse = try JSONDecoder().decode(CryptoCompareNewsResponse.self, from: data)
            let mappedArticles = decodedResponse.data
                .compactMap(\.asArticle)
                .sorted { $0.published_on > $1.published_on }
            let curatedArticles = curatedArticles(from: mappedArticles)
            
            articles = curatedArticles
            errorMessage = curatedArticles.isEmpty ? "No news available right now." : nil
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            if articles.isEmpty {
                errorMessage = "Failed to load news. Pull to refresh."
            }
        }
    }
    
    private func curatedArticles(from articles: [NewsArticle]) -> [NewsArticle] {
        let preferredArticles = articles.filter { isPreferredSource($0.source) }
        if preferredArticles.count >= minimumPreferredSourceArticles {
            return preferredArticles
        }
        return cappedBySource(articles, maxPerSource: fallbackMaxPerSource)
    }
    
    private func isPreferredSource(_ source: String) -> Bool {
        let normalizedSource = normalizedSourceName(source)
        return preferredSources.contains { normalizedSource.contains($0) }
    }
    
    private func cappedBySource(_ articles: [NewsArticle], maxPerSource: Int) -> [NewsArticle] {
        guard maxPerSource > 0 else { return articles }
        
        var sourceCounts: [String: Int] = [:]
        var capped: [NewsArticle] = []
        
        for article in articles {
            let sourceKey = normalizedSourceName(article.source)
            let currentCount = sourceCounts[sourceKey, default: 0]
            guard currentCount < maxPerSource else { continue }
            sourceCounts[sourceKey] = currentCount + 1
            capped.append(article)
        }
        
        return capped
    }
    
    private func normalizedSourceName(_ source: String) -> String {
        source
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

private struct CryptoCompareNewsResponse: Decodable {
    let data: [CryptoCompareNewsItem]
    
    enum CodingKeys: String, CodingKey {
        case data = "Data"
    }
}

private struct CryptoCompareNewsItem: Decodable {
    let idString: String?
    let idInt: Int?
    let title: String?
    let url: String?
    let imageurl: String?
    let source: String?
    let publishedOn: TimeInterval?
    let sourceInfo: SourceInfo?
    
    struct SourceInfo: Decodable {
        let name: String?
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case imageurl
        case source
        case publishedOn = "published_on"
        case sourceInfo = "source_info"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        idString = try? container.decode(String.self, forKey: .id)
        idInt = try? container.decode(Int.self, forKey: .id)
        title = try? container.decode(String.self, forKey: .title)
        url = try? container.decode(String.self, forKey: .url)
        imageurl = try? container.decode(String.self, forKey: .imageurl)
        source = try? container.decode(String.self, forKey: .source)
        publishedOn = try? container.decode(TimeInterval.self, forKey: .publishedOn)
        sourceInfo = try? container.decode(SourceInfo.self, forKey: .sourceInfo)
    }
    
    var asArticle: NewsArticle? {
        guard let rawTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines), !rawTitle.isEmpty,
              let rawURL = url?.trimmingCharacters(in: .whitespacesAndNewlines), !rawURL.isEmpty else {
            return nil
        }
        
        let resolvedID = idString
            ?? idInt.map(String.init)
            ?? rawURL
        
        let sourceName = sourceInfo?.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackSource = source?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedSource = sourceName.flatMap { $0.isEmpty ? nil : $0 }
            ?? fallbackSource.flatMap { $0.isEmpty ? nil : $0 }
            ?? "Unknown Source"
        
        return NewsArticle(
            id: resolvedID,
            title: rawTitle,
            url: rawURL,
            imageurl: imageurl ?? "",
            source: resolvedSource,
            published_on: publishedOn ?? 0
        )
    }
}
