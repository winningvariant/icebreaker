# Generates an OAuth token to authenticate with Snowflake Snowpark Container Serices.
# Derived from Snowflake Tutorial (https://docs.snowflake.com/en/developer-guide/snowpark-container-services/tutorials/tutorial-1#optional-access-the-public-endpoint-programmatically)

from generate_jwt import JWTGenerator
from datetime import timedelta
import argparse
import logging
import sys
import requests
logger = logging.getLogger(__name__)
# logger.setLevel(logging.DEBUG)

def main():
  args = _parse_args()
  token = _get_token(args)
  oauth_token = token_exchange(token,endpoint=args.endpoint, role=args.role,
                  snowflake_account_url=args.snowflake_account_url,
                  snowflake_account=args.account)
  
  print(oauth_token)

def _get_token(args):
  token = JWTGenerator(args.account, args.user, args.private_key_file_path, timedelta(minutes=args.lifetime),
            timedelta(minutes=args.renewal_delay)).get_token()
  logger.debug("Key Pair JWT: %s" % token)
  return token

def token_exchange(token, role, endpoint, snowflake_account_url, snowflake_account):
  scope_role = f'session:role:{role}' if role is not None else None
  scope = f'{scope_role} {endpoint}' if scope_role is not None else endpoint
  data = {
    'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    'scope': scope,
    'assertion': token,
  }
  logger.debug(data)
  url = f'https://{snowflake_account}.snowflakecomputing.com/oauth/token'
  if snowflake_account_url:
    url =       f'{snowflake_account_url}/oauth/token'
  logger.debug("oauth url: %s" %url)
  response = requests.post(url, data=data)
  logger.debug("snowflake response : %s" % response.status_code)
  logger.debug("snowflake token : %s" % response.text)
  assert 200 == response.status_code, f"unable to get snowflake token. status: {response.status_code}, response: {response.text}"
  return response.text

def _parse_args():
  logging.basicConfig(stream=sys.stdout, level=logging.INFO)
  cli_parser = argparse.ArgumentParser()
  cli_parser.add_argument('--account', required=True,
              help='The account identifier (for example, "myorganization-myaccount" for '
                '"myorganization-myaccount.snowflakecomputing.com").')
  cli_parser.add_argument('--user', required=True, help='The user name.')
  cli_parser.add_argument('--private_key_file_path', required=True,
              help='Path to the private key file used for signing the JWT.')
  cli_parser.add_argument('--lifetime', type=int, default=59,
              help='The number of minutes that the JWT should be valid for.')
  cli_parser.add_argument('--renewal_delay', type=int, default=54,
              help='The number of minutes before the JWT generator should produce a new JWT.')
  cli_parser.add_argument('--role',
              help='The role we want to use to create and maintain a session for. If a role is not provided, '
                'use the default role.')
  cli_parser.add_argument('--endpoint', required=True,
              help='The ingress endpoint of the service')
  cli_parser.add_argument('--snowflake_account_url', default=None,
              help='The account url of the account for which we want to log in. Type of '
                'https://myorganization-myaccount.snowflakecomputing.com')
  args = cli_parser.parse_args()
  return args

if __name__ == "__main__":
  main()