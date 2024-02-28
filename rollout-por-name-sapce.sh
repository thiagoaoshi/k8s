#!/bin/bash
# Executa rollout no cluster k8s somente para o name space definido na var NAMESPACE="your-namespace"

# Define the namespace
NAMESPACE="your-namespace"

# Get a list of deployments in the specified namespace
DEPLOYMENTS=$(kubectl get deployments -n $NAMESPACE -o=jsonpath='{.items[*].metadata.name}')

# Iterate through the deployments and trigger a rollout restart
for DEPLOYMENT in $DEPLOYMENTS; do
    echo "Rolling out restart for deployment: $DEPLOYMENT"
    kubectl rollout restart deployment $DEPLOYMENT -n $NAMESPACE
done
