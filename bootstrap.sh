#!/bin/bash
set -e

# Taint nodes labeled with app=mysql
kubectl taint nodes -l app=mysql app=mysql:NoSchedule --overwrite

# Install Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Build Helm chart dependencies
helm dependency update .infrastructure/helm-chart/todoapp

# Deploy the todoapp Helm chart (includes mysql sub-chart)
helm upgrade --install todoapp .infrastructure/helm-chart/todoapp
