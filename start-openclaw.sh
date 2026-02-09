#!/bin/bash
# High-reliability startup script for OpenClaw (Gemini focus)
set -ex
export DEBUG=*


# Patch OpenClaw to support Gemini 2.0 Flash (dynamic patching)
if [ -f "/usr/local/lib/node_modules/openclaw/dist/entry.js" ]; then
  echo "Patching OpenClaw to support Gemini 2.0 Flash..."
  sed -i 's/gemini-1.5-flash/gemini-2.0-flash/g' /usr/local/lib/node_modules/openclaw/dist/entry.js
fi

CONFIG_DIR="/root/.openclaw"
mkdir -p "$CONFIG_DIR"

echo "Generating static config using Node.js for reliable environment variable expansion..."
node -e "
const fs = require('fs');
const gatewayToken = process.env.OPENCLAW_GATEWAY_TOKEN;
const googleKey = process.env.GOOGLE_GENERATIVE_AI_API_KEY || process.env.GEMINI_API_KEY;

if (!gatewayToken) {
  console.error('CRITICAL: OPENCLAW_GATEWAY_TOKEN is not set.');
  process.exit(1);
}
if (!googleKey) {
  console.error('CRITICAL: GOOGLE_GENERATIVE_AI_API_KEY or GEMINI_API_KEY is not set.');
  process.exit(1);
}

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
      model: { primary: 'google/gemini-2.0-flash' }
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
            id: 'gemini-2.0-flash',
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

echo "Final environment check:"
echo "OPENCLAW_HOME: $OPENCLAW_HOME"
echo "OPENCLAW_GATEWAY_TOKEN: ${OPENCLAW_GATEWAY_TOKEN:0:4}..."
echo "GOOGLE_GENERATIVE_AI_API_KEY: ${GOOGLE_GENERATIVE_AI_API_KEY:0:4}..."

# Check if openclaw exists
which openclaw || echo "openclaw not found in PATH"

echo "Executing openclaw gateway..."
exec openclaw gateway --port 18789 --verbose --allow-unconfigured --bind 0.0.0.0 --token "${OPENCLAW_GATEWAY_TOKEN}"
