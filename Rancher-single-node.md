# Configurando rancher em single node docker

Oque é o Rancher ?
é um serviço de gerenciamento de clusters kubernetes e também ambiente de virtualização, possuindo varias features para uma administração mais visual e customizavel.

Pré-requisitos:
- servidor com docker
- acesso internet (dockerhub) e (rancher.com)

Pode-se rodar o Racnher de forma básica com o comando docker run:

`docker run --privileged -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher`

Ou pode-se customizar para que o mesmo possua perssistencia e ssl proprietario:

``` yaml
docker run -d --restart=unless-stopped \
-p 80:80 -p 443:443 \
-v /home/seac/rancher/ssl/cert.pem:/etc/rancher/ssl/cert.pem \
-v /home/seac/rancher/ssl/key.pem:/etc/rancher/ssl/key.pem \
-v /home/seac/rancher/ssl/cacerts.pem:/etc/rancher/ssl/cacerts.pem \
-v /home/seac/rancher/persistente:/var/lib/rancher \
--privileged rancher/rancher
```

# Capturando a senha inicial de configuração do dashboard:
Acessar a url https://ip , com a pagina carregada solicitando a senha inicial, execute o comando no servidor docker:
`docker logs <docker-id-do-container> 2>&1 | grep "Bootstrap Password:"`

A seguinte saida deve ser exibida:
`Bootstrap Password: 8xxxlbm4xl8xxpvhzbrxxxxxxp62zg8nkvgctlt7sm68s6tq`

Em posse da senha iniciar a configuração do Rancher na url.
