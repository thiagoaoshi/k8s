#!/usr/bin/bash
# script para limpeza de imagens com crictl
crictl rmi --prune
echo "rodou o script no  cron para limpeza das imagens no host as $(date)"  >> /var/log/log_cron_limpeza-img-crictl.log
