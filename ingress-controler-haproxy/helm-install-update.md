##### Instala deploy com helm
# OBS: caso name space ja esteja criado remover a linha --create-namespace
# OBS: validar as portas!
```bash
helm install haproxy-kubernetes-ingress haproxytech/kubernetes-ingress \
--create-namespace \
--namespace haproxy-controller \
--version 1.16.2 \
--set controller.service.nodePorts.http=32765 \
--set controller.service.nodePorts.https=32766 \
--set controller.service.nodePorts.stat=32767 \
--set controller.kind=DaemonSet \
--set controller.service.type=NodePort \
--set controller.healthzPort=1042 \
--set controller.livenessProbe.port=1042 \
--set controller.readinessProbe.port=1042 \
--set controller.startupProbe.initialDelaySeconds=120 \
-f values.yaml
```

##### Atualizar deploy com helm

```bash
helm upgrade haproxy-kubernetes-ingress \
--version 1.16.2 \
--set controller.service.nodePorts.http=32765 \
--set controller.service.nodePorts.https=32766 \
--set controller.service.nodePorts.stat=32767 \
--set controller.kind=DaemonSet \
--set controller.service.type=NodePort \
--set controller.healthzPort=1042 \
--set controller.livenessProbe.port=1042 \
--set controller.readinessProbe.port=1042 \
--set controller.startupProbe.initialDelaySeconds=120 \
-f values.yaml \
haproxytech/kubernetes-ingress --recreate-pods \
--namespace haproxy-controller
