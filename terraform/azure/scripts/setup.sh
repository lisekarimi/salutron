#!/bin/bash

# terraform/azure/scripts/setup.sh
# One-time Azure setup

set -e

echo "🚀 Setting up Azure for Salutron..."

# Login to Azure
echo "🔐 Logging in to Azure..."
az login

# Set subscription (if you have multiple)
# az account set --subscription "your-subscription-id"

# Register required resource providers
echo "📦 Registering Azure resource providers..."
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.Storage

echo "⏳ Waiting for providers to register (this may take 1-2 minutes)..."
sleep 30

# Check registration status
echo ""
echo "✅ Checking registration status:"
az provider show --namespace Microsoft.App --query "registrationState" -o tsv
az provider show --namespace Microsoft.OperationalInsights --query "registrationState" -o tsv
az provider show --namespace Microsoft.ContainerRegistry --query "registrationState" -o tsv
az provider show --namespace Microsoft.Storage --query "registrationState" -o tsv

echo ""
echo "🎉 Azure setup complete! Ready for Terraform."
