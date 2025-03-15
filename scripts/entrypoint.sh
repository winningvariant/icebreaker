#!/bin/sh

# Generate initial token
echo "Generating OAuth token..."
/icebreaker/scripts/generate-token-config.sh > /icebreaker/nginx/snowflake-auth-header.conf

# Update nginx configuration file with environment variables. The use of the `DOLLAR`
# environment variable is to prevent envsubst from interpreting the `$` character for
# request variables. See here: https://www.baeldung.com/linux/nginx-config-environment-variables#4-a-common-pitfall
export DOLLAR="$"
envsubst < /icebreaker/nginx/nginx.conf.template > /icebreaker/nginx/nginx.conf

# Start nginx
echo "Starting nginx..."
nginx -c /icebreaker/nginx/nginx.conf -e /icebreaker/nginx/error.log

# Start cron
echo "Starting cron..."
crond -f -L /icebreaker/cron.log