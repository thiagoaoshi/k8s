#!/bin/bash

### Esse script mostra os serviços que estão criados mas não tem pods associados no endpoint slice
### Script feito para manutenção no cluster

IGNORAR_NAMESPACES=("cattle-fleet-system" "cattle-impersonation-system" "cattle-ui-plugin-system" "cilium-secrets" "default" "haproxy-controller" "kube-node-lease" "kube-public" "kube-system" "local" "local-path-storage" "longhorn-system")

# Converte a lista em expressão jq
filtro_jq=$(printf 'select(.namespace != "%s") | ' "${IGNORAR_NAMESPACES[@]}")
filtro_jq="${filtro_jq::-2}"  # remove o último ' | '

SERVICES_WITHOUT_ENDPOINTS=$(kubectl get endpoints --all-namespaces -o json | jq -r ".items[] | { namespace: .metadata.namespace, name: .metadata.name, addresses: ([.subsets[]?.addresses[]?] | length)} | $filtro_jq | select(.addresses == 0) | \"\(.namespace)/\(.name)\"")

# Transforma em array para preservar quebras de linha corretamente
readarray -t svc_array <<< "$SERVICES_WITHOUT_ENDPOINTS"

# Exibe os resultados
echo "Services sem pods (ignorando namespaces: ${IGNORAR_NAMESPACES[*]}):"

# Lê linha por linha
echo "Apagando services sem pods associados..."
for svc in "${svc_array[@]}"; do
    # valor do svc: namespace/nome-do-servico
    # as duas linhas seguintes extraem o namespace e o nome do service para que seja executado o kubectl delete $service_name -n $namespace
    namespace=$(cut -d/ -f1 <<< "$svc")
    service_name=$(cut -d/ -f2 <<< "$svc")
  
    echo "🔴 Deletando service específico: $namespace $service_name" 
    kubectl delete service "$service_name" -n "$namespace"
done
