# VirtuTrade - Feature Breakdown

## App Overview
**VirtuTrade** is a native iOS cryptocurrency tracking and virtual trading application built with SwiftUI. The app allows users to monitor real-time cryptocurrency prices and simulate trading without using real money, providing a risk-free environment for learning about crypto markets.

---

## Core Features

### 1. Real-Time Cryptocurrency Market Data
- **Live Price Tracking**: Displays real-time prices for 250+ cryptocurrencies from CoinGecko API
- **Market Statistics Dashboard**: Shows global market cap, 24-hour volume, and Bitcoin dominance
- **Price Change Indicators**: Visual indicators for 24-hour price changes with color-coded gains/losses
- **Market Cap Rankings**: Displays coins sorted by market capitalization
- **Pull-to-Refresh**: Manual data refresh functionality for up-to-date market information

### 2. Interactive Portfolio Management
- **Virtual Portfolio**: Create and manage a simulated cryptocurrency portfolio
- **Add/Edit Holdings**: Add coins to portfolio with custom quantities
- **Portfolio Value Calculation**: Real-time calculation of total portfolio value based on current prices
- **Portfolio Performance Tracking**: 24-hour portfolio value change percentage
- **Portfolio View Toggle**: Seamless switching between market view and portfolio view
- **Empty State Handling**: User-friendly empty state when portfolio is empty

### 3. Advanced Search & Filtering
- **Real-Time Search**: Debounced search functionality (0.5s delay) for instant filtering
- **Multi-Criteria Search**: Search by coin name, symbol, or ID
- **Search Integration**: Search works across both market and portfolio views

### 4. Sorting & Organization
- **Multiple Sort Options**: Sort by rank, holdings value, or price
- **Bidirectional Sorting**: Ascending and descending order for all sort options
- **Interactive Column Headers**: Tap-to-sort functionality with visual indicators
- **Context-Aware Sorting**: Different sort options for market vs. portfolio views

### 5. Detailed Coin Information
- **Comprehensive Coin Details**: View detailed information for each cryptocurrency
- **7-Day Price Charts**: Interactive sparkline charts showing 7-day price trends
- **Interactive Chart Interaction**: Drag gesture to view historical prices at specific points
- **Price Statistics**: Current price, market cap, rank, and 24-hour volume
- **Additional Metrics**: 24-hour high/low, price changes, block time, hashing algorithm
- **Coin Descriptions**: Detailed descriptions with expandable "View More" functionality
- **External Links**: Direct links to coin websites and Reddit communities

### 6. Data Persistence
- **Core Data Integration**: Persistent storage using Core Data for portfolio holdings
- **Local Image Caching**: Coin images cached locally to reduce network usage
- **Automatic Data Sync**: Portfolio data automatically synced with market data

### 7. User Interface & Experience
- **Modern SwiftUI Design**: Built entirely with SwiftUI for native iOS experience
- **Custom Theme System**: Comprehensive color theme with support for light/dark modes
- **Smooth Animations**: Transitions and animations for view changes
- **Haptic Feedback**: Tactile feedback for user interactions
- **Launch Screen**: Animated launch screen with loading text animation
- **Navigation Stack**: Modern navigation using NavigationStack
- **Sheet Presentations**: Modal presentations for portfolio editing and settings

### 8. Network & Data Management
- **RESTful API Integration**: Integration with CoinGecko API v3
- **Combine Framework**: Reactive programming with Combine for data streams
- **Error Handling**: Comprehensive error handling with retry logic (3 attempts)
- **Network Manager**: Centralized networking layer with URL validation
- **Data Services Architecture**: Separated service layer for coin data, market data, and portfolio data

### 9. Settings & Information
- **Settings View**: Accessible settings screen with app information
- **Developer Information**: Links to developer's LinkedIn and GitHub profiles
- **API Attribution**: Credit to CoinGecko API with external links
- **Version Information**: App version display

### 10. Performance Optimizations
- **Lazy Loading**: LazyHStack and LazyVGrid for efficient list rendering
- **Image Optimization**: Local file manager for image caching and storage
- **Debounced Search**: Prevents excessive API calls during search
- **Efficient Data Mapping**: Optimized data transformation pipelines

---

## Technical Architecture

### Design Patterns
- **MVVM Architecture**: Model-View-ViewModel pattern throughout the app
- **Singleton Pattern**: LocalFileManager and NetworkingManager as singletons
- **Publisher-Subscriber**: Combine framework for reactive data flow
- **Dependency Injection**: Environment objects for view models

### Key Technologies
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming framework
- **Core Data**: Persistent data storage
- **Charts Framework**: Native iOS Charts for price visualization
- **URLSession**: Network requests and data downloading
- **FileManager**: Local file system management

### Data Models
- **CoinModel**: Comprehensive cryptocurrency data model
- **CoinDetailModel**: Extended coin information model
- **MarketDataModel**: Global market statistics model
- **StatisticModel**: Reusable statistics display model
- **PortfolioEntity**: Core Data entity for portfolio storage

---

## API Integration

### CoinGecko API Endpoints
- **Markets Endpoint**: `/api/v3/coins/markets` - Fetches top 250 cryptocurrencies
- **Global Data Endpoint**: `/api/v3/global` - Fetches global market statistics
- **Coin Details Endpoint**: `/api/v3/coins/{id}` - Fetches detailed coin information

### Data Features
- Real-time price updates
- 7-day sparkline price data
- Market capitalization and volume data
- 24-hour price change percentages
- Coin descriptions and metadata
- External links (websites, Reddit, etc.)

---

## User Experience Highlights
- **Intuitive Navigation**: Easy switching between market and portfolio views
- **Visual Feedback**: Color-coded price changes (green for gains, red for losses)
- **Responsive Design**: Optimized for all iOS device sizes
- **Accessibility**: Clear typography and contrast for readability
- **Performance**: Smooth scrolling and fast data loading
- **Offline Capability**: Cached images and persisted portfolio data

---

## Development Features
- **Modular Architecture**: Separated concerns with dedicated services and view models
- **Reusable Components**: Custom SwiftUI components (StatisticView, CoinRowView, etc.)
- **Extension Utilities**: Helper extensions for formatting (currency, percentages, abbreviations)
- **Preview Support**: SwiftUI preview providers for development
- **Error Handling**: Comprehensive error handling throughout the app



