#!/bin/bash

# ==============================================================================
# CONFIGURAÇÃO: Altere para "false" para DELETAR DE VERDADE os recursos.
# salve o arquivo como executavel chmod +x
# comando ./seus-cript.sh seu-name-space
# ==============================================================================
DRY_RUN="true"

# Validação do argumento de Namespace
TARGET_NS=$1

if [ -z "$TARGET_NS" ]; then
    echo "❌ Erro: Você precisa especificar um namespace."
    echo "Uso: $0 <nome-do-namespace>"
    exit 1
fi

# Verifica se o namespace realmente existe no cluster
if ! kubectl get namespace "$TARGET_NS" &>/dev/null; then
    echo "❌ Erro: O namespace '$TARGET_NS' não foi encontrado no cluster."
    exit 1
fi

if [ "$DRY_RUN" = "true" ]; then
    echo "======================================================================"
    echo "⚠️  MODO DRY-RUN ATIVADO. Simulando limpeza no namespace: [$TARGET_NS]"
    echo "======================================================================"
    DELETE_FLAG="--dry-run=client"
else
    echo "======================================================================"
    echo "🚨 ATENÇÃO: MODO DELEÇÃO ATIVADO! Apagando recursos em: [$TARGET_NS]"
    echo "======================================================================"
    DELETE_FLAG=""
fi

# ------------------------------------------------------------------------------
# 1. LIMPEZA DE REPLICASETS ÓRFÃOS (0 Réplicas)
# ------------------------------------------------------------------------------
echo -e "\n🔍 [ReplicaSets] Buscando no namespace '$TARGET_NS'..."
rs_list=$(kubectl get replicaset -n "$TARGET_NS" -o jsonpath='{range .items[?(@.status.replicas==0)]}{.metadata.name}{"\n"}{end}')

if [ -z "$rs_list" ]; then
    echo "✅ Nenhum ReplicaSet órfão encontrado."
else
    echo "$rs_list" | while read -r rs; do
        if [ ! -z "$rs" ]; then
            echo "-> Deletando ReplicaSet: $TARGET_NS/$rs"
            kubectl delete replicaset "$rs" -n "$TARGET_NS" $DELETE_FLAG
        fi
    done
fi

# ------------------------------------------------------------------------------
# 2. LIMPEZA DE SERVICES ÓRFÃOS (Sem Pods correspondentes ao Selector)
# ------------------------------------------------------------------------------
echo -e "\n🔍 [Services] Buscando no namespace '$TARGET_NS'..."
svcs=$(kubectl get svc -n "$TARGET_NS" -o jsonpath='{range .items[?(@.spec.selector)]}{.metadata.name}{"\n"}{end}')

if [ -z "$svcs" ]; then
    echo "✅ Nenhum Service com seletor encontrado."
else
    echo "$svcs" | while read -r svc; do
        if [ ! -z "$svc" ]; then
            # Extrai o seletor em formato chave=valor
            selector=$(kubectl get svc "$svc" -n "$TARGET_NS" -o jsonpath='{.spec.selector}' | jq -r 'to_entries | map("\(.key)=\(.value)") | join(",")' 2>/dev/null)
            
            if [ ! -z "$selector" ]; then
                # Verifica se existem pods que batem com esse seletor
                pod_count=$(kubectl get pods -n "$TARGET_NS" -l "$selector" --no-headers 2>/dev/null | wc -l)
                if [ "$pod_count" -eq 0 ]; then
                    echo "-> Deletando Service Órfão: $TARGET_NS/$svc (Nenhum pod responde ao seletor: $selector)"
                    kubectl delete svc "$svc" -n "$TARGET_NS" $DELETE_FLAG
                fi
            fi
        fi
    done
fi

# ------------------------------------------------------------------------------
# 3. LIMPEZA DE SECRETS ÓRFÃOS (Não utilizados por nenhum Pod)
# ------------------------------------------------------------------------------
echo -e "\n🔍 [Secrets] Buscando no namespace '$TARGET_NS'..."
secrets=$(kubectl get secrets -n "$TARGET_NS" --no-headers 2>/dev/null | grep -v -E "helm.sh|kubernetes.io/service-account-token" | awk '{print $1}')

if [ -z "$secrets" ]; then
    echo "✅ Nenhum Secret elegível encontrado."
else
    # Coleta todas as referências de secrets sendo usadas pelos Pods do namespace alvo
    used_secrets=$(kubectl get pods -n "$TARGET_NS" -o jsonpath='{.items[*].spec.volumes[*].secret.secretName} {.items[*].spec.containers[*].env[*].valueFrom.secretKeyRef.name} {.items[*].spec.containers[*].envFrom[*].secretRef.name}' 2>/dev/null | tr ' ' '\n' | sort -u)
    
    echo "$secrets" | while read -r secret; do
        if [ ! -z "$secret" ]; then
            # Se o secret não estiver na lista de usados pelos pods, deleta
            if ! echo "$used_secrets" | grep -qE "^${secret}$"; then
                echo "-> Deletando Secret Órfão: $TARGET_NS/$secret"
                kubectl delete secret "$secret" -n "$TARGET_NS" $DELETE_FLAG
            fi
        fi
    done
fi

echo -e "\n✨ Processo concluído para o namespace '$TARGET_NS'!"
