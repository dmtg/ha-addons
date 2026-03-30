#!/bin/sh

echo "A iniciar Maintainerr com persistência..."

# garantir pasta persistente
mkdir -p /share/maintainerr

# ligar pasta ao caminho usado pela app (ajustar se necessário)
rm -rf /opt/data
ln -s /share/maintainerr /opt/data

# arrancar processo original
exec /init
