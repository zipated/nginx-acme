#!/bin/bash

# Check /cert is exist
if [ ! -d "/cert" ]; then
    mkdir -p /cert
fi

# Read all env
IFS=',' read -r -a cfTokenList <<< "$CF_Token_List"
IFS=',' read -r -a cfAccountIdList <<< "$CF_Account_ID_List"
IFS=',' read -r -a domainList <<< "$DOMAIN_List"

# Check if any domain is already initialized
any_found=false
for domain in "${domainList[@]}"; do
  if "/root/.acme.sh/acme.sh" --list | grep -q "$domain"; then
      any_found=true
      break
  fi
done

# If none of the domains are found, register account and set CA
if [ "$any_found" = false ]; then
       echo "Register account and set default CA."
      "/root/.acme.sh/acme.sh" --register-account -m "$EMAIL"
      "/root/.acme.sh/acme.sh" --set-default-ca --server zerossl
fi

# Helper function
empty_prev() {
  local -n arr=$1
  local -n prev=$2
  local idx=$3
  if [ -z "${arr[$idx]}" ]; then
    arr[$idx]="$prev"
  else
    prev="${arr[$idx]}"
  fi
  echo "$prev"
}

# Initialize prev
prev_cfToken=""
prev_cfAccountId=""

# Get Value from env
for i in "${!domainList[@]}"; do
  # Update prev
  prev_cfToken=$(empty_prev cfTokenList prev_cfToken $i)
  prev_cfAccountId=$(empty_prev cfAccountIdList prev_cfAccountId $i)

  # Export env
  export CF_Token="${prev_cfToken}"
  export CF_Account_ID="${prev_cfAccountId}"
  export DOMAIN="${domainList[$i]}"

  # Check init
  if ! "/root/.acme.sh/acme.sh" --list | grep -q "$DOMAIN"; then
      "/root/.acme.sh/acme.sh" --issue --dns "dns_cf"  -d "$DOMAIN" -d "*.$DOMAIN"
  fi

  # Execute
  "/root/.acme.sh/acme.sh" --installcert -d "$DOMAIN" \
          --key-file /cert/"$DOMAIN".key \
          --fullchain-file /cert/"$DOMAIN".crt
done

# Execute
"/root/.acme.sh/acme.sh" --cron --home "/root/.acme.sh"

# Nginx reload
nginx -s reload
