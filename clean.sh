#!/bin/bash
set -e

rm -rf volume
rm -rf terraform/.terraform terraform/terraform.tfstate terraform/terraform.tfstate.backup terraform/.terraform.lock.hcl terraform/.terraform.tfstate.lock.info terraform/localstack_providers_override.tf