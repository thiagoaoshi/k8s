#!/bin/bash

echo "🔍 Procurando Ingress com serviços inexistentes..."

kubectl get ingress --all-namespaces -o json | jq -r '
  .items[] |
  . as $ingress |
  .spec.rules[]? |                                # ignora Ingresses sem regras
  .http.paths[]? |
  "\($ingress.metadata.namespace)\t\($ingress.metadata.name)\t\(.backend.service.name)"' |
while IFS=$'\t' read -r namespace ingress service; do
  
  if ! kubectl get svc -n "$namespace" "$service" &>/dev/null; then
    echo "⚠️  [$namespace/$ingress] aponta para serviço inexistente: $service"
    echo "🗑️  Apagando ingress..."
    kubectl delete ingress -n "$namespace" "$ingress"
  else
    echo "✅ [$namespace/$ingress] serviço $service encontrado."
  fi
done
