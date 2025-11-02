# Dockerfile for nof2 project
# Uses Python 3.12.6 (slim) and creates a non-root user

FROM python:3.12-slim

# keep Python output unbuffered (helpful for logs)
ENV PYTHONUNBUFFERED=1
ENV PATH="/home/appuser/.local/bin:${PATH}"

WORKDIR /opt/app

# Install minimal system deps needed to build wheels for some packages
# (this keeps image smaller than full build-essential but covers common cases)
# Update and upgrade OS packages first to pull in security fixes from the base image
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       build-essential \
       gcc \
       g++ \
       libssl-dev \
       libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash appuser

# Copy only requirements first to leverage Docker cache
COPY requirements.txt /opt/app/requirements.txt

# Install python deps (no-cache to reduce image size)
RUN pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

# sanity check: fail kalau joblib tidak terinstall
RUN python - <<'PY'
import sys
import importlib
m = importlib.import_module("joblib")
print("joblib OK", getattr(m, "__version__", "?"))
PY

# Copy application code
COPY . /opt/app

# Fix permissions and switch to non-root
RUN chown -R appuser:appuser /opt/app
USER appuser

# Expose web UI port (as used in alpha_web_server.py)
EXPOSE 58183

# Default command: run the provided entrypoint script
CMD ["python", "run_alpha.py"]
