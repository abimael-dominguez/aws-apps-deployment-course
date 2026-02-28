#!/usr/bin/env bash
set -euo pipefail

mkdir -p data

cat > data/customers.json <<'JSON'
[
  {"id": 1, "name": "Ana", "country": "PE", "active": true},
  {"id": 2, "name": "Luis", "country": "MX", "active": true},
  {"id": 3, "name": "Marta", "country": "CO", "active": false}
]
JSON

sha256sum data/customers.json
