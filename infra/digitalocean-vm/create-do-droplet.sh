#!/usr/bin/env bash
set -euo pipefail

# Create (or rebuild) a DigitalOcean droplet with cloud-init user-data + password auth.
# Requirements:
#  - env DO_TOKEN (DigitalOcean personal access token)
#  - env VM_PASSWORD (password for the jenkins user)
#  - curl, jq
# Usage:
#   REGION=nyc3 SIZE=s-2vcpu-4gb IMAGE=ubuntu-22-04-x64 NAME=ecommerce-integration-runner \
#   VM_PASSWORD='P@ssw0rd!' DO_TOKEN=... ./create-do-droplet.sh

REGION=${REGION:-"nyc3"}
SIZE=${SIZE:-"s-2vcpu-4gb"}
IMAGE=${IMAGE:-"ubuntu-22-04-x64"}
NAME=${NAME:-"ecommerce-integration-runner"}
SSH_KEYS_JSON=${SSH_KEYS_JSON:-"[]"}  # optional: JSON array of SSH key IDs to attach

if [[ -z "${DO_TOKEN:-}" ]]; then
  echo "Missing DO_TOKEN env var" >&2
  exit 1
fi
if [[ -z "${VM_PASSWORD:-}" ]]; then
  echo "Missing VM_PASSWORD env var" >&2
  exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CLOUD_INIT_TEMPLATE="${CLOUD_INIT_TEMPLATE:-cloud-init.yaml}"
CLOUD_INIT_TEMPLATE="${SCRIPT_DIR}/${CLOUD_INIT_TEMPLATE}"
if [[ ! -f "${CLOUD_INIT_TEMPLATE}" ]]; then
  echo "cloud-init template not found at ${CLOUD_INIT_TEMPLATE}" >&2
  exit 1
fi

# Inject password into cloud-init template safely
USER_DATA=$(sed "s|__VM_PASSWORD__|${VM_PASSWORD//|/\|}|g" "${CLOUD_INIT_TEMPLATE}")

echo "Creating droplet '${NAME}' in ${REGION} (${SIZE})..."
echo "Using cloud-init template: ${CLOUD_INIT_TEMPLATE}"
CREATE_PAYLOAD=$(jq -n \
  --arg name "${NAME}" \
  --arg region "${REGION}" \
  --arg size "${SIZE}" \
  --arg image "${IMAGE}" \
  --arg user_data "${USER_DATA}" \
  --argjson ssh_keys "${SSH_KEYS_JSON}" \
  '{name:$name, region:$region, size:$size, image:$image, user_data:$user_data, ssh_keys:$ssh_keys, backups:false, ipv6:false, monitoring:true, tags:["ecommerce-tests"]}')

RESP=$(curl -sS -X POST "https://api.digitalocean.com/v2/droplets" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${DO_TOKEN}" \
  -d "${CREATE_PAYLOAD}")

if [[ "$(echo "$RESP" | jq -r '.droplet.id?')" == "null" ]]; then
  echo "$RESP" | jq . >&2
  echo "Droplet creation failed" >&2
  exit 1
fi

DROPLET_ID=$(echo "$RESP" | jq -r '.droplet.id')
echo "Droplet ID: ${DROPLET_ID}"

echo "Waiting for public IP..."
for i in {1..60}; do
  DESC=$(curl -sS -H "Authorization: Bearer ${DO_TOKEN}" "https://api.digitalocean.com/v2/droplets/${DROPLET_ID}")
  IP=$(echo "$DESC" | jq -r '.droplet.networks.v4[] | select(.type=="public") | .ip_address' | head -n1)
  if [[ -n "${IP}" && "${IP}" != "null" ]]; then
    echo "Public IP: ${IP}"
    break
  fi
  sleep 5
done

if [[ -z "${IP:-}" ]]; then
  echo "Could not get public IP for droplet ${DROPLET_ID}" >&2
  exit 1
fi

cat <<EOF

Droplet created successfully.

Name:      ${NAME}
Region:    ${REGION}
Size:      ${SIZE}
Image:     ${IMAGE}
DropletID: ${DROPLET_ID}
Public IP: ${IP}

Login (password-based):
  ssh jenkins@${IP}
  Password: (value set in VM_PASSWORD)

EOF
