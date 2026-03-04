# VirtuTrade

Real market prices. Simulated trades.

## App Preview

![VirtuTrade Preview](docs/screenshots/app-preview.png)
![Market View](docs/screenshots/home.png)
![Portfolio View](docs/screenshots/portfolio.png)
![Trade Flow](docs/screenshots/trade.png)

## About the App

VirtuTrade is a native iOS crypto trading simulator designed for realistic market practice without real-money risk. The app streams live market pricing and pairs it with a local simulation engine so users can learn trading behavior, portfolio dynamics, and execution discipline in a controlled environment.

Built as a product-first experience, VirtuTrade focuses on clarity, responsiveness, and confidence at every step of the journey, from onboarding and discovery to trade execution and portfolio tracking.

## Key Features

- Simulated buy/sell execution using virtual USD
- Live crypto market browsing with search and sorting views
- Portfolio tracking with holdings, value, and performance metrics
- Trade flows designed for speed, feedback, and usability
- Interactive market charts and value visualization
- Crypto news feed integrated into the app experience
- Trading profiles with configurable starting balances
- Persistent local state for portfolio, history, and preferences

## Design Philosophy

VirtuTrade is intentionally minimal and information-forward.

- Clear hierarchy: essential information is visible first, secondary context follows
- Responsive interactions: fast state updates and smooth transitions
- Practical realism: simulation behavior mirrors real decision pressure without financial exposure
- Polished states: loading, empty, and error states are handled with the same care as happy paths
- Visual consistency: cohesive spacing, typography, and controls across Home, Portfolio, Trade, and Settings

## Engineering Highlights

- SwiftUI-first architecture optimized for maintainable, state-driven UI
- Combine-powered reactive pipelines for synchronized market and portfolio updates
- Core Data-backed persistence for holdings and portfolio state durability
- URLSession networking with structured decoding, error propagation, and safe request handling
- CoinGecko-backed live market data integration
- Asynchronous data flow designed to keep UI updates smooth and predictable
- Local simulation engine for trade execution and account value updates
- Reliability-focused implementation with explicit UI states and defensive data handling

## Privacy

VirtuTrade is a simulated trading product.

- Trades are simulated locally using virtual USD
- No real cryptocurrency purchases, deposits, withdrawals, or custody
- No brokerage or exchange execution
- No personal financial account linking
- Uses public market/news data APIs for pricing and content

## App Store

[Download on the App Store](APP_STORE_LINK)

## Credits

- Market data powered by [CoinGecko](https://www.coingecko.com/)
