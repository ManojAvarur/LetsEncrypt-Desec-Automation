#!/usr/bin/env bash

set -euo pipefail

DOMAIN="${CERTBOT_DOMAIN}"
RECORD_NAME="_acme-challenge.${DOMAIN}"

DESEC_DOMAIN=$(echo "$DESEC_DOMAIN" | tr -d '\r\n')
DESEC_TOKEN=$(echo "$DESEC_TOKEN" | tr -d '\r\n')

if [[ -z "$DESEC_TOKEN" || -z "$DESEC_DOMAIN" ]]; then
    echo "Error: DESEC_TOKEN or DESEC_DOMAIN not set"
    exit 1
fi

# DELETE the RRSet
echo "Deleting DNS TXT record for ${RECORD_NAME}"

curl -s -X DELETE "https://desec.io/api/v1/domains/${DESEC_DOMAIN}/rrsets/_acme-challenge/TXT/" \
    -H "Authorization: Token ${DESEC_TOKEN}"

echo "DNS record deleted."
