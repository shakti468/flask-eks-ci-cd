# Dockerfile
# Stage 1: build / install dependencies
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build-essential if needed for C extensions (optional)
RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency files
COPY app/requirements.txt .

# Install into an isolated directory to keep final image small
RUN python -m pip install --upgrade pip
RUN pip install --prefix=/install -r requirements.txt

# Stage 2: final runtime image
FROM python:3.11-slim

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY app/ /app

# Create a non-root user for security
RUN useradd --create-home appuser && chown -R appuser /app
USER appuser

# Expose port
EXPOSE 5000

# Use gunicorn for production; bind to 0.0.0.0 so container accepts external traffic
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app", "--workers", "2"]
