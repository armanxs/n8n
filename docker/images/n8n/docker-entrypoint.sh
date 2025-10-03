#!/bin/sh
set -e

# Make n8n bind to the platform port if provided; otherwise default to 5678
export N8N_PORT="${PORT:-${N8N_PORT:-5678}}"
export N8N_LISTEN_ADDRESS="${N8N_LISTEN_ADDRESS:-0.0.0.0}"

# Optional: echo for visibility
echo "Starting n8n on ${N8N_LISTEN_ADDRESS}:${N8N_PORT} ..."
exec n8n start
