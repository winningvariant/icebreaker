#!/bin/sh
# Generates the authentication configuration file for nginx. Contents are
# written to stdout.

TOKEN=$(python /icebreaker/python/generate_token.py \
  --account $SNOWFLAKE_ACCOUNT \
  --user $SNOWFLAKE_USER \
  --private_key_file_path $SNOWFLAKE_PRIVATE_KEY_PATH \
  --role $SNOWFLAKE_ROLE \
  --endpoint $SNOWFLAKE_ENDPOINT)

echo "# This file was automatically generated at: $(date)"
echo "set \$snowflake_auth_header 'Snowflake Token=\"${TOKEN}\"';"