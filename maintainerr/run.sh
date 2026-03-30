#!/bin/sh

# criar pasta persistente se não existir
mkdir -p /addon_configs/maintainerr

# substituir /opt/data por symlink
rm -rf /opt/data
ln -s /addon_configs/maintainerr /opt/data

# arrancar app original
exec /init
