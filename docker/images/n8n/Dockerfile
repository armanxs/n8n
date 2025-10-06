# Use the official, prebuilt n8n image (includes all dependencies)
FROM n8nio/n8n:1.112.4

# Bind correctly on Railway
ENV N8N_LISTEN_ADDRESS=0.0.0.0

# Start n8n on Railway's assigned port
EXPOSE 5678
CMD ["sh", "-lc", "echo Starting n8n on 0.0.0.0:${PORT:-5678}; n8n start --port ${PORT:-5678} --host 0.0.0.0"]
