# Build application in container with go tools.
FROM golang:1.17.6 AS build

WORKDIR /app

COPY . /app

RUN cd ./cmd/bridge && GOOS=linux GOARCH=amd64 go build

# Build runtime image with built application.
# FROM alpine:3.18.3
FROM debian:bullseye-20230227-slim

RUN apt-get update \
    && apt-get install -y --force-yes --no-install-recommends apt-transport-https curl ca-certificates \
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home

COPY --from=build /app/cmd/bridge/config/ ./config/
COPY --from=build /app/cmd/bridge/bridge ./bridge

# Custom start script to pull keys from environment secrets.
COPY --from=build /app/cmd/bridge/entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
