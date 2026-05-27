# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ICantCook is a full-stack recipe management application with a Flutter mobile frontend and Django REST API backend. The app enables users to create, share, and discover recipes with AI-powered assistance, nutrition tracking, and social features.

## Development Commands

### Backend (Django API)
```bash
# Navigate to API directory
cd api

# Install dependencies
pip install -r requirements.txt

# Run development server
python manage.py runserver

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Populate sample data
python manage.py shell -c "exec(open('populate_recipes.py').read())"

# Calculate nutrition data
python manage.py calculate_recipe_nutrition
python manage.py populate_nutrition_data
```

### Frontend (Flutter Mobile)
```bash
# Navigate to mobile directory
cd mobile

# Install dependencies
flutter pub get

# Generate code (for Freezed models)
flutter pub run build_runner build

# Run on iOS simulator
flutter run -d "iPhone 15 Pro"

# Run on Android emulator
flutter run -d android

# Build for production
flutter build ios
flutter build android
```

## Architecture Overview

### Backend (Django)
- **Django REST Framework** with token authentication
- **Modular app structure**: `recipes`, `ai_chatbot`, `social`, `accounts`, `recommendations`
- **PostgreSQL** database with Google Cloud Storage for media files
- **OpenAI API** integration for AI-powered recipe assistance
- **USDA API** for nutrition data
- **Celery** for background tasks (nutrition calculations)

### Frontend (Flutter)
- **Provider pattern** for state management with 9 specialized providers
- **Freezed** for immutable data models with JSON serialization
- **Material Design 3** theming with light/dark mode support
- **Google Fonts (Nunito)** typography throughout the app
- **Tab-based navigation** with 4 main sections: Recipes, AI Chat, Explore, Social

## Key Components

### State Management (Provider Pattern)
All state is managed through Provider with these specialized providers:
- `ThemeProvider` - Light/dark theme with SharedPreferences persistence
- `AuthProvider` - Authentication state and token management
- `UserRecipesProvider` - Personal recipe management with search/filtering
- `RecipeDetailProvider` - Individual recipe state and interactions
- `ExploreProvider` - Recipe discovery with advanced filtering
- `SocialProvider` - Social features and user interactions
- `ChatProvider` - AI chatbot conversations
- `UserProfileProvider` - User profile and social stats
- `SettingsProvider` - App settings and preferences

### API Communication
- **Centralized HTTP client** in `api/api_helper.dart`
- **Automatic token injection** for authenticated requests
- **Environment-aware URLs** (development vs production)
- **Error handling** with consistent status code responses
- **File upload support** for recipe images
- **Streaming responses** for AI chatbot interactions

### UI Architecture
- **Dashboard-based navigation** with bottom tab bar
- **Consistent AppBar styling** across all pages:
  - Transparent background with `surfaceTintColor: Colors.transparent`
  - Primary color icons with 32px size
  - GoogleFonts.nunito titles with `fontWeight: FontWeight.w900`
  - Centered titles with proper padding
- **Toast notification system** with enum-based types (info, warning, success, error)
- **Material Design 3** with extended ColorScheme for semantic colors

### Data Models
All models use Freezed with these patterns:
- **Immutable data classes** with `@freezed` annotation
- **JSON serialization** with `@JsonSerializable()`
- **Union types** for different states (e.g., `RecipeViewMode`)
- **Rich domain models** with computed properties and validation

## Development Guidelines

### Flutter Specific
- Use `Consumer<T>` widgets for reactive UI updates
- Implement debouncing for search inputs (500ms standard)
- Follow Material Design 3 theming conventions
- Use mixins for cross-cutting concerns (search, pagination, etc.)
- Generate code after model changes: `flutter pub run build_runner build`

### AppBar Styling Standard
All pages should use this consistent AppBar structure:
```dart
appBar: AppBar(
  backgroundColor: Colors.transparent,
  surfaceTintColor: Colors.transparent,
  automaticallyImplyLeading: false,
  centerTitle: true,
  leading: IconButton(
    padding: const EdgeInsets.only(left: 16.0),
    onPressed: () => Navigator.pop(context),
    icon: Icon(
      Icons.chevron_left,
      color: Theme.of(context).colorScheme.primary,
      size: 32,
    ),
  ),
  title: Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Text(
      'Page Title',
      style: GoogleFonts.nunito(
        fontWeight: FontWeight.w900,
        fontSize: 28,
        letterSpacing: -0.5,
      ),
    ),
  ),
),
```

### Toast Notifications
Use the enhanced InformationToast with semantic types:
```dart
InformationToast.show(
  context: context,
  message: "Operation completed!",
  type: ToastType.success, // info, warning, success, error
);
```

### Django Backend
- **Token authentication** required for most endpoints
- **Nutrition data** automatically calculated for recipes
- **AI integration** through OpenAI API for recipe assistance
- **Image uploads** handled through Google Cloud Storage
- **Search functionality** implemented with custom search mixins

## Environment Variables

### Backend (.env)
- `DJANGO_SECRET_KEY` - Django secret key
- `DATABASE_URL` - PostgreSQL connection string
- `OPENAI_API_KEY` - OpenAI API key for AI features
- `USDA_API_KEY` - USDA nutrition data API key
- `GOOGLE_APPLICATION_CREDENTIALS_JSON` - Google Cloud Storage credentials

### Frontend
- Development API: `http://10.0.2.2:8000` (Android emulator)
- Production API: `https://i-cant-cook-1500fc1d933c.herokuapp.com`

## Testing

### Backend
```bash
cd api
python manage.py test
```

### Frontend
```bash
cd mobile
flutter test
```

## Deployment

### Backend (Heroku)
- Configured with `Procfile` for Heroku deployment
- Uses PostgreSQL add-on and Google Cloud Storage
- Environment variables configured in Heroku dashboard

### Frontend
- iOS: Build through Xcode after `flutter build ios`
- Android: Generate APK with `flutter build apk`

## Key Files to Understand

- `mobile/lib/main.dart` - App entry point with provider setup
- `mobile/lib/routes.dart` - Navigation routing configuration
- `mobile/lib/theme/theme.dart` - Material Design 3 theme configuration
- `mobile/lib/api/api_helper.dart` - Centralized HTTP client
- `api/api/settings.py` - Django configuration and environment setup
- `api/recipes/models.py` - Core recipe and nutrition data models