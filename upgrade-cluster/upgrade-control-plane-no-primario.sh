#!/bin/bash
# Upgrade do control plane Nó Principal.
# OBS: deve ser executado um node por vez, garantindo o estado do node, seguir para o próximo.
# Variavies globais
NODE_NAME=${1:-$HOSTNAME}
KUBEADM_VERSION="1.31.13"
KUBELET_VERSION="1.31.13"
KUBECTL_VERSION="1.31.13"
# VERSOES DOS PACOTES, tem que ser a versão base da familia !
CRIO_VERSION=v1.31
KUBERNETES_VERSION=v1.31
# VALIDACOES E AVISOS
echo -e "Antes de atualizar o kubernetes, tenha certeza que a versao a ser atualizada é compativel com a versão do CILIUM instalada! \n"
cilium version
echo -e "Matriz do CRD schema do CILIUM: https://docs.cilium.io/en/stable/network/kubernetes/compatibility \n"
echo -e "DIGITE ** CTRL + C ** para parar o script ou...\n"
read -n1 -r -p "Para continuar aperte qualquer teclaa..." key
# Iniciando upgrade
echo -e "Iniciando upgrade...\n"
# Draining control plane! Colocando node em manutencao
echo -e "> DRAIN CONTROL PLANE \e[1m${NODE_NAME}\e[0m \n"
kubectl drain ${NODE_NAME} --ignore-daemonsets --delete-emptydir-data --force
echo
# Download dos pacotes e habilitacao no apt
echo -e "Download pacotes e gpg- CRI-O - digite Y para continuar se necessario... \n"
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/stable:/${CRIO_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/stable:/${CRIO_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/cri-o.list
echo -e "Download pacotes e gpg- kubernetes - digite Y para continuar se necessario... \n"
curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
apt update

# Valide a ultima versao
apt-cache madison kubeadm

# Intalação do cri-o .. caso de erro verificar com apt-cache madison cri-o
echo -e "Instalando cri-o na ultima versao da familia" ${CRIO_VERSION}
apt-mark unhold cri-o
apt install cri-o="'${CRIO_VERSION}.*'"
apt-mark hold cri-o
# validando versão instalada
echo -e "versao instalada: \n"
crio version | grep Version:
# Upgrade KUBEADM
echo -e "> Upgrade kubeadm...\n"
# Valide a ultima versao
apt-cache madison kubeadm
echo -e "DIGITE ** CTRL + C ** para parar o script ou...\n"
read -n1 -r -p "A ultima versao apresentada é a definida na variavel ? Se sim, precione qualquer tecla para continuar..." key

apt-mark unhold kubeadm && apt-get install -y kubeadm="'${KUBEADM_VERSION}'".* && apt-mark hold kubeadm
echo  "Upgrade para versao: `kubeadm version`"
echo
# Upgrade plan
echo -e "> Checando upgrade plan...\n"
kubeadm upgrade plan "v${KUBEADM_VERSION}"
# Download das imagens antes de aplicar (diminui o tempo)
kubeadm config images pull
# Apply upgrade
echo -e "> Aplicando upgrade e ignorando automatic certificate renewal...\n"
kubeadm upgrade apply "v${KUBEADM_VERSION}" --certificate-renewal=false --yes
echo
# Upgrade KUBELET and KUBECTL
echo -e "> Upgrade kubelet and kubectl\n"
apt-mark unhold kubelet kubectl && apt-get install -y kubelet="'${KUBELET_VERSION}'"  kubectl="'${KUBECTL_VERSION}'"  && apt-mark hold kubelet kubectl
echo
# Restart kubelet
systemctl daemon-reload &&  systemctl restart kubelet
echo -e "daemon reloaded e kubelet reiniciado \n"
# Uncordon do node
echo -e "> Removendo node do modo manutencao...\n"
kubectl uncordon ${NODE_NAME}
#
echo -e "\nControl plane ${HOSTNAME} \e[32msuccessfuly\e[0m upgraded\n"
echo -e "> Validar aplicacoes ao termino do upgrade :...\n"
echo -e "> Em caso de falha do kube-apiserver, deletar o container diretamente com [crictl -rm id em caso de runtime crio] :...\n"
