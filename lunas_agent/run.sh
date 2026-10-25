#!/usr/bin/with-contenv bash
# Fetches the agent from the controller (so it always matches its version),
# enrolls once with the one-time token, then runs the agent.
set -euo pipefail

options=/data/options.json
dir=/data/agent
bin=/data/lunas-agent

opt() { jq -r --arg k "$1" '.[$k] // empty' "$options"; }

server=$(opt server)
pin=$(opt ca_sha256)
token=$(opt token)
url=$(opt download_url)
url=${url:-https://${server%:*}}

case "$(uname -m)" in
  x86_64) arch=amd64 ;;
  aarch64) arch=arm64 ;;
  *) echo "Architecture non prise en charge : $(uname -m)" >&2; exit 1 ;;
esac

echo "Téléchargement de l'agent depuis ${url%/}/downloads/lunas-agent-linux-$arch"
if curl -fsSL --retry 3 -o "$bin.new" "${url%/}/downloads/lunas-agent-linux-$arch"; then
  chmod 755 "$bin.new"
  mv "$bin.new" "$bin"
elif [ -x "$bin" ]; then
  rm -f "$bin.new"
  echo "Contrôleur injoignable : l'agent déjà téléchargé est utilisé." >&2
else
  echo "Impossible de télécharger l'agent : vérifie l'adresse du contrôleur." >&2
  exit 1
fi
"$bin" version

if [ ! -f "$dir/config.json" ]; then
  if [ -z "$token" ]; then
    echo "Agent pas encore enrôlé : colle le jeton d'enrôlement dans la configuration de l'app." >&2
    exit 1
  fi
  "$bin" enroll --server "$server" --ca-sha256 "$pin" --token "$token" --dir "$dir"
fi

# Only the recipes an HA box needs: copying /backup.
exec "$bin" run --dir "$dir" --recipes files
