#!/bin/sh

echo "A iniciar Maintainerr com persistência..."

PERSISTENT_PATH="/addon_configs/maintainerr"
APP_PATH="/opt/data"

# garantir pasta persistente
mkdir -p $PERSISTENT_PATH

# substituir /config por symlink
rm -rf $APP_PATH
ln -s $PERSISTENT_PATH $APP_PATH

# arrancar aplicação
exec /init
