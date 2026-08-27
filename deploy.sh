#!/usr/bin/env bash
#
# Deploy de Obras Abiertas (Salta) a un servidor por SSH/rsync.
#
# Qué hace:
#   1. Corre `grunt build` (con --force, porque los binarios viejos de
#      imagemin no andan en este sistema; solo se pierde la optimización
#      de imágenes, no la funcionalidad).
#   2. Copia a dist/ los dos archivos que el build NO genera porque están
#      en .gitignore (son específicos de esta instancia): config.js y
#      data.csv.
#   3. Sincroniza dist/ con la carpeta remota por rsync sobre ssh.
#
# Uso:
#   SSH_USER=tuusuario REMOTE_PATH=/ruta/real/a/obras ./deploy.sh
#
# Variables (todas por variable de entorno, nada se guarda en el script):
#   SSH_USER      (obligatoria) usuario ssh en el servidor
#   REMOTE_PATH   (obligatoria) carpeta destino en el servidor (la carpeta "obras")
#   SSH_HOST      IP o hostname (default: 172.17.40.173)
#   SSH_PORT      puerto ssh (default: 22)
#   SSH_KEY       ruta a clave privada (opcional; si no se usa el agente/default de ssh)
#
# Flags:
#   --dry-run     muestra qué archivos cambiarían sin copiar nada (recomendado
#                 para el primer uso, o cada vez que quieras revisar antes de subir)
#
# Ejemplos:
#   ./deploy.sh --dry-run
#   SSH_USER=seba REMOTE_PATH=/var/www/obras ./deploy.sh --dry-run
#   SSH_USER=seba REMOTE_PATH=/var/www/obras ./deploy.sh

set -euo pipefail

SSH_USER="${SSH_USER:-}"
SSH_HOST="${SSH_HOST:-172.17.40.173}"
SSH_PORT="${SSH_PORT:-22}"
REMOTE_PATH="${REMOTE_PATH:-}"
SSH_KEY="${SSH_KEY:-}"

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *)
      echo "Argumento desconocido: $arg" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$SSH_USER" || -z "$REMOTE_PATH" ]]; then
  echo "Faltan variables obligatorias. Ejemplo de uso:" >&2
  echo "  SSH_USER=tuusuario REMOTE_PATH=/ruta/real/a/obras ./deploy.sh --dry-run" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"

echo "==> Build (grunt build --force)"
(cd "$SCRIPT_DIR" && node_modules/.bin/grunt build --force)

echo "==> Copiando config.js y data.csv (no vienen del build) a dist/"
cp "$SCRIPT_DIR/app/config.js" "$DIST_DIR/config.js"
cp "$SCRIPT_DIR/app/data.csv" "$DIST_DIR/data.csv"

SSH_CMD="ssh -p $SSH_PORT"
if [[ -n "$SSH_KEY" ]]; then
  SSH_CMD="$SSH_CMD -i $SSH_KEY"
fi

RSYNC_FLAGS=(-avz --delete --exclude=".DS_Store")
if $DRY_RUN; then
  RSYNC_FLAGS+=(--dry-run)
  echo "==> Modo --dry-run: no se copia nada, solo se muestra qué cambiaría"
fi

echo "==> Creando carpeta remota si no existe"
$SSH_CMD "$SSH_USER@$SSH_HOST" "mkdir -p '$REMOTE_PATH'"

echo "==> Sincronizando $DIST_DIR/ -> $SSH_USER@$SSH_HOST:$REMOTE_PATH/"
rsync "${RSYNC_FLAGS[@]}" -e "$SSH_CMD" "$DIST_DIR/" "$SSH_USER@$SSH_HOST:$REMOTE_PATH/"

echo "==> Listo."
