#!/bin/sh

set -eu

until rpk cluster info --brokers=redpanda:9092 >/dev/null 2>&1; do
  sleep 2
done

rpk topic create diploma.lifecycle.v1 --brokers=redpanda:9092 --partitions 3 --replicas 1 || true
rpk topic create sharelink.lifecycle.v1 --brokers=redpanda:9092 --partitions 3 --replicas 1 || true
rpk topic create gateway.dlq.v1 --brokers=redpanda:9092 --partitions 3 --replicas 1 || true
