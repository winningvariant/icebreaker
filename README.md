# icebreaker
Reverse proxy (using nginx) for accessing [Snowflake Snowpark Container Services](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/overview) (SPCS) from the public internet.

This project contains all configuration and scripts for building an image that does two main things:

1. Run a background job (managed by `cron`) that gets a new Snowflake OAuth token hourly
2. Runs an `nginx` server as a reverse proxy to the SPCS endpoint

## Why this exists

SPCS is a great way to run containers on Snowflake. However, it's not possible to access them from the public internet without authenticating with an OAuth token. `icebreaker` allows you to do just that proxying unauthenticated traffic to SPCS through an authenticated service account.

## How it works

Built into the image is a process that gets a Snowflake OAuth token upon start and refreshes it hourly. This token is written into a configuration file that's read by nginx. Nginx pulls in this file on start/restart and uses its value in the `Authorization` HTTP header when proxying requests to SPCS.

Each hour, when the token is refreshed, nginx is restarted to pull in the new value.

## Dependencies

1. An SPCS service with a public endpoint to route traffic to.
2. A Snowflake role that has access to the SPCS endpoint.
3. A Snowflake service user [set up with key pair authentication](https://docs.snowflake.com/en/user-guide/key-pair-auth). This project will need the private key (unencrypted). This user must be granted the role from #2.

## Deploying

### Configuration

The following environment variables are **REQUIRED** when running the image:

| Environment Variable | Description | Example |
|---|---|---|
| `PORT` | The port to launch the nginx server on within the container. | `80` |
| `SNOWFLAKE_ENDPOINT` | The hostname of the SPCS endpoint to proxy traffic to (no protocol). | `<random>-<org>-<account>.snowflakecomputing.app` |
| `SNOWFLAKE_ACCOUNT` | Account ID for the Snowflake account the service resides within. | `<org>-<account>` |
| `SNOWFLAKE_USER` | The username of the service user to log in with. | `PROXY_USER` |
| `SNOWFLAKE_PRIVATE_KEY_PATH` | Path to the service user's private key within the container. | `/icebreaker/private.key` |
| `SNOWFLAKE_ROLE` | The Snowflake role (case sensitive) to use. | `SPCS_PROXY`  |

### Example Docker Compose File

Here's an example `docker-compose.yml` file to launch an `icebreaker` container.

```yaml
services:
  web:
    image: icebreaker:latest
    volumes:
      - /local/path/to/private.key:/icebreaker/private.key:ro
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
      - SNOWFLAKE_ENDPOINT=<random>-<org>-<account>.snowflakecomputing.app
      - SNOWFLAKE_ACCOUNT=<org>-<account>
      - SNOWFLAKE_USER=<user>
      - SNOWFLAKE_PRIVATE_KEY_PATH=/icebreaker/private.key
      - SNOWFLAKE_ROLE=<Role>
```

## Building

To build, run the following command:

```
docker build . -t icebreaker:latest -t icebreaker:<VERSION>
```

## Customizing

### Custom nginx configuration

The `nginx.conf.template` file is located in the root of the repository. This file is used to configure the reverse proxy. Use `${DOLLAR}` anywhere you need a literal `$` in the nginx configuration. This is due to the substitution that happens when the template is used to build the `nginx.conf` file.

### Custom cron job

The cron job (`crontab`) is located in the root of the repository. This file is used to configure the cron job that refreshes the Snowflake OAuth token. Here, you can alter the frequency of the OAuth token refresh.

## Disclaimers

This project is not affiliated with nor endorsed by [Snowflake](https://www.snowflake.com/). "Snowflake", "Snowpark Container Services", and other related terms are trademarks of Snowflake, Inc.

## Authors

This project is owned and maintained by [Winning Variant, LLC](https://www.winningvariant.com/).

## License

This project is licensed under the [MIT License](LICENSE) and inherits the [nginx License](https://nginx.org/LICENSE).
