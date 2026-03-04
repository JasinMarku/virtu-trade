//
//  NewsView.swift
//  VirtuTrade
//
//  Created by Codex on 3/3/26.
//

import SwiftUI
import SafariServices

struct NewsView: View {
    @EnvironmentObject private var newsService: NewsService
    @State private var selectedArticle: NewsArticle?
    
    var body: some View {
        List {
            if newsService.isLoading && newsService.articles.isEmpty {
                ProgressView("Loading crypto news...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.theme.background)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 30)
            }
            
            if let errorMessage = newsService.errorMessage,
               newsService.articles.isEmpty {
                VStack(spacing: 12) {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.secondaryText)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        Task {
                            await newsService.refresh()
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.theme.accent)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.theme.background)
                .listRowSeparator(.hidden)
                .padding(.vertical, 30)
            }
            
            ForEach(newsService.articles) { article in
                Button {
                    selectedArticle = article
                } label: {
                    NewsArticleRow(article: article)
                }
                .buttonStyle(.plain)
                .listRowInsets(.init(top: 12, leading: 0, bottom: 12, trailing: 0))
                .listRowBackground(Color.theme.background)
                .listRowSeparator(.hidden)
            }
        }
        .padding()
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .background(Color.theme.background)
        .navigationTitle("Crypto News")
        .task {
            await newsService.loadIfNeeded()
        }
        .refreshable {
            await newsService.refresh()
        }
        .sheet(item: $selectedArticle) { article in
            Group {
                if let articleURL = URL.safeHTTPURL(from: article.url) {
                    SafariView(url: articleURL)
                        .ignoresSafeArea()
                } else {
                    Text("Unable to open article.")
                        .padding()
                }
            }
        }
    }
}

private struct NewsArticleRow: View {
    let article: NewsArticle
    
    private var relativeTimeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: article.publishedDate, relativeTo: Date())
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: article.imageurl)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.theme.accentBackground)
            }
            .frame(width: 84, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .foregroundStyle(Color.primary)
                
                HStack(spacing: 8) {
                    Text(article.source)
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                        .lineLimit(1)
                    
                    Circle()
                        .fill(Color.theme.secondaryText.opacity(0.6))
                        .frame(width: 3, height: 3)
                    
                    Text(relativeTimeText)
                        .font(.caption)
                        .foregroundStyle(Color.theme.secondaryText)
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 0)
        }
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        NewsView()
    }
    .environmentObject(NewsService())
}
