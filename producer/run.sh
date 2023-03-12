#!/bin/bash

#set -x

CONTAINER_NAME="localhost/kafka-producer-otlp"
CONTAINER_TAG="latest"

declare -A args
args[BOOTSTRAP_SERVERS]="192.168.244.128:9092"
args[TOPIC]="health-service-1"
args[CONSUMER_GROUP]="consumer-group-1"
args[OTEL_INSTRUMENTATION_MESSAGING_EXPERIMENTAL_RECEIVE_TELEMETRY_ENABLED]="true"

function output_args
{
  for arg in "${!args[@]}"
  do
    echo -n "-e ${arg}=${args[$arg]} "
  done
}

podman run -it \
  $(output_args) \
  "${CONTAINER_NAME}:${CONTAINER_TAG}" \
  '-Dotel.traces.exporter=otlp' \
  '-Dotel.exporter.otlp.endpoint=http://192.168.244.128:4318' \
  '-Dotel.service.name=health-services' \
  '-Dotel.exporter-otlp.protocol=http/protobuf' \
  '-Dotel.metrics.exporter=none' \
  '-Dotel.instrumentation.messaging.experimental.receive-telemetry.enabled=true' \
  '-DJAEGER_TAGS="span.kind=client"'

