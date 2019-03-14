#!/usr/bin/env bash

out=$(GOOGLE_APPLICATION_CREDENTIALS=./terraform.json gcloud alpha cloud-shell ssh --command="curl http://ipv4.icanhazip.com")

printf '{"shell-address": "%s"}' "$out"