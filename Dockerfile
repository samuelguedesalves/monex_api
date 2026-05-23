FROM hexpm/elixir:1.14.0-erlang-25.0-alpine-3.18.0

RUN apk add --no-cache build-base git inotify-tools

WORKDIR /app

ENV MIX_ENV=dev

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get

EXPOSE 4000

CMD ["mix", "phx.server"]
