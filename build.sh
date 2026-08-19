#!/usr/bin/env bash
# Build script for Azure deployment

set -e

echo "Building frontend..."
cd frontend
npm install
npm run build
cd ..

# Copy the built frontend into the deployable backend package so it is included in azd deploy.
mkdir -p backend/frontend
rm -rf backend/frontend/dist
cp -R frontend/dist backend/frontend/

echo "Build complete!"
