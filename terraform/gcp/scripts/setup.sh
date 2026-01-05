#!/bin/bash
# terraform/gcp/scripts/setup.sh
# One-time GCP project setup

PROJECT_ID="salutron"
REGION="us-central1"

echo "🚀 Setting up GCP project: $PROJECT_ID"

# Authenticate for Terraform
echo "🔐 Authenticating..."
gcloud auth application-default login

# Create project (if it doesn't exist)
if ! gcloud projects describe $PROJECT_ID &>/dev/null; then
  gcloud projects create $PROJECT_ID --name="Salutron"
  echo "✅ Project created"
else
  echo "✅ Project already exists"
fi

# Set active project
gcloud config set project $PROJECT_ID

# Set quota project for API billing
gcloud auth application-default set-quota-project $PROJECT_ID
echo "✅ Quota project set"

# Enable required APIs
echo "📦 Enabling APIs..."
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com

echo "🎉 Setup complete! Ready for Terraform."
