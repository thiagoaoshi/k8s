O Projeto Harbor é um projeto de Registry Cloud Nativo, com código aberto e confiável que armazena, assina e analisa conteúdos. Harbor estende o projeto Opensource Docker Distribution adicionando funcionalidades, como segurança, identidade e gerenciamento. Harbor suporta funcionalidades avançadas como gerenciamento de usuários, controle de acesso, auditoria de atividades e replicação entre instâncias. Ter um repositório de imagens mais perto do ambiente de desenvolvimento e produção pode melhorar a eficiência de transferência de imagens.

## **Instalando**
1. Baixar o .gz em https://github.com/goharbor/harbor/releases
2. Descompactar

```bash
tar xzvf arquivo.gz
```
3. Adicionar os certificados key e cert na pasta /cert ou onde preferir
4. Inserir em /usr/local/share/ca-certificates/ e executar update-ca-certificates e executar systemctl restart docker
5. Dependendo da versão do docker adicionar "~/.docker/config.json"
```
{
  "insecure-registries": [
    "seuregistry1.domain.com.br:443",
    "seuregistry2.domain.com.br:443"
  ]
}
```
6. em /etc/hosts inserir o dominio a ser utilizado pelo harbor ex:registry.domain.com
7. editar o harbor.yml.tmpl para .yml as seguintes linhas:
	
```
hostname:
certificates:
harbor_admin_password:
```
8. rodar o "install.sh --with-trivy"
9. acessar console web
	criar usuario local caso não precise LDAP.
	***se precisar de autenticacao LDAP nao crie usuario local***
        testar com docker login registry.domain.com
_________________
## **Configurando LDAP**
OBS: Para logar como admin quando a opção de ldap esta marcada: /account/sign-in

Exemplo:
```
Modo de autenticação: LDAP
Primary Auth Mode: CHECK
URL LDAP: ldaps://ldapdomain.com.br
DN de busca LDAP: cn=<usuario>,ou=<OU-do-USUARIO>,dc=<seu-DC>,dc=com,dc=br
Senha de Busca LDAP:
DN Base de Busca LDAP: ou=<OU-do-USUARIO>,dc=<seu-DC>,dc=com,dc=br
Filtro LDAP: vazio
UID LDAP: sAMAccountName
Escopo LDAP: Subtree
DN Base de busca de Grupos LDAP: ou=<OU-do-USUARIO>,dc=<seu-DC>,dc=com,dc=br
Filtro de Grupo LDAP: objectclass=groupOfNames
GID de Grupo LDAP: cn
DN de Grupo ADMIN no LDAP: cn=<grupo>,ou=<OU-do-grupo>,dc=<seu-DC>,dc=com,dc=br
Filiação de Grupo LDAP: memberof
LDAP Group Search Scope: Subtree
LDAP Group Attached In Parallel: CHECK
Verificar certificado LDAP: VAZIO
```
__________
## **Troubleshootings**
deploy ou reconfigurar o harbor: `docker-compose down -v`
restart: `docker-compose up -d`

Pasta onde ficam as imagens: `/data/registry/docker/registry/v2/repositories`
