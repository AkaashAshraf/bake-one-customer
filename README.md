# Bake One — customer app

Flutter app for Bake One customers, with the same red & white look and
animations as the website.

**Without logging in:** home (banners, categories, bestsellers, our process,
FAQ), full product catalogue with search, categories and quick view,
About, and Contact (WhatsApp, call, email, directions).

**After logging in** (same email/password as the website's customer portal):
dashboard with outstanding balance and unpaid invoices, your own special
prices and savings on every product, invoices (with PDF sharing),
payments and the invoices each payment covered, profile and password change.

## First-time setup
```
bash setup.sh
flutter run
```
`setup.sh` generates the Android/iOS folders, sets the app name "Bake One"
and ID `com.bakeone.customer`, and creates the launcher icons.

## Server
Talks to `https://www.bake-one.com` by default (see `lib/core/config.dart`).
For your local server:
```
flutter run --dart-define=API_BASE_URL=http://<your-mac-ip>:8100
```
Uses the `/api/customer/*` endpoints in the Laravel project
(`app/Http/Controllers/Api/CustomerApp/CustomerAppController.php`).
# bake-one-customer
