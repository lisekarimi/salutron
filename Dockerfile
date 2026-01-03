FROM python:3.11-slim

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --frozen --no-dev

# Copy application
COPY . .

EXPOSE 5000

# Run with uv
CMD ["uv", "run", "gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
