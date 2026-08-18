FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy backend code (. is the backend folder due to build context)
COPY . .

# Copy pre-built frontend from parent directory
# azd sets build context to ./backend, so ../ goes back to project root
COPY ../frontend/dist ./frontend/dist

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt gunicorn uvicorn

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/')" || exit 1

# Run the app
CMD ["gunicorn", "-w", "1", "-k", "uvicorn.workers.UvicornWorker", "-b", "0.0.0.0:8000", "main:app"]
