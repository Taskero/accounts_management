FROM elixir:alpine AS builder

ARG phoenix_subdir=.
ARG build_env=prod
ARG app_name

ENV MIX_ENV=${build_env} TERM=xterm

WORKDIR /opt/app

# not applicable for this project
# RUN apk update \
#   && apk --no-cache --update add nodejs nodejs-npm

RUN mix local.rebar --force \
  && mix local.hex --force

COPY . .
RUN mix do deps.get, compile

# not applicable for this project
# RUN cd ${phoenix_subdir}/assets \
#   && npm install \
#   && ./node_modules/webpack/bin/webpack.js --mode production \
#   && cd .. \
#   && mix phx.digest

RUN mix phx.digest
RUN mix release ${app_name}
RUN mv _build/${build_env}/rel/${app_name} /opt/release
RUN mv /opt/release/bin/${app_name} /opt/release/bin/start_server

FROM alpine:latest

RUN apk update \
  && apk --no-cache --update add\
  bash \
  ca-certificates \
  libgcc \
  libstdc++ \
  ncurses-libs \
  openssl \
  openssl-dev

RUN apk upgrade --no-cache && apk add --no-cache

EXPOSE ${PORT}

WORKDIR /opt/app
COPY --from=builder /opt/release .

CMD exec /opt/app/bin/start_server start

# Usage:
# build: docker image build -t $APP_NAME-web . --no-cache --build-arg app_name=$APP_NAME
# shell: docker container run --rm -it -p 127.0.0.1:8080:8080 --env-file scripts/deployment/.docker.prod.env $APP_NAME sh
# run:   docker container run --rm -it -p 127.0.0.1:8080:8080 --env-file scripts/deployment/.docker.prod.env $APP_NAME-web
# id:    ID=$(docker ps | grep $APP_NAME | awk '{print $1}')
# exec:  docker exec -it $ID bash
# logs:  docker container logs --follow --tail 100 $ID
# comp:  docker-compose up
