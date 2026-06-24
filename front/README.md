# front

## Web Deploy (Firebase Hosting)

1. `firebase login`
2. Set Firebase project id in `.firebaserc`
3. Create `.env.production` from `.env.production.example`
   - Set `GA4_MEASUREMENT_ID=G-XXXXXXXXXX` if you want web analytics
4. Run:
   - `./scripts/deploy_web.sh`

`deploy_web.sh` does:
- copy `.env.production` -> `.env`
- `flutter build web --release`
- deploy only the `cafebubu` Firebase Hosting target by default

## Web Video Build Notes

- Keep both `video_player` and the direct `video_player_web` dependency in `pubspec.yaml`.
- After dependency or Flutter upgrades, run a clean build:
  - `flutter clean`
  - `flutter pub get`
  - `flutter build web --release --pwa-strategy=none`
- Confirm the generated web plugin registrant contains:
  - `VideoPlayerPlugin.registerWith(registrar)`
- If it is missing, web playback fails with `UnimplementedError: init() has not been implemented`.
- iPhone Chrome uses WebKit, like Safari. Keep gallery autoplay muted by calling `setVolume(0)` before `play()`.
- Video `mediaItems[].url` must be a direct presigned S3 GET URL. Do not route video playback through a backend redirect or FastAPI byte streaming; iPhone playback can fail or turn black.
- Verify production playback on both desktop Chrome and a real iPhone Chrome/Safari after media or deployment changes.
