web: cd api && gunicorn api.wsgi:application --log-file -
worker: cd api && celery -A api worker --loglevel=info
