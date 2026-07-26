#!/usr/bin/env bash
set -e

# =============================================================================
# CoinTrack Backend — Docker Entrypoint
#
# For use with Neon PostgreSQL (DATABASE_URL env var).
# Runs Alembic migrations then starts uvicorn.
# =============================================================================

cd /app

# ── 1. Run Alembic migrations ───────────────────────────────────────────────
echo "→ Running database migrations..."
alembic upgrade head
echo "✓ Migrations complete."

# ── 2. Start uvicorn in the foreground ───────────────────────────────────────
echo "→ Starting uvicorn on 0.0.0.0:8000..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --proxy-headers
