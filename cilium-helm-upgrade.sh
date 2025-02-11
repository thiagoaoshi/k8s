#!/bin/bash
# Upgrade do CILIUM com helm, executar como root.
# OBS: deve ser executado em apenas um node control plane!
# PARA ATUALIZACAO DE VERSAO VALIDAR COMPATIBILIDADE do CILIUM EM:
# https://docs.cilium.io/en/stable/network/kubernetes/compatibility/
# 1.16.3 é a versao do chart instalada inicialmente, sua versao incial seja diferente alterar!
# 1.17.0 é a versao da imagem nova a ser implantada

# backup dos valores da instalação atual para yaml
helm get values cilium --namespace=kube-system -o yaml > cilium-values.yaml

# reduzindo downtime por download de imagens do cilium
helm install cilium-preflight cilium/cilium --version 1.17.0 \
--namespace=kube-system \
--set preflight.enabled=true \
--set agent=false \
--set operator.enabled=false

# Limpando o pre-fligth criado
helm delete cilium-preflight --namespace=kube-system

# executa upgrade
helm upgrade cilium cilium/cilium --version 1.17.0 \
--namespace=kube-system \
--set upgradeCompatibility=1.16.3

echo -e "verificando status do cilium:"
cilium status
# Em caso de falhas de upgrade executar rollout
# helm history cilium --namespace=kube-system
# helm rollback cilium [REVISION] --namespace=kube-system
