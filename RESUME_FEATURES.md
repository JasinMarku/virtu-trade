# VirtuTrade - Resume Feature List

## Project Description
Native iOS cryptocurrency tracking and virtual trading application built with SwiftUI, enabling users to monitor real-time crypto prices and simulate trading without financial risk.

---

## Key Features

### Market Data & Tracking
• Real-time cryptocurrency price tracking for 250+ coins via CoinGecko API integration
• Global market statistics dashboard displaying market cap, 24h volume, and Bitcoin dominance
• Interactive 7-day price charts with drag gesture for historical price exploration
• Color-coded price change indicators (green/red) for 24-hour gains and losses
• Market cap rankings with sortable columns for rank, price, and holdings

### Portfolio Management
• Virtual portfolio system for risk-free cryptocurrency trading simulation
• Add, edit, and remove coin holdings with real-time value calculations
• Portfolio performance tracking with 24-hour value change percentage
• Seamless toggle between market view and portfolio view
• Empty state handling for improved user experience

### Search & Organization
• Real-time debounced search (0.5s) filtering by coin name, symbol, or ID
• Multi-criteria sorting (rank, price, holdings) with bidirectional toggle
• Interactive column headers with visual sort indicators
• Context-aware sorting for market vs. portfolio views

### Detailed Coin Information
• Comprehensive coin detail screens with overview and additional statistics
• 7-day interactive sparkline charts with price point selection
• Detailed metrics: market cap, volume, 24h high/low, block time, hashing algorithm
• Expandable coin descriptions with external links to websites and Reddit communities
• Real-time price updates with formatted currency display

### Data Persistence & Caching
• Core Data integration for persistent portfolio storage
• Local image caching system to reduce network usage and improve performance
• Automatic synchronization between portfolio and market data

### User Interface & Experience
• Modern SwiftUI design with custom theme system supporting light/dark modes
• Smooth animations and transitions for view changes
• Haptic feedback for enhanced user interactions
• Animated launch screen with loading text animation
• Pull-to-refresh functionality for manual data updates
• Sheet presentations for portfolio editing and settings

### Technical Implementation
• MVVM architecture with separated service layer
• Combine framework for reactive data streams and publisher-subscriber pattern
• RESTful API integration with comprehensive error handling and retry logic (3 attempts)
• Centralized networking layer with URL validation
• Lazy loading for efficient list rendering (LazyHStack, LazyVGrid)
• Singleton pattern for file and network managers

### Additional Features
• Settings screen with developer information and API attribution
• External links to developer profiles (LinkedIn, GitHub) and CoinGecko
• Version information display
• Reusable UI components (StatisticView, CoinRowView, SearchBarView, etc.)
• Helper extensions for currency formatting, percentage display, and number abbreviations

---

## Technical Stack
**Languages & Frameworks:** Swift, SwiftUI, Combine, Core Data
**APIs:** CoinGecko API v3 (REST)
**Architecture:** MVVM (Model-View-ViewModel)
**Design Patterns:** Singleton, Publisher-Subscriber, Dependency Injection
**iOS Features:** Charts Framework, URLSession, FileManager, Haptic Feedback

---

## API Endpoints Used
• `/api/v3/coins/markets` - Market data for top 250 cryptocurrencies
• `/api/v3/global` - Global market statistics
• `/api/v3/coins/{id}` - Detailed coin information

---

## Performance Optimizations
• Debounced search to prevent excessive API calls
• Local image caching to reduce network requests
• Lazy loading for efficient memory usage
• Optimized data transformation pipelines
• Efficient Core Data queries



