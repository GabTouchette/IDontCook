# ICantCook

## Backend deployment baseline

The production backend is expected to run on Railway with separate web and worker services.

### Runtime commands

- Web: `cd api && gunicorn api.wsgi:application --log-file -`
- Worker: `cd api && celery -A api worker --loglevel=info`

### Required environment variables

- `ENVIRONMENT=production`
- `DEBUG=false`
- `DJANGO_SECRET_KEY`
- `DATABASE_URL`
- `ALLOWED_HOSTS`
- `CELERY_BROKER_URL` or `REDIS_URL`
- `CELERY_RESULT_BACKEND` or `REDIS_URL`

### Optional environment variables

- `CORS_ALLOWED_ORIGINS`
- `CSRF_TRUSTED_ORIGINS`
- `FRONTEND_URL`
- `RAILWAY_PUBLIC_DOMAIN`
- `OPENAI_API_KEY`
- `USDA_API_KEY`
- `GS_BUCKET_NAME`
- `GOOGLE_APPLICATION_CREDENTIALS_JSON`
- `GOOGLE_APPLICATION_CREDENTIALS`

If Google Cloud Storage credentials are not provided, media files fall back to local filesystem storage. For Railway production, configure both `GS_BUCKET_NAME` and one of the Google credentials variables if media uploads must persist across deploys.