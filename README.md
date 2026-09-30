# Eden mobile (`uko_eden`)

Flutter app for Android and iOS. It talks to the Eden API (`eden/back-end`, port 5005) through the API's **mobile entry**.

## How the app gets past the backend's checks

The backend normally accepts only browsers from `eden.uko-app.co.ke`. When a request has the header `x-eden-client: mobile`, the backend skips the User-Agent and Origin checks. Instead it:

- compares `x-api-key` with `mobile_api_key` in `eden/back-end/.env`. If `mobile_api_key` is not set, the mobile entry is closed;
- reads the session from `Authorization: Bearer <jwt>` rather than from a cookie. An expired or forged token gets a 401;
- returns `token` and `expires_in` in the body of `/signin` and `/person/signin/confirm`.

## Run

```
flutter run --dart-define-from-file=.env
```

`.env` sits next to `pubspec.yaml`. It is git-ignored.

| Key | Value |
|---|---|
| `EDEN_API` | Android emulator: `http://10.0.2.2:5005`. iOS simulator: `http://127.0.0.1:5005`. Real phone: the laptop's LAN IP. Production: `https://entry.uko-app.co.ke` |
| `EDEN_MOBILE_KEY` | Must equal `mobile_api_key` in the backend's `.env` |

Plain `http` is allowed only in Android debug builds, and on iOS only for local networking. Release builds use https.

## What's on the phone

| Tab | Who | What |
|---|---|---|
| Cinema | anyone | Now Screening, paged; film detail |
| Studios | anyone | Studios that have published something |
| Account | studio | Monetization rules, wallet, M-PESA withdraw (polls `/withdraw/:id`), history |
| Account | cast & crew | Sign in with an e-mailed code; profile, counts, studios |

These stay on the web dashboard for now: uploads, casting, editing cast and crew, mini-series.

## Layout

The layout follows the other UKO apps: `lib/main.dart`, then `lib/src/{app,api,config,models,session,theme}.dart` and `lib/src/screens/`. The app does not use `uko_core`, because that package is built for the FastAPI partner APIs and uses UKO navy. Eden has its own palette: earth, clay and sand, with Fraunces and Inter fonts.

## Still to do before a store release

- Release signing. Android currently signs with the debug key. iOS needs a team set in Xcode.
- Launcher icons made from `web-app/public/Eden-Logos/eden-appicon-*.png`.
- Studio sessions last 1 h, which is short for a phone. Add refresh or a longer mobile token.
- A public playback route, so viewers can watch films.
