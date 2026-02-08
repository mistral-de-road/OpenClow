import urllib.request
import json
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

url = "https://moltbot-sandbox.mistral-de-road.workers.dev/debug/processes?logs=true&token=my-secret-4863"

try:
    with urllib.request.urlopen(url, context=ctx) as response:
        data = json.load(response)
        print(f"Process count: {data.get('count')}")
        for p in data.get('processes', []):
            print(f"--- Process {p.id} ({p.status}) ---")
            print(f"Command: {p.command}")
            if 'stdout' in p:
                print(f"STDOUT:\n{p['stdout']}")
            if 'stderr' in p:
                print(f"STDERR:\n{p['stderr']}")
            print("-" * 30)
except Exception as e:
    print(f"Error: {e}")
