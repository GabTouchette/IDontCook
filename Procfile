web: cd api && gunicorn api.wsgi:application --bind 0.0.0.0:$PORT --workers 2 --log-file -
worker: cd api && celery -A api worker --loglevel=info
