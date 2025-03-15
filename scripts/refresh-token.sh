#!/bin/sh

# Generate token
echo "Generating OAuth token..."
/icebreaker/scripts/generate-token-config.sh > /icebreaker/nginx/snowflake-auth-header.conf

# Reload nginx
echo "Reloading nginx..."
nginx -s reload -c /icebreaker/nginx/nginx.conf -e /icebreaker/nginx/error.log

echo "Done!"