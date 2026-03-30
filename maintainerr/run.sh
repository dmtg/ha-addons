#!/bin/sh

echo "A iniciar Maintainerr..."

PERSISTENT_PATH="/addon_configs/maintainerr"
APP_PATH="/opt/data"   # confirmar depois se necessário

mkdir -p $PERSISTENT_PATH

rm -rf $APP_PATH
ln -s $PERSISTENT_PATH $APP_PATH

exec /init
