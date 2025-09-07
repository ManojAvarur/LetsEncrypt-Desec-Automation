#!/usr/bin/env bash

set -euo pipefail

# Provided by Certbot
DOMAIN="${CERTBOT_DOMAIN}"
VALIDATION="${CERTBOT_VALIDATION}"
RECORD_NAME="_acme-challenge.${DOMAIN}"

# Your deSEC credentials (should be set as environment variables)
DESEC_DOMAIN=$(echo "$DESEC_DOMAIN" | tr -d '\r\n')
DESEC_TOKEN=$(echo "$DESEC_TOKEN" | tr -d '\r\n')

SLEEP_TIME=30
MAX_ATTEMPTS=40

if [[ -z "$DESEC_TOKEN" || -z "$DESEC_DOMAIN" ]]; then
    echo "Error: DESEC_TOKEN or DESEC_DOMAIN not set"
    exit 1
fi

payload=$(cat <<JSON
{
    "subname": "_acme-challenge",
    "type": "TXT",
    "ttl": 60,
    "records": ["\"$VALIDATION\""]
}
JSON
)

echo "Creating DNS TXT record for ${RECORD_NAME} with value ${VALIDATION}"

response=$(curl "https://desec.io/api/v1/domains/${DESEC_DOMAIN}/rrsets/" \
    --header "Authorization: Token ${DESEC_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "$payload")


if echo "$response" | grep -q '"created"'; then
    echo "Successfully created DNS record."
else
    echo "Creatation failed"
    echo "$response"
    exit 1
fi

echo "Waiting for DNS to propagate..."

attempt=1
while [[ $attempt -le $MAX_ATTEMPTS ]]; do
    echo "Attempt $attempt: Checking DNS for ${RECORD_NAME}..."

    txt_values=$(dig +short TXT "${RECORD_NAME}" | tr -d '"')

    if echo "$txt_values" | grep -q "$VALIDATION"; then
        echo "DNS record found and propagated."
        exit 0
    fi

    echo "Not yet propagated. Waiting ${SLEEP_TIME}s..."
    sleep "$SLEEP_TIME"
    ((attempt++))
done

echo "Gave up after $MAX_ATTEMPTS attempts. DNS not propagated."
exit 1
