# 💳 Millennia Debit Card Cashback Tracker

A simple Flutter app to manually track spending and estimate cashback across different categories — designed specifically around the HDFC Millennia Debit Card.

> ⚠️ This app is for **personal use only**. It does **not connect to any bank**, handle **financial data**, or provide **financial advice**. All data is stored locally.

---

## ✨ Features

- Manually add transaction details:
  - Amount
  - Category (Online Shopping / Bill Payment / Other)
  - Date
- Auto-calculate estimated cashback per entry
- View monthly totals for:
  - Spend per category
  - Cashback earned per category
- Clean and intuitive UI (dashboard, category view)
- Local data persistence using Hive or SQLite
- Optional summary charts (pie/bar)

---

## 💰 Cashback Categories

Estimated cashback rates based on real user experience:

| Category           | Cashback Rate |
|--------------------|----------------|
| 🛍️ Online Shopping  | **5%**         |
| 💡 Bill Payments     | **2.5%**       |
| 🏪 Other Spends      | **1%**         |

> Rates are based on personal usage and may not reflect actual bank offers.

---

## 🧱 Tech Stack

- **Flutter** – Cross-platform app framework
- **Hive / SQLite** – Lightweight local database
- **Provider / Bloc** – State management (optional)
- **Flutter Charts** – For visual summaries (optional)

---

## 🚫 Disclaimer

This is a **personal-use** project.  
It does **not connect to any bank accounts**, does **not require login**, and does **not collect or store any sensitive financial information**.

You are responsible for verifying your actual cashback with your bank/card provider.

---

## 🚀 Getting Started

1. Clone the repo:
```bash
git clone https://github.com/SujalPatel17/millennia_cashback_tracker.git
cd millennia_cashback_tracker
