# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Monex is a finance API that allows users to send and receive transactions. Built with Phoenix 1.6 + Elixir 1.14 / Erlang 25. All client interactions happen via GraphQL (Absinthe) — there are no REST endpoints.

## Commands

```bash
# Start dependencies (PostgreSQL + LocalStack for S3)
docker-compose up -d

# First-time setup
mix setup                        # deps.get + ecto.create + ecto.migrate + seeds

# Development
mix phx.server                   # start server on http://localhost:4000
# GraphQL playground: http://localhost:4000/graphiql
# Email preview (dev): http://localhost:4000/dev/mailbox

# Database
mix ecto.reset                   # drop + recreate + migrate + seeds
mix ecto.migrate

# Testing
mix test                         # auto-creates and migrates test DB
mix test test/path/to/file.exs   # single file
mix test test/path/to/file.exs:42  # single test by line

# Code quality
mix format
mix credo
```

## Architecture

### Layer structure

```
MonexWeb (GraphQL layer)
  Schema (Absinthe types/schema)
  Resolvers (translate GraphQL args → context calls)
  Middlewares (Authentication: checks current_user in context)
  Plugs (SetCurrentUser: populates context from Bearer token)

Monex (business logic / context layer)
  Users       — user CRUD, auth
  Operations  — transactions (Ecto.Multi for atomicity)

Monex.Repo   — single PostgreSQL repo
```

### Request flow

1. `SetCurrentUser` plug parses `Authorization: Bearer <token>` and puts `current_user` into the Absinthe context.
2. `Authentication` middleware (on protected fields) halts resolution with `{:error, :unauthenticated}` if `current_user` is absent.
3. Resolvers (`MonexWeb.Resolvers.*`) call into context modules (`Monex.Users`, `Monex.Operations`).

### GraphQL schema

Queries (all require authentication except where noted):
- `user` — current user profile
- `user_by_email(email)` — lookup user by email
- `transaction(id)` — single transaction (sender or receiver must be current user)
- `transactions_from_user(page)` — paginated list; returns `{page, transactions, quantity, next_page, previous_page}` with page size of 10

Mutations:
- `auth_user(input)` — authenticate, returns user + token (no auth required)
- `create_user(input)` — register, returns user + token (no auth required)
- `update_user(input)` — update current user profile
- `create_transaction(input)` — send funds to another user

### Authentication

`MonexWeb.AuthToken` uses `Phoenix.Token` (signed with a static salt, 24h max age). Tokens carry only `user.id`. Decoded user is fetched fresh from DB on every request.

### Transactions

`Monex.Operations.create_transaction/2` runs as an `Ecto.Multi` pipeline:
1. Verify sender has sufficient balance
2. Fetch receiver user
3. Insert transaction record
4. Debit sender balance
5. Credit receiver balance
6. Send email notification

`Monex.Operations.Worker` is an Oban worker on the `:transactions` queue — currently a stub (`IO.inspect` only), pending implementation.

### Error handling

Resolvers convert `Ecto.Changeset` errors using `MonexWeb.Helpers.TranslateErrors.call/1`, which traverses the changeset and returns a flat list of human-readable strings (e.g. `["email has already been taken"]`).

### Email

`Monex.Users.Email` sends welcome and transaction notification emails via `Monex.Mailer` (Swoosh). Templates use Phoenix.Swoosh. In dev, emails are stored locally and viewable at `/dev/mailbox`. In test, `Swoosh.Adapters.Test` is used.

### External services

LocalStack (port 4566) emulates AWS S3 in dev. Configured via `ex_aws` in `config/dev.exs`. `localstack-init.sh` runs on container start.

### Balance

Stored as integer (smallest currency unit). New users receive an initial balance of `10_000`. All transaction amounts must be positive (enforced via DB check constraint).

### Production

`Monex.Release` provides `migrate/0` for running Ecto migrations at runtime without Mix (used in the Docker release image via `Dockerfile.prod`).

## Testing

Uses `ExMachina` factories (`Monex.Factory`) with `Ecto.Adapters.SQL.Sandbox`. Tests live in `test/monex_web/schema/` and target the GraphQL layer. Oban is set to `testing: :inline` in test env.

## Credo

Max line length is 120. `ModuleDoc` check is disabled. Run `mix credo --strict` to see low-priority checks.
