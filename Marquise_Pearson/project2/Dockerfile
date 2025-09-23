FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# App code in /app (per the official guide)
WORKDIR /app
COPY project2.py ./project2.py

# Non-root user (guide best practice)
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Where CSVs will be written (mount your host here)
WORKDIR /work

# Make `docker run <image>` execute your script automatically
ENTRYPOINT ["python", "/app/project2.py"]
# Default URL if you run with no args (override at runtime)
CMD ["https://example.com"]
