# VirtuTrade

Real market prices. Simulated trades.

## App Preview
![EA513120-8FBD-474C-ADD8-E1B919D0712D_1_102_a](https://github.com/user-attachments/assets/2e538bbf-cbd6-4a8e-b488-6d1cfd93f91e)

## 🎥 Demo


https://github.com/user-attachments/assets/32927b3f-cef3-4680-83c2-2bca65c29a42



## About the App

VirtuTrade is a native iOS crypto trading simulator designed for realistic market practice without real-money risk. The app streams live market pricing and pairs it with a local simulation engine so users can learn trading behavior, portfolio dynamics, and execution discipline in a controlled environment.

The goal was to build a fast, clean, and reliable trading experience that feels real without involving actual financial risk.

## Key Features

- Simulated buy and sell execution using virtual USD
- Live crypto market browsing with search and sorting
- Portfolio tracking with holdings, value, and performance metrics
- Fast, responsive trade flows with clear feedback
- Interactive charts and market visualization
- Trading profiles with configurable starting balances
- Persistent local state for portfolio, trade history, and preferences

## Architecture Overview

- Built using SwiftUI with an MVVM architecture
- Combine pipelines used for reactive data flow and UI updates
- Market data fetched from the CoinGecko API using URLSession
- Core Data used for local persistence of portfolio and trade history
- Local simulation engine handles trade execution and account value updates
- Structured loading, error, and retry states for reliability

## Engineering Highlights

- State-driven UI for predictable and maintainable updates
- Asynchronous networking with structured decoding
- Clear separation between UI, business logic, and persistence
- Defensive data handling to prevent crashes and inconsistent balances
- Local-first simulation design with no backend dependency

## Design Philosophy

VirtuTrade is intentionally minimal and information-first.

- Clear hierarchy: important information appears first
- Fast interactions: low-friction flows with immediate feedback
- Realistic simulation: designed to mirror trading decision pressure without financial exposure
- Polished states: loading, empty, and error states handled intentionally
- Consistent UI: spacing, typography, and controls remain cohesive across the app

## Privacy

VirtuTrade is a fully simulated trading environment.

- No real cryptocurrency transactions
- No deposits, withdrawals, or wallet connections
- No brokerage or exchange integration
- No personal financial account linking
- Uses public APIs for market and content data only
  
## Status

App Store submission in progress.

## Credits

- Market data powered by [CoinGecko](https://www.coingecko.com/)
