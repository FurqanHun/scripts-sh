#!/usr/bin/env bash
# Purpose: Checks for and installs updates for Antigravity IDE.

if [ -f /etc/os-release ]; then
  . /etc/os-release
  if [ "$ID" != "fedora" ]; then
    echo "stfu this aint feodra"
    exit 1
  fi
else
  echo "stfu this aint feodra"
  exit 1
fi

REQUIRED_TOOLS=("rpm" "curl" "awk" "grep" "git" "dnf" "spectool" "rpkg" "tar" "gzip")
MISSING_TOOLS=()
for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    MISSING_TOOLS+=("$tool")
  fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
  echo "Error: Missing required tools: ${MISSING_TOOLS[*]}"
  echo "Please install them before running the update."
  exit 1
fi

echo "==> Checking for Antigravity IDE RPM updates..."

LOCAL_VER=$(rpm -qa --queryformat '%{VERSION}' antigravity2-ide 2>/dev/null)

if [ -z "$LOCAL_VER" ]; then
  echo "Error: Antigravity IDE is not installed via RPM on this system."
  exit 1
fi

SPEC_URL="https://raw.githubusercontent.com/jrobertogarcia/antigravity-2-fedora-installer/main/antigravity2-ide.spec"
REMOTE_VER=$(curl -s "$SPEC_URL" | grep -i "^Version:" | awk '{print $2}')

if [ -z "$REMOTE_VER" ]; then
  echo "Warning: Failed to fetch remote version. Check internet connection or GitHub repo."
  exit 1
fi

echo "Installed Version : $LOCAL_VER"
echo "Latest RPM Version: $REMOTE_VER"

if [ "$LOCAL_VER" = "$REMOTE_VER" ]; then
  echo "Info: You are already on the latest RPM version ($LOCAL_VER). Nothing to download!"
else
  echo "Info: New update found ($REMOTE_VER)! Starting build & update..."

  TEMP_DIR=$(mktemp -d)
  git clone https://github.com/jrobertogarcia/antigravity-2-fedora-installer.git "$TEMP_DIR"

  ORIG_DIR=$(pwd)
  cd "$TEMP_DIR" || exit 1

  ./build-ide.sh

  ARCH=$(uname -m)
  sudo dnf upgrade -y ~/rpkg/"$ARCH"/antigravity2-ide-*.rpm

  cd "$ORIG_DIR" || cd ~
  rm -rf "$TEMP_DIR" ~/rpkg

  echo "Success: Antigravity IDE successfully updated to $REMOTE_VER!"
fi
