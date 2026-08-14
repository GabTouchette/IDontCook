# mobile

## API configuration

The app uses a compile-time API origin setting that defaults based on the platform and build mode.

### Local development (mobile)

- iOS simulator defaults to `http://127.0.0.1:8000`
- Android emulator defaults to `http://10.0.2.2:8000`
- Physical devices should pass an explicit backend URL:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.198:8000
```

### Web development

**Against production backend (Railway):**
```bash
flutter run -d chrome
```
The web app automatically points to `https://web-production-853e.up.railway.app`. The production backend is configured to allow CORS requests from `http://localhost:*` on any port.

**Against local development backend:**
```bash
# Terminal 1: Start Django dev server
cd api
python manage.py runserver

# Terminal 2: Run Flutter web
cd mobile
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

### Release builds

Release builds require an explicit backend URL and should point at the Railway deployment:

```bash
flutter build ios --release --dart-define=API_BASE_URL=https://web-production-853e.up.railway.app
```

The value should be the backend origin without `/api`. The app appends `/api` internally.
