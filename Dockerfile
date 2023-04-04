# syntax = docker/dockerfile:1
ARG MIX_ENV="prod"

FROM hexpm/elixir:1.14.2-erlang-25.2-debian-bullseye-20221004-slim as build

# install build dependencies
RUN --mount=type=cache,target=/var/lib/apt,sharing=locked \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y build-essential git curl npm cargo

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN --mount=type=cache,target=~/.cache/rebar3 \
  mix do \
  local.hex --force,\
  local.rebar --force

# set build ENV
ARG MIX_ENV
ENV MIX_ENV="${MIX_ENV}"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN --mount=type=cache,target=~/.hex/packages/hexpm \
  mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/$MIX_ENV.exs config/
RUN mix deps.compile

COPY priv priv
# COPY assets assets
COPY lib lib
# RUN --mount=type=cache,target=/root/.npm npm --prefix assets ci
# compile and build the release
RUN mix compile
# RUN mix assets.deploy

# changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/
# COPY rel rel
# COPY cfg_files cfg_files
RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM hexpm/elixir:1.14.2-erlang-25.2-debian-bullseye-20221004-slim as app
RUN --mount=type=cache,target=/var/lib/apt,sharing=locked \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y openssl libncurses6 ca-certificates
RUN update-ca-certificates

ARG MIX_ENV
ENV USER="elixir"

WORKDIR "/home/${USER}/app"
# Creates an unprivileged user to be used exclusively to run the Phoenix app
RUN \
  addgroup \
  --gid 1000 \
  "${USER}" \
  && adduser \
  --shell /bin/sh \
  --uid 1000 \
  --ingroup "${USER}" \
  --home "/home/${USER}" \
  "${USER}" \
  && su "${USER}"

# Everything from this line onwards will run in the context of the unprivileged user.
USER "${USER}"

COPY scripts/entrypoint.sh ./
# COPY cfg_files ./cfg_files
COPY --from=build --chown="${USER}":"${USER}" /app/_build/"${MIX_ENV}"/rel/accounts_management_api ./

ENTRYPOINT ["./entrypoint.sh"]
# Expose web (8080) and SMTP-with-STARTTLS (1587)
ENV PORT=8080
EXPOSE 8080
EXPOSE 1587

# Usage:
# build: docker image build -t accounts_management_api-web .
# shell: docker container run --rm -it --entrypoint "" -p 127.0.0.1:8080:8080  --env-file ./.docker.env accounts_management_api-web sh
# run:   docker container run --rm -it -p 127.0.0.1:8080:8080 --name accounts_management_api --env-file ./.docker.env accounts_management_api-web
# exec:  docker container exec -it accounts_management_api sh
# logs:  docker container logs --follow --tail 100 accounts_management_api
# comp:  docker-compose up

# http://localhost:8080/api/accounts
CMD ["start"]
