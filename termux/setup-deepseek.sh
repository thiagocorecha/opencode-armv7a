#!/data/data/com.termux/files/usr/bin/sh
# Configura o OpenCode no Termux (Android / Android TV) para usar a API oficial do DeepSeek diretamente.
#
# Uso no Termux:
#   DEEPSEEK_API_KEY='sk-sua-chave' OPENCODE_SERVER_PASSWORD='sua-senha' \
#     sh -c "$(curl -fsSL https://raw.githubusercontent.com/thiagocorecha/opencode-armv7a/main/termux/setup-deepseek.sh)"
set -eu

REPO="${OPENCODE_REPO:-thiagocorecha/opencode-armv7a}"
MODEL="${DEEPSEEK_MODEL:-deepseek/deepseek-chat}"
PORT="${OPENCODE_PORT:-4096}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
CONFIG_FILE="$CONFIG_DIR/opencode.json"
ENV_FILE="$CONFIG_DIR/env"
LAUNCHER="$PREFIX/bin/opencode-tv"

if [ ! -d "/data/data/com.termux/files/usr" ]; then
  echo "ERRO: Execute este script dentro do Termux no Android / Android TV." >&2
  exit 1
fi

if ! command -v opencode >/dev/null 2>&1; then
  echo "==> OpenCode nao encontrado. Instalando o pacote .deb primeiro..."
  curl -fsSL "https://raw.githubusercontent.com/${REPO}/main/termux/install-termux.sh" | sh
fi

if [ -z "${DEEPSEEK_API_KEY:-}" ]; then
  if [ -t 0 ]; then
    printf "Cole sua DEEPSEEK_API_KEY (ex: sk-...): "
    read -r DEEPSEEK_API_KEY
  fi
fi

if [ -z "${DEEPSEEK_API_KEY:-}" ]; then
  echo "ERRO: DEEPSEEK_API_KEY nao informada." >&2
  echo "Execute passando a chave:" >&2
  echo "  DEEPSEEK_API_KEY='sk-...' OPENCODE_SERVER_PASSWORD='sua-senha' sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/${REPO}/main/termux/setup-deepseek.sh)\"" >&2
  exit 1
fi

if [ -z "${OPENCODE_SERVER_PASSWORD:-}" ]; then
  if [ -t 0 ]; then
    printf "Escolha uma senha para o servidor OpenCode [padrao: opencode123]: "
    read -r OPENCODE_SERVER_PASSWORD
  fi
  OPENCODE_SERVER_PASSWORD="${OPENCODE_SERVER_PASSWORD:-opencode123}"
fi

mkdir -p "$CONFIG_DIR"

# Salva variaveis de ambiente com permissao restrita (apenas usuario atual)
sq() { printf '%s' "$1" | sed "s/'/'\\\\''/g"; }
(
  umask 077
  cat > "$ENV_FILE" <<EOF
export DEEPSEEK_API_KEY='$(sq "$DEEPSEEK_API_KEY")'
export OPENCODE_SERVER_PASSWORD='$(sq "$OPENCODE_SERVER_PASSWORD")'
export OPENCODE_PORT='$(sq "$PORT")'
EOF
  chmod 600 "$ENV_FILE"
)

# Configura DeepSeek como modelo padrao do OpenCode 2.0.31 (provedor nativo)
cat > "$CONFIG_FILE" <<EOF
{
  "model": "${MODEL}"
}
EOF

# Carrega automaticamente no ~/.bashrc (sem duplicar)
BASHRC="$HOME/.bashrc"
SOURCE_LINE='[ -f "$HOME/.config/opencode/env" ] && . "$HOME/.config/opencode/env"'
touch "$BASHRC"
if ! grep -Fq "$SOURCE_LINE" "$BASHRC"; then
  printf '\n%s\n' "$SOURCE_LINE" >> "$BASHRC"
fi

# Cria comando rapido "opencode-tv" para iniciar na Android TV
cat > "$LAUNCHER" <<'LAUNCH'
#!/data/data/com.termux/files/usr/bin/sh
set -eu
ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/env"
[ -f "$ENV_FILE" ] && . "$ENV_FILE"

if command -v termux-wake-lock >/dev/null 2>&1; then
  termux-wake-lock || true
fi

PORT="${OPENCODE_PORT:-4096}"
echo "==> Iniciando OpenCode (DeepSeek) na porta ${PORT} (0.0.0.0)..."
echo "==> Para parar: Ctrl+C"
exec opencode serve --hostname 0.0.0.0 --port "$PORT" "$@"
LAUNCH
chmod 755 "$LAUNCHER"

echo ""
echo "============================================================"
echo " DeepSeek configurado no OpenCode (Android TV / Termux)!"
echo "============================================================"
echo " Config:  $CONFIG_FILE (modelo: $MODEL)"
echo " Env:     $ENV_FILE"
echo " Comando: opencode-tv"
echo ""
echo "Para iniciar o servidor agora, basta rodar:"
echo "  opencode-tv"
echo ""
echo "Para testar em outra aba do Termux (ou de outro dispositivo usando o IP da TV):"
echo "  curl -u opencode:${OPENCODE_SERVER_PASSWORD} http://127.0.0.1:${PORT}/api/info"
echo ""
echo "Para trocar para o modelo de raciocinio (DeepSeek R1 / Reasoner), edite $CONFIG_FILE:"
echo '  { "model": "deepseek/deepseek-reasoner" }'
echo ""
