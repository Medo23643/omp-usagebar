#!/usr/bin/env bash
# Kill any previous instance to avoid port conflicts
pkill -f 'omp stats' 2>/dev/null || true

# Start omp stats with 5-minute auto-timeout (omp opens the browser automatically)
timeout 300 omp stats --port 44011 >/dev/null 2>&1 &
