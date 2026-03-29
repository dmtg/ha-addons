#!/bin/sh

# criar pasta persistente se não existir
mkdir -p /share/maintainerr

# substituir /opt/data por symlink
rm -rf /opt/data
ln -s /share/maintainerr /opt/data

# arrancar app original
exec /init
