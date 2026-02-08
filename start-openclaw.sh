#!/bin/bash
# High-reliability startup script for OpenClaw (Gemini focus)
set -ex

CONFIG_DIR="/root/.openclaw"
mkdir -p "$CONFIG_DIR"

echo "Generating static config using Node.js for reliable environment variable expansion..."
node -e "
const fs = require('fs');
const gatewayToken = process.env.OPENCLAW_GATEWAY_TOKEN || 'my-secret-4863';
const googleKey = process.env.GOOGLE_GENERATIVE_AI_API_KEY || process.env.GEMINI_API_KEY || 'AIzaSyC8-ySLrut_IvuE-1xohiVdeNp9CokmMjY';

const config = {
  messages: {
    ackReactionScope: 'group-mentions'
  },
  agents: {
    defaults: {
      maxConcurrent: 4,
      subagents: { maxConcurrent: 8 },
      compaction: { mode: 'safeguard' },
      workspace: '/root/.openclaw/workspace',
      model: { primary: 'google/gemini-1.5-flash' }
    }
  },
  gateway: {
    mode: 'local',
    port: 18789,
    bind: 'lan',
    auth: {
      mode: 'token',
      token: gatewayToken
    },
    trustedProxies: ['10.1.0.0'],
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
            id: 'gemini-1.5-flash',
            name: 'Gemini 1.5 Flash',
            contextWindow: 1048576,
            maxTokens: 8192,
            input: ['text', 'image'],
            cost: { input: 0.075, output: 0.3, cacheRead: 0.01, cacheWrite: 0.01 }
          }
        ]
      }
    }
  },
  auth: {
    profiles: {
      'google:manual': {
        provider: 'google',
        mode: 'api_key'
      }
    }
  },
  channels: {},
  meta: { 
    lastTouchedVersion: '2026.2.3', 
    lastTouchedAt: new Date().toISOString()
  }
};

fs.writeFileSync('$CONFIG_DIR/openclaw.json', JSON.stringify(config, null, 2));
console.log('Static configuration generated successfully.');
"

echo "Starting OpenClaw Gateway with static config..."
rm -f "$CONFIG_DIR/gateway.lock" 2>/dev/null || true

# Explicitly set OPENCLAW_HOME to ensure config is picked up
export OPENCLAW_HOME="/root/.openclaw"

exec openclaw gateway --port 18789 --verbose --allow-unconfigured --bind lan --token "${OPENCLAW_GATEWAY_TOKEN:-my-secret-4863}"
