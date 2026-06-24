# SplitSmart 💸

A mobile-first group expense splitting app built for Indian college students — roommates splitting rent, friends settling a trip, or a group splitting monthly Swiggy orders.

SplitSmart automatically tracks who paid what, calculates running balances across all expenses, and lets anyone settle their dues in one tap via a UPI deep-link that opens any UPI app (GPay, PhonePe, Paytm, BHIM) pre-filled with the amount and note.

---

## The Core: Debt Simplification Engine

The main technical feature is a **greedy graph algorithm** (`core/debt_engine/debt_simplifier.dart`) that takes N pairwise debts and reduces them to the minimum number of transactions needed to settle the group — using a max-heap on net balances.

> **Example**: 6 raw debts → 3 optimised settlements (50% reduction)

---

## Features

- 🏠 **Group Management** — Create groups, share a 6-char invite code, join by entering the code
- ➕ **Add Expenses** — Category-tagged, custom numpad, split equally among all members
- 🧠 **Debt Simplification** — Live "Before → After" view showing raw vs optimised settlements
- 💸 **UPI Settlement** — Deep-link opens GPay / PhonePe / Paytm / BHIM pre-filled
- 📋 **History** — Full searchable + category-filtered expense log across all groups
- 📄 **Export** — PDF ledger or CSV of all expenses, shared via native share sheet
- 🔒 **Fully Offline** — All data stored locally in JSON, no internet required

---

## Tech Stack

| Package | Purpose |
|---|---|
| `flutter` | UI framework |
| `provider` ^6.1.5 | State management |
| `path_provider` ^2.1.6 | Local file storage |
| `uuid` ^4.5.3 | Unique ID generation |
| `url_launcher` ^6.3.2 | UPI deep-link intent |
| `pdf` ^3.13.0 | PDF ledger generation |
| `share_plus` ^10.1.4 | Native share sheet for export |

---

## App Structure

```
lib/
├── auth/             → Local auth (single-user, offline)
├── home/             → Groups list, splits, history, settings tabs
├── group/
│   ├── detail/       → Group tabs: Expenses / Balances / History
│   ├── expense/      → Add Expense screen with numpad
│   └── balances/     → SettleUp: debt simplification + UPI + export
│   └── history/      → Searchable filterable expense log
└── core/
    ├── models/       → Group, Expense, Settlement, AppUser
    ├── debt_engine/  → DebtSimplifier (greedy max-heap algorithm)
    ├── export/       → PDF + CSV export service
    ├── services/     → LocalStorageService, LocalAuthService
    ├── upi/          → UPI URI builder + url_launcher intent
    ├── theme/        → NeonTheme (dark glassmorphism design system)
    └── widgets/      → GlassCard, NeonButton
```

---

## Debt Simplification Algorithm

```
Input:  List<Expense> for a group
Output: List<Settlement> — minimum transactions to zero all balances

1. For each member: net = total_paid - total_owed
2. Separate into creditors (net > 0) and debtors (net < 0)
3. Sort both lists by absolute value descending (simulate max-heap)
4. While both lists non-empty:
     C = creditors.pop(), D = debtors.pop()
     settle = min(C.balance, |D.balance|)
     emit: D pays C → ₹settle
     re-push remainders if non-zero
5. Result: at most (N-1) transactions for N members
```

---

## UPI Deep-Link Format

```
upi://pay?pa={upi_id}&pn={name}&am={amount}&cu=INR&tn=SplitSmart | {group}
```

> ⚠️ UPI deep-links only work on physical Android/iOS devices — not on emulators.

---

## Demo Data

On first launch, the app seeds two demo groups:

| Group | Members | Expenses |
|---|---|---|
| Goa Trip 🏖️ | You, Rahul, Priya, Amit | Hotel, Scooter, Dinner, Water sports, Breakfast |
| BHK Flat 🏠 | You, Rahul, Priya | June Rent, Electricity, Swiggy |

---

## Running Locally

```bash
flutter pub get
flutter run
```

> All data is stored in `getApplicationDocumentsDirectory()/splitsmart_data.json` on the device.
