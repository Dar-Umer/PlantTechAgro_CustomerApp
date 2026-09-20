# PTA Customer App (Flutter)

Customer mobile app for the PTA Laravel backend (`E:\Ai Apps\PTA\Laravel`).
Covers every endpoint in Laravel `routes/api.php` for customers.

## Design — "Orchard Modernist" (Stitch)

The UI implements the design system from the Stitch project
`14626018066789175812`, synced via `E:\Ai Apps\PTA\stitch-sync`
(`DESIGN.md`, 8 screens, HTML + screenshots) using the Stitch API:

- Emerald `#22c55e` primary actions, orchard-orange `#e65100` booking/pay
  CTAs, deep forest `#14532d` headings, light-only theme
- Inter throughout (via `google_fonts`), tabular figures for ₹ amounts
- 16px cards with 1px `#e5e7eb` borders, 12px controls, spec-mapped
  status chips (Paid/Completed, In Progress, Overdue, Assigned, Pending)
- Branded splash/login ("Strong Horticulture. Stronger Kashmir."), welcome
  banner, 2×2 stat cards with icon badges, stage timeline with photo grids

Theme lives in `lib/theme/orchard_theme.dart`; brand widgets
(PlantTech Agro wordmark, gradient, yield pill) in `lib/widgets/brand.dart`.

## Features

- **Auth** — phone + password login (Sanctum token, persisted), logout,
  forgot-password via OTP (`/auth/forgot` → `/auth/verify-otp` → `/auth/reset-password`)
- **Dashboard** — order/invoice stats, outstanding & overdue balances,
  recent orders & invoices, farm weather, support card
- **Services** — browse active services, book a service with optional notes
  (duplicate active bookings are rejected by the backend with a friendly message)
- **Work orders** — filter by status, infinite scroll, detail with stage
  timeline, materials, photo/document attachments (open externally)
- **Invoices** — filter by status, infinite scroll, detail with items,
  payments, totals, overdue flag
- **Products** — sellable catalog with search + pagination, stock badges
- **Notifications** — list, mark one / mark all as read, unread badge
- **Profile** — view/edit name, email, area, address; change password

## Backend base URL

Default (no flags needed):

| Platform | Default |
|---|---|
| Android emulator | `http://10.0.2.2:8000/api` |
| Desktop / web / iOS sim | `http://localhost:8000/api` |

Override with:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

For a physical Android device, use your PC's LAN IP and make sure
`php artisan serve --host=0.0.0.0 --port=8000` is running. The dev API
(`API_ECHO_OTP=false` in `.env`) hides OTPs; on `local` env with echo
enabled the app surfaces the debug OTP in a snackbar.

## Run

```powershell
cd "E:\Ai Apps\PTA\CustomerApp"
flutter pub get
flutter run
```

Backend must be up with MySQL (`planttech` DB) migrated:

```powershell
cd "E:\Ai Apps\PTA\Laravel"
php artisan serve --host=127.0.0.1 --port=8000
```

## Test / analyze

```powershell
flutter test
flutter analyze
```

## Structure

```
lib/
  main.dart                # providers + MaterialApp + 401 → Login hook
  core/
    config.dart            # base-URL resolution + media URLs
    api_client.dart        # bearer-token HTTP wrapper, SessionStore,
                           # 429 friendly copy, 401 onUnauthorized hook
  models/models.dart       # all JSON models (user, orders, invoices, …)
                           # + company/mobile gating + compareVersions
  services/customer_api.dart  # 1:1 mapping of routes/api.php
  state/app_state.dart     # ChangeNotifiers (auth, dashboard, catalog, …)
  theme/orchard_theme.dart # Orchard Modernist tokens + ThemeData
  screens/
    splash_screen.dart     # brand + update/maintenance gates
    gate_screens.dart      # UpdateRequired, Maintenance, Support, About
    login_screen.dart forgot_password_screen.dart (6-box OTP)
    home_screen.dart       # 4-tab shell (Home, Services, Orders, More)
    service_detail_screen.dart  # detail → confirm → booking success
    notifications_screen.dart
    order_detail_screen.dart invoice_detail_screen.dart
    tabs/ (dashboard, services, orders, invoices list, more hub)
  widgets/
    common.dart            # chips, loading/error/empty, money/date/relative
    brand.dart             # wordmark, gradient, yield pill
```

Implements the Stitch `screen-8132350114314183853` UI/UX spec
(`stitch-sync/export/14626018066789175812/`): 4-tab nav, stack screens,
gating, booking flow, status mapping, empty-state copy, 401/429 handling.
