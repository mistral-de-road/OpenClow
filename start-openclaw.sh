#!/bin/bash
# High-reliability startup script for OpenClaw (Clean Version)
set -e

CONFIG_DIR="/root/.openclaw"
mkdir -p "$CONFIG_DIR"

echo "Generating configuration..."
node -e "
const fs = require('fs');
const gatewayToken = process.env.OPENCLAW_GATEWAY_TOKEN;
const googleKey = process.env.GOOGLE_GENERATIVE_AI_API_KEY || process.env.GEMINI_API_KEY;

if (!gatewayToken || !googleKey) {
  console.error('CRITICAL: Required environment variables are missing.');
  process.exit(1);
}

const config = {
  messages: { ackReactionScope: 'group-mentions' },
  agents: {
    defaults: {
      maxConcurrent: 4,
      subagents: { maxConcurrent: 8 },
      compaction: { mode: 'safeguard' },
      workspace: '/root/.openclaw/workspace',
      model: { primary: 'google/gemini-1.5-flash' } // Initial fallback
    }
  },
  gateway: {
    mode: 'local',
    port: 18789,
    bind: '0.0.0.0',
    auth: { mode: 'token', token: gatewayToken },
    controlUi: { allowInsecureAuth: true }
  },
  models: {
    mode: 'merge',
    providers: {
      google: {
        baseUrl: 'https://generativelanguage.googleapis.com',
        apiKey: googleKey,
        api: 'google-generative-ai',
        models: [
          {
            id: 'gemini-2.0-flash',
            name: 'Gemini 2.0 Flash',
            contextWindow: 1048576,
            maxTokens: 8192,
            input: ['text', 'image'],
            cost: { input: 0, output: 0 }
          }
        ]
      }
    }
  }
};

fs.writeFileSync('/root/.openclaw/openclaw.json', JSON.stringify(config, null, 2));
"

export OPENCLAW_HOME="/root/.openclaw"
echo "Starting OpenClaw Gateway..."
exec openclaw gateway --port 18789 --verbose --allow-unconfigured --bind 0.0.0.0 --token "${OPENCLAW_GATEWAY_TOKEN}"
