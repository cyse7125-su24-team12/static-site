FROM caddy:2.8.1-alpine


COPY Caddyfile /etc/caddy/Caddyfile

COPY index.html /srv/

RUN caddy fmt --overwrite /etc/caddy/Caddyfile  

# RUN caddy start --config /etc/caddy/Caddyfile

# EXPOSE 80
EXPOSE 8080
