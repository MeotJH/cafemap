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
- `firebase deploy --only hosting`
