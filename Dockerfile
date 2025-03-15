FROM python:3.12-alpine

RUN mkdir -p /icebreaker/scripts
RUN mkdir -p /icebreaker/nginx
RUN mkdir -p /icebreaker/python

WORKDIR /icebreaker

# Install other dependencies, including nginx
RUN apk update && apk add nginx envsubst

# Copy python source and install dependencies
COPY src/requirements.txt ./python/
COPY src/*.py ./python/

WORKDIR /icebreaker/python
RUN pip install --no-cache-dir -r requirements.txt
WORKDIR /icebreaker

# Copy scripts
COPY scripts/*.sh ./scripts/
RUN chmod +x ./scripts/*.sh

# crontab
COPY crontab /icebreaker
RUN (crontab -u $(whoami) -l; cat /icebreaker/crontab ) | crontab -u $(whoami) -
RUN touch /icebreaker/cron.log
RUN rm /icebreaker/crontab

# Nginx configuration
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
COPY nginx.conf.template /icebreaker/nginx/
RUN mkdir -p /icebreaker/nginx/tmp/client_temp
RUN mkdir -p /icebreaker/nginx/tmp/proxy_temp_path
RUN mkdir -p /icebreaker/nginx/tmp/fastcgi_temp
RUN mkdir -p /icebreaker/nginx/tmp/uwsgi_temp
RUN mkdir -p /icebreaker/nginx/tmp/scgi_temp

# Create a non-root user and group to run the services
RUN addgroup -S ice && adduser -S ice -G ice

# Change the owner to the non-root user.
RUN chown -R ice:ice /icebreaker

# USER ice

ENV PORT=8080

ENTRYPOINT [ "/icebreaker/scripts/entrypoint.sh" ]