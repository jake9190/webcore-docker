#!/bin/sh
set -eu

endpoint_hub_ids=${WEBCORE_ENDPOINT_HUB_ID_MAP:-{}}
printf 'window.webcoreConfig = { endpointHubIds: %s };\n' "$endpoint_hub_ids" > /var/www/webcore/config.js

exec "$@"