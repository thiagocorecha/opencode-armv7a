#!/data/data/com.termux/files/usr/bin/sh
# Instalador do OpenCode (headless) para Termux 32-bit ARM (armeabi-v7a / armv7l / armv8l)
# Uso no Termux:
#   curl -fsSL https://raw.githubusercontent.com/thiagocorecha/opencode-armv7a/main/termux/install-termux.sh | sh
set -eu

REPO="${OPENCODE_REPO:-thiagocorecha/opencode-armv7a}"
VERSION="${OPENCODE_VERSION:-2.0.31}"
DEB_NAME="opencode_${VERSION}-1_arm.deb"
DEB_URL="https://github.com/${REPO}/releases/latest/download/${DEB_NAME}"
TMP_DEB="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/${DEB_NAME}"

echo "==> Verificando ambiente Termux..."
if [ ! -d "/data/data/com.termux/files/usr" ]; then
  echo "ERRO: Este script deve ser executado dentro do Termux no Android / Android TV." >&2
  exit 1
fi

ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
echo "==> Arquitetura detectada: ${ARCH}"
if [ "$ARCH" != "arm" ]; then
  echo "AVISO: Este pacote foi compilado para Termux 32-bit ARM (arm / armeabi-v7a)."
  echo "       Sua arquitetura atual e '${ARCH}'. Continuando mesmo assim..."
fi

echo "==> Atualizando repositorios e instalando dependencias (nodejs, curl)..."
pkg update -y
pkg install -y nodejs curl

NODE_VER=$(node -v 2>/dev/null || echo "desconhecido")
echo "==> Node.js instalado: ${NODE_VER}"

echo "==> Baixando ${DEB_NAME} do GitHub Releases..."
curl -fL --progress-bar -o "$TMP_DEB" "$DEB_URL"

echo "==> Instalando ${DEB_NAME}..."
apt install -y "$TMP_DEB"
rm -f "$TMP_DEB"

echo ""
echo "============================================================"
echo " OpenCode instalado com sucesso no Termux!"
echo "============================================================"
echo ""
echo "Comandos uteis para Android TV:"
echo "  1) Evitar que a TV suspenda o Termux:"
echo "     termux-wake-lock"
echo ""
echo "  2) Definir sua chave de provedor (ex.: OpenRouter):"
echo "     export OPENROUTER_API_KEY='sua-chave-aqui'"
echo ""
echo "  3) Iniciar o servidor (acessivel pela rede local / Wi-Fi):"
echo "     OPENCODE_SERVER_PASSWORD='escolha-uma-senha' opencode serve --hostname 0.0.0.0 --port 4096"
echo ""
echo "  4) Testar a API localmente:"
echo "     curl -u opencode:escolha-uma-senha http://127.0.0.1:4096/api/info"
echo ""
