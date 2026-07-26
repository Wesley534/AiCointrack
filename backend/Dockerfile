# =============================================================================
# CoinTrack Backend — Docker Image
# Lightweight: FastAPI (uvicorn) + PostgreSQL driver (Neon DB)
# =============================================================================
FROM python:3.11-slim-bookworm

LABEL description="CoinTrack API — FastAPI + PostgreSQL (Neon)"

# ── Application code ─────────────────────────────────────────────────────────
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN chmod +x start.sh

EXPOSE 8000

CMD ["./start.sh"]
