#!/bin/bash

# ==============================================================================
# CONFIGURAÇÃO: Altere para "false" para DELETAR DE VERDADE os Ingresses órfãos.
# ==============================================================================
DRY_RUN="true"

# Permite passar um namespace específico como argumento, ou roda em todos se omitido
TARGET_NS=$1

if [ -z "$TARGET_NS" ]; then
    echo "======================================================================"
    echo "🔍 Buscando Ingresses órfãos em TODOS os namespaces..."
    echo "💡 Dica: Você pode passar um namespace como argumento: $0 <namespace>"
    echo "======================================================================"
    NS_FLAG="--all-namespaces"
else
    # Verifica se o namespace realmente existe
    if ! kubectl get namespace "$TARGET_NS" &>/dev/null; then
        echo "❌ Erro: O namespace '$TARGET_NS' não foi encontrado."
        exit 1
    fi
    echo "======================================================================"
    echo "🔍 Buscando Ingresses órfãos APENAS no namespace: [$TARGET_NS]"
    echo "======================================================================"
    NS_FLAG="-n $TARGET_NS"
fi

if [ "$DRY_RUN" = "true" ]; then
    echo "⚠️  MODO DRY-RUN ATIVADO. Nenhuma deleção real será feita."
    echo "======================================================================"
    DELETE_FLAG="--dry-run=client"
else
    echo "🚨 ATENÇÃO: MODO DELEÇÃO ATIVADO! Recursos serão removidos permanentemente."
    echo "======================================================================"
    DELETE_FLAG=""
fi

# Coleta todos os ingresses no escopo definido em formato JSON
ingress_list=$(kubectl get ingress $NS_FLAG -o json 2>/dev/null)

if [ -z "$ingress_list" ] || [ "$(echo "$ingress_list" | jq '.items | length')" -eq 0 ]; then
    echo "✅ Nenhum Ingress encontrado no escopo selecionado."
    exit 0
fi

found_orphans=0

# Itera sobre cada Ingress encontrado
echo "$ingress_list" | jq -c '.items[]' | while read -r ing; do
    ing_name=$(echo "$ing" | jq -r '.metadata.name')
    ing_ns=$(echo "$ing" | jq -r '.metadata.namespace')
    
    is_orphan=false
    reasons=()

    # 1. Verifica os Services dentro das regras HTTP (rules[].http.paths[].backend.service.name)
    services_in_rules=$(echo "$ing" | jq -r '.spec.rules[].http.paths[].backend.service.name' 2>/dev/null | sort -u)
    
    # 2. Verifica o Default Backend (caso exista)
    default_backend_svc=$(echo "$ing" | jq -r '.spec.defaultBackend.service.name' 2>/dev/null)
    
    # Consolida todos os serviços que este Ingress precisa
    all_required_services=$(echo -e "${services_in_rules}\n${default_backend_svc}" | grep -v '^null$' | grep -v '^$' | sort -u)

    if [ -z "$all_required_services" ]; then
        # Se o Ingress não tem nenhuma regra nem default backend configurado, ele está quebrado/vazio
        is_orphan=true
        reasons+=("Ingress não possui nenhuma regra de backend ou serviço configurado")
    else
        # Valida a existência de cada serviço dentro do mesmo namespace do Ingress
        while read -r svc; do
            if [ ! -z "$svc" ]; then
                if ! kubectl get svc "$svc" -n "$ing_ns" &>/dev/null; then
                    is_orphan=true
                    reasons+=("Aponta para o serviço inexistente: '$svc'")
                fi
            fi
        done <<< "$all_required_services"
    fi

    # Se foi detectado como órfão, exibe o diagnóstico e toma a ação
    if [ "$is_orphan" = true ]; then
        found_orphans=$((found_orphans + 1))
        echo "-> ❌ Ingress Órfão Detectado: $ing_ns/$ing_name"
        for reason in "${reasons[@]}"; do
            echo "   👉 Motivo: $reason"
        done
        
        # Executa a deleção ou simulação
        kubectl delete ingress "$ing_name" -n "$ing_ns" $DELETE_FLAG
        echo "------------------------------------------------------------"
    fi
done

if [ "$found_orphans" -eq 0 ]; then
    echo "✅ Todos os Ingresses analisados estão apontando para serviços válidos!"
fi

echo -e "\n✨ Processo concluído!"
