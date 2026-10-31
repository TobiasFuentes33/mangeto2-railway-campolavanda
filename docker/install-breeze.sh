#!/bin/sh
set -eu
cd /var/www/html
if [ ! -f bin/magento ] || [ ! -f app/etc/env.php ]; then
  echo "Magento no parece instalado en /var/www/html" >&2
  exit 1
fi
if [ -z "${MAGENTO_PUBLIC_KEY:-}" ] || [ -z "${MAGENTO_PRIVATE_KEY:-}" ]; then
  echo "Configura MAGENTO_PUBLIC_KEY y MAGENTO_PRIVATE_KEY como variables privadas en Railway." >&2
  exit 1
fi
echo "Instalando Breeze Evolution en el volumen actual de Magento (sin respaldo)..."
export COMPOSER_ALLOW_SUPERUSER=1
export COMPOSER_AUTH="$(php -r 'echo json_encode(["http-basic"=>["repo.magento.com"=>["username"=>getenv("MAGENTO_PUBLIC_KEY"),"password"=>getenv("MAGENTO_PRIVATE_KEY")]]]);')"
composer config repositories.magento composer https://repo.magento.com
composer require 'swissup/breeze-evolution:^3.1.1' --update-with-all-dependencies --update-no-dev --prefer-dist --no-interaction
unset COMPOSER_AUTH
echo "Actualizando modulos y contenido estatico..."
php bin/magento maintenance:enable
trap 'php bin/magento maintenance:disable || true' EXIT
php bin/magento setup:upgrade
php bin/magento setup:di:compile
php bin/magento setup:static-content:deploy -f es_AR en_US
php bin/magento cache:flush
php bin/magento maintenance:disable
trap - EXIT
echo "Instalacion completada. Elegi el tema en Content > Design > Configuration."
