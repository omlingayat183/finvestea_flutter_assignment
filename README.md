# 📊 Finvestea Portfolio Analysis App

A Flutter-based investment portfolio analysis application built as part of the **Akeshya Pvt Ltd Flutter Developer Assignment**.

This app allows users to authenticate, upload their investment portfolio (CSV/XLSX), and visualize insights through dynamic charts and analytics.

---

## 🚀 Features

### 🔐 Authentication

* User Registration (Sign Up)
* User Login (Email/Password & Phone OTP)
* Persistent Session Management
* Logout functionality

### 📂 Portfolio Upload

* Upload portfolio via:

  * CSV files
  * Excel (.xlsx) files
* File parsing and validation
* Error handling for invalid formats

### 📊 Dynamic Data Visualization

* Pie Chart → Asset Allocation
* Bar Chart → Returns / Performance
* Interactive charts using `fl_chart`

### 📈 Portfolio Analysis

* Total Investment Value
* Current Portfolio Value
* Profit / Loss Calculation
* CAGR (Compound Annual Growth Rate)
* Risk Profile (Aggressive / Moderate / Conservative)
* Asset Allocation Breakdown

### 🤖 Insights

* Strengths and Weaknesses of portfolio
* Rule-based analysis for better understanding

---

## 🛠 Tech Stack

* **Flutter** – Frontend framework
* **Firebase** – Authentication & backend
* **Cloud Firestore** – User data storage
* **fl_chart** – Charts & visualization
* **file_picker** – File selection
* **excel / csv** – File parsing

---

## 📂 Project Structure

```
lib/
 ├── core/
 │   ├── models/
 │   ├── services/
 │   └── theme/
 │
 ├── features/
 │   ├── auth/
 │   ├── dashboard/
 │   ├── portfolio/
 │   └── onboarding/
 │
 ├── firebase_options.dart
 └── main.dart
```

---

## ⚙️ Setup Instructions

### 1. Clone the repository

```
git clone https://github.com/your-username/finvestea_flutter_assignment.git
cd finvestea_flutter_assignment
```

### 2. Install dependencies

```
flutter pub get
```

### 3. Firebase Setup

* Create a Firebase project
* Add Android app (`com.example.finvestea_app`)
* Download `google-services.json`
* Place it in:

```
android/app/google-services.json
```

* Enable:

  * Email/Password Authentication
  * Phone Authentication

### 4. Run the app

```
flutter run
```

---

## 📊 Portfolio Upload Format

The uploaded CSV/XLSX file should contain the following columns:

* Investment Name
* Type (Equity, Debt, FD, etc.)
* Amount Invested
* Current Value
* Units (optional)
* Date (optional)
* Returns (optional)

---

## 🧠 Assumptions

* Portfolio file follows a structured format
* Risk profile is calculated based on asset allocation
* CAGR is calculated using earliest investment date
* Missing values are handled with default logic

---

## ⚠️ Limitations

* No real-time stock market API integration
* Basic rule-based insights (not AI-driven)
* Limited validation for custom file formats

---


## 🎥 Demo Video (Optional)

*https://drive.google.com/drive/folders/1HzOOWG2V___afZ98WrZxGcxK4sVoR5OT?usp=sharing*

---

## 📌 Notes

This project was developed as part of a technical assignment for **Akeshya Pvt Ltd**.

Focus areas:

* Clean architecture
* Real-world data handling
* UI consistency
* Error handling

---

## 👨‍💻 Author

**Om Lingayat**
Flutter Developer

---


# Finvestea

A full-featured personal finance and investment management app built with Flutter. Finvestea covers the entire investor journey — from KYC onboarding and portfolio tracking to mutual fund investments, financial calculators, loan discovery, and investment education.

---

## Features

### Onboarding & KYC
Complete step-by-step account setup:
- Phone + OTP login
- Basic personal information collection
- PAN verification
- CKYC lookup
- Aadhaar KYC
- Address confirmation
- Bank account linking
- Account activation

### Dashboard
Central hub showing:
- Live portfolio value card with total returns
- Investment category quick-access tiles
- Recent market insights and news feed

### Portfolio Management
- **Portfolio Import** — upload CSV or Excel (.xlsx/.xls) files to import holdings
- **Portfolio Reports** — single-page scrollable report with 5 anchored sections:
  - Overview (portfolio summary, growth chart)
  - Returns (return breakdown, top/under performers)
  - Investments (holdings list with return badges)
  - Allocation (pie chart by asset class)
  - AI Insights (rule-based performance, risk, diversification analysis and suggestions)
- **Recommended Portfolio** — curated portfolio suggestions based on profile

### Investment Marketplace
- Mutual fund browsing and search
- Fund details with historical performance charts
- One-tap investment order placement
- Payment gateway integration
- Order confirmation
- Transaction history

### Financial Calculators
- **SIP Calculator** — monthly investment goal planner
- **Lumpsum Calculator** — one-time investment projection
- **EMI Calculator** — loan EMI breakdown
- **Retirement Planner** — corpus accumulation estimator
- **Tax Saver Calculator** — 80C tax-saving instrument planner

### Academy
- Featured courses and learning paths
- Course list with progress tracking
- In-app video player
- Article reader for market insights

### Loans
- Personal Loan (up to ₹40 Lakhs, from 10.5% p.a.)
- Home Loan (up to ₹5 Crores, from 8.4% p.a.)
- Car Loan (up to ₹50 Lakhs, from 9.2% p.a.)
- Education Loan (up to ₹75 Lakhs, from 11.0% p.a.)
- Loan application flow with lender selection

### Profile & Account
- Personal info management
- Risk profiling questionnaire
- Nominee management (add/edit nominees)
- Goal creation and tracking
- App settings
- Help center

### Market & News
- Market overview (indices, top gainers/losers)
- News feed with live market updates
- Services hub

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Routing | go_router |
| Fonts | Google Fonts — Manrope |
| Icons | lucide_icons |
| Animations | animations, flutter_spinkit |
| Excel parsing | excel ^4.0.6 |
| UI | Custom glassmorphism design system |

---

## Architecture

```
lib/
├── main.dart
├── core/
│   ├── router.dart          # go_router route definitions
│   └── theme.dart           # AppTheme — colors, typography, dark theme
└── features/
    ├── onboarding/
    │   └── presentation/    # Splash, Welcome, Login, OTP, KYC screens
    ├── dashboard/
    │   ├── presentation/    # Dashboard, Portfolio, Marketplace, Goals, etc.
    │   └── services/
    │       ├── portfolio_document_parser.dart   # CSV/Excel → PortfolioInvestment
    │       ├── portfolio_analysis_service.dart  # Analytics computation
    │       └── portfolio_ai_insight_service.dart # Rule-based AI insights
    ├── calculators/
    │   └── presentation/    # SIP, Lumpsum, EMI, Retirement, Tax Saver
    ├── academy/
    │   └── presentation/    # Academy home, courses, video player, articles
    └── loans/
        └── presentation/    # Loans home, application, lender selection
```

---

## Design System

Finvestea uses a custom dark glassmorphism design system:

- **Primary color** — Emerald Green `#22C55E`
- **Accent color** — Gold `#D4AF37`
- **Background** — Deep navy gradient `#1B2233` → `#0F1115`
- **Surface** — Translucent glass cards `#1E2638` at 70% opacity
- **Typography** — Manrope (Google Fonts)
- **Components** — Glass cards, animated tab bars, custom painters for charts, gradient buttons

---

## Portfolio Analysis Services

### `PortfolioDocumentParser`
Parses uploaded investment files into structured `PortfolioInvestment` objects.
- Supports CSV (comma-separated, quoted fields)
- Supports Excel via the `excel` package (`parseExcelRows`)
- Includes a `getDemoPortfolio()` with 5 sample holdings from `finvestea_portfolio_sample.xlsx`

### `PortfolioAnalysisService`
Computes portfolio metrics from a list of investments:
- Total invested, current value, total returns, return %
- Asset allocation by category (sorted by value)
- Top performers and underperformers
- Indian number formatting (`formatIndianCurrency`) and compact notation (`formatCurrencyCompact`)

### `PortfolioAiInsightService`
Generates contextual insights (rule-based, with a Gamma API integration stub):
- Performance summary based on return %
- Risk profile assessment based on equity allocation
- Diversification analysis by asset class count
- Actionable suggestions (gold hedge, SIP setup, rebalancing, diversification)

---

## Getting Started

### Prerequisites
- Flutter SDK `^3.9.2`
- Dart SDK `^3.9.2`

### Install & Run

```bash
cd finvestea_app
flutter pub get
flutter run
```

### Build (Android)

```bash
flutter build apk --release
```

---

## Sample Portfolio Data

The file `finvestea_app/finvestea_portfolio_sample.xlsx` contains a demo portfolio used for testing the import and analysis features:

| Investment | Type | Invested | Current Value | Returns |
|---|---|---|---|---|
| Reliance Industries | Stock | ₹1,00,000 | ₹1,25,000 | ₹25,000 |
| TCS | Stock | ₹80,000 | ₹96,000 | ₹16,000 |
| HDFC Top 100 Fund | Mutual Fund | ₹1,20,000 | ₹1,38,000 | ₹18,000 |
| Gold ETF | ETF | ₹50,000 | ₹57,500 | ₹7,500 |
| SBI Bluechip Fund | Mutual Fund | ₹90,000 | ₹99,000 | ₹9,000 |

**Portfolio Summary:** Total Invested ₹4,40,000 | Current Value ₹5,15,500 | Returns ₹75,500 | Return 17.16%

---

## Dependencies

```yaml
dependencies:
  flutter_spinkit: ^5.2.2
  google_fonts: ^8.0.2
  lucide_icons: ^0.257.0
  go_router: ^17.1.0
  animations: ^2.1.1
  excel: ^4.0.6
  cupertino_icons: ^1.0.8
```
