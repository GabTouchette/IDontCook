# mobile

## API configuration

The app now uses a single compile-time API origin setting.

### Local development

- iOS simulator and desktop default to `http://127.0.0.1:8000`
- Android emulator defaults to `http://10.0.2.2:8000`
- Physical devices should pass an explicit backend URL:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.198:8000
```

### Release builds

Release builds require an explicit backend URL and should point at the Railway deployment:

```bash
flutter build ios --release --dart-define=API_BASE_URL=https://your-railway-api-domain
```

The value should be the backend origin without `/api`. The app appends `/api` internally.
