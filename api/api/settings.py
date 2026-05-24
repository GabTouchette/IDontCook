"""Django settings for the IDontCook API."""

import json
import logging
import os
from datetime import timedelta
from pathlib import Path

import dj_database_url
import environ
from django.core.exceptions import ImproperlyConfigured
from dotenv import load_dotenv
from google.oauth2.service_account import Credentials

BASE_DIR = Path(__file__).resolve().parent.parent
env = environ.Env()
load_dotenv(BASE_DIR / ".env")

LOGGER = logging.getLogger(__name__)
ENVIRONMENT = env("ENVIRONMENT", default="development").lower()
IS_PRODUCTION = ENVIRONMENT == "production"
DEBUG = env.bool("DEBUG", default=not IS_PRODUCTION)


def get_secret_key() -> str:
    secret_key = env("DJANGO_SECRET_KEY", default=os.getenv("SECRET_KEY"))
    if secret_key:
        return secret_key
    if DEBUG:
        return "django-insecure-local-development-key"
    raise ImproperlyConfigured("DJANGO_SECRET_KEY must be set when DEBUG is false.")


def get_required_env(name: str, *, allow_local_default: str | None = None) -> str:
    value = os.getenv(name, allow_local_default)
    if value:
        return value
    raise ImproperlyConfigured(f"{name} must be set when ENVIRONMENT=production.")


def load_gcs_credentials() -> Credentials | None:
    credentials_json = os.getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON")
    credentials_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

    if credentials_json:
        try:
            return Credentials.from_service_account_info(json.loads(credentials_json))
        except (json.JSONDecodeError, TypeError, ValueError) as exc:
            if IS_PRODUCTION:
                raise ImproperlyConfigured(
                    "GOOGLE_APPLICATION_CREDENTIALS_JSON is not valid service account JSON."
                ) from exc
            LOGGER.warning("Ignoring invalid Google credentials JSON: %s", exc)
            return None

    if credentials_path:
        try:
            return Credentials.from_service_account_file(credentials_path)
        except (OSError, ValueError) as exc:
            if IS_PRODUCTION:
                raise ImproperlyConfigured(
                    "GOOGLE_APPLICATION_CREDENTIALS does not point to a valid service account file."
                ) from exc
            LOGGER.warning("Ignoring invalid Google credentials file: %s", exc)

    return None


SECRET_KEY = get_secret_key()

railway_public_domain = os.getenv("RAILWAY_PUBLIC_DOMAIN")
railway_public_origin = f"https://{railway_public_domain}" if railway_public_domain else None

default_allowed_hosts = ["127.0.0.1", "localhost"]
if DEBUG:
    default_allowed_hosts.append("*")  # Allow any host in local development
if railway_public_domain:
    default_allowed_hosts.append(railway_public_domain)

configured_allowed_hosts = [host for host in env.list("ALLOWED_HOSTS", default=[]) if host]
ALLOWED_HOSTS = sorted(set(configured_allowed_hosts or default_allowed_hosts if DEBUG else configured_allowed_hosts + ([railway_public_domain] if railway_public_domain else [])))

if not ALLOWED_HOSTS:
    raise ImproperlyConfigured("ALLOWED_HOSTS must be set for non-debug environments.")

default_cors_origins = [origin for origin in [os.getenv("FRONTEND_URL"), railway_public_origin] if origin]
CORS_ALLOWED_ORIGINS = env.list("CORS_ALLOWED_ORIGINS", default=default_cors_origins)
CSRF_TRUSTED_ORIGINS = env.list("CSRF_TRUSTED_ORIGINS", default=default_cors_origins)
CORS_ALLOW_ALL_ORIGINS = DEBUG and not CORS_ALLOWED_ORIGINS
# Allow localhost on any port (for Flutter web dev against production backend)
CORS_ALLOWED_ORIGIN_REGEXES = [
    r"^http://localhost:\d+$",
    r"^http://127\.0\.0\.1:\d+$",
]

database_url = env("DATABASE_URL", default=None)
if not database_url:
    if DEBUG:
        database_url = f"sqlite:///{BASE_DIR / 'db.sqlite3'}"
    else:
        database_url = get_required_env("DATABASE_URL")

redis_default_url = "redis://localhost:6379/0" if DEBUG else None
CELERY_BROKER_URL = env("CELERY_BROKER_URL", default=os.getenv("REDIS_URL", redis_default_url))
CELERY_RESULT_BACKEND = env("CELERY_RESULT_BACKEND", default=os.getenv("REDIS_URL", redis_default_url))
if not CELERY_BROKER_URL:
    CELERY_BROKER_URL = get_required_env("CELERY_BROKER_URL")
if not CELERY_RESULT_BACKEND:
    CELERY_RESULT_BACKEND = get_required_env("CELERY_RESULT_BACKEND")

CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TASK_SERIALIZER = "json"
CELERY_RESULT_SERIALIZER = "json"
CELERY_TIMEZONE = "UTC"

GS_CREDENTIALS = load_gcs_credentials()
GS_BUCKET_NAME = os.getenv("GS_BUCKET_NAME")
USE_GCS = bool(GS_BUCKET_NAME and GS_CREDENTIALS)

# Google OAuth client ID used to verify mobile sign-in tokens
GOOGLE_OAUTH_CLIENT_ID = env("GOOGLE_OAUTH_CLIENT_ID", default="")

if GS_BUCKET_NAME and not GS_CREDENTIALS and IS_PRODUCTION:
    raise ImproperlyConfigured(
        "GS_BUCKET_NAME was provided without valid Google Cloud credentials."
    )

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework.authtoken', 
    'imagekit',
    'corsheaders',
    'recipes',
    'ai_chatbot',
    'social',
    'accounts',
    'storages',
    'recommendations',
    'meal_planning',
]

AUTHENTICATION_BACKENDS = (
    'django.contrib.auth.backends.ModelBackend',
)

AUTH_USER_MODEL = 'accounts.CustomUser'

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

SECURE_CONTENT_TYPE_NOSNIFF = env.bool('SECURE_CONTENT_TYPE_NOSNIFF', default=IS_PRODUCTION)

# Rest Framework Settings
REST_FRAMEWORK = {
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
    'DEFAULT_PARSER_CLASSES': [
        'rest_framework.parsers.JSONParser',
    ],
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
    ],
}

REST_USE_JWT = True

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=5),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
    'ROTATE_REFRESH_TOKENS': False,
    'BLACKLIST_AFTER_ROTATION': False,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'VERIFYING_KEY': None,
    'AUDIENCE': None,
    'ISSUER': None,
    'JWK_URL': None,
    'LEeway': 0,
}


ROOT_URLCONF = 'api.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'api.wsgi.application'


# Database
# https://docs.djangoproject.com/en/5.1/ref/settings/#databases

default_database = dj_database_url.parse(
    database_url,
    conn_max_age=env.int('DB_CONN_MAX_AGE', default=600),
)

if IS_PRODUCTION and default_database['ENGINE'] != 'django.db.backends.sqlite3':
    default_database.setdefault('OPTIONS', {})['sslmode'] = 'require'

DATABASES = {
    'default': default_database
}


# Password validation
# https://docs.djangoproject.com/en/5.1/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
]


# Internationalization
# https://docs.djangoproject.com/en/5.1/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/5.1/howto/static-files/

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

STORAGES = {
    'staticfiles': {
        # CompressedStaticFilesStorage works without a pre-built manifest;
        # use CompressedManifestStaticFilesStorage only when collectstatic has run.
        'BACKEND': 'whitenoise.storage.CompressedStaticFilesStorage',
    },
}

if USE_GCS:
    MEDIA_URL = f'https://storage.googleapis.com/{GS_BUCKET_NAME}/'
    STORAGES['default'] = {
        'BACKEND': 'storages.backends.gcloud.GoogleCloudStorage',
        'OPTIONS': {
            'bucket_name': GS_BUCKET_NAME,
            'credentials': GS_CREDENTIALS,
            'file_overwrite': False,
            'default_acl': None,
        },
    }
else:
    STORAGES['default'] = {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
        'OPTIONS': {
            'location': MEDIA_ROOT,
            'base_url': MEDIA_URL,
        },
    }

# Default primary key field type
# https://docs.djangoproject.com/en/5.1/ref/settings/#default-auto-field

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# API Keys for nutrition services
ANTHROPIC_API_KEY = os.getenv('ANTHROPIC_API_KEY')
USDA_API_KEY = os.getenv('USDA_API_KEY')
MEAL_PLAN_REFINER_OPENAI_ENABLED = os.getenv("MEAL_PLAN_REFINER_OPENAI_ENABLED", "False").lower() == "true"
MEAL_PLAN_REFINER_OPENAI_MODEL = os.getenv("MEAL_PLAN_REFINER_OPENAI_MODEL", "gpt-3.5-turbo")

# Cache configuration for nutrition lookups
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-snowflake',
        'TIMEOUT': 300,
        'OPTIONS': {
            'MAX_ENTRIES': 1000,
        }
    }
}

SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
USE_X_FORWARDED_HOST = True
SECURE_SSL_REDIRECT = env.bool('SECURE_SSL_REDIRECT', default=IS_PRODUCTION)
SESSION_COOKIE_SECURE = IS_PRODUCTION
CSRF_COOKIE_SECURE = IS_PRODUCTION
SECURE_HSTS_SECONDS = env.int('SECURE_HSTS_SECONDS', default=31536000 if IS_PRODUCTION else 0)
SECURE_HSTS_INCLUDE_SUBDOMAINS = env.bool('SECURE_HSTS_INCLUDE_SUBDOMAINS', default=IS_PRODUCTION)
SECURE_HSTS_PRELOAD = env.bool('SECURE_HSTS_PRELOAD', default=False)

LOG_LEVEL = os.getenv('DJANGO_LOG_LEVEL', 'INFO' if IS_PRODUCTION else 'DEBUG')
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'standard': {
            'format': '%(asctime)s %(levelname)s %(name)s %(message)s',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'standard',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': LOG_LEVEL,
    },
}
