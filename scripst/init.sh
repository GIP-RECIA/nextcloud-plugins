indent() {
  sed 's/^/    /'
}

indent_cli() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -l 's/^/   > /'
  else
    sed -u 's/^/   > /'
  fi
}

is_installed() {
  (
    if [ -x "$(command -v "$1")" ]; then
      echo "✅ $1 is properly installed"
    else
      echo "❌ Install $1 before running this script"
      exit 1
    fi
  ) | indent
}

clone_or_pull() {
  if [ ! -d "$1" ]; then
    (
      echo "🌏 Fetching $1"
      (git clone $2 2>&1 | indent_cli && echo "✅ $1 installed") ||
        echo "❌ Failed to install $1"
    ) | indent
  else
    (
      echo "🌏 Updating $1"
      cd $1
      (git fetch --prune 2>&1 | indent_cli)
      cd ..
    ) | indent
  fi
}

add_worktree() {
  if [ ! -d "$1" ]; then
    (
      echo "🛠️  Adding $1"
      (git worktree add $1 $2 2>&1 | indent_cli)
    ) | indent
  else
    echo "✅ $1 already exists" | indent
  fi
}

echo
echo "⏩ Performing system checks"

is_installed docker
is_installed git

DCC=
docker-compose version >/dev/null 2>/dev/null && DCC='docker-compose'
docker compose version >/dev/null 2>/dev/null && DCC='docker compose'

if [ -z "$DCC" ]; then
  echo "❌ Install docker-compose before running this script"
  exit 1
fi

(
  (docker ps 2>&1 >/dev/null && echo "✅ Docker is properly executable") ||
    (echo "❌ Cannot run docker ps, you might need to check that your user is able to use docker properly" && exit 1)
) | indent

echo
echo "⏩ Setting up folder structure and fetching repositories"
if [ ! -d "workspace" ]; then
  mkdir "workspace"
fi
cd workspace
add_worktree nextcloud-gip master-gip
add_worktree nextcloud-ent master-ent

clone_or_pull notifications https://github.com/nextcloud/notifications.git
clone_or_pull onlyoffice-nextcloud https://github.com/ONLYOFFICE/onlyoffice-nextcloud.git
clone_or_pull richdocuments https://github.com/nextcloud/richdocuments.git

clone_or_pull nextcloud-docker-dev https://github.com/juliusknorr/nextcloud-docker-dev.git
cd nextcloud-docker-dev
if [ ! "nextcloud-docker-dev/.env" ]; then
  echo
  ./bootstrap.sh --full-clone
else
  echo
  echo "⏩ Skipping nextcloud-docker-dev"
fi

echo
echo "⏩ Setting up Nextcloud's stable folder structure"
cd workspace/server
git submodule update --init 2>&1 | indent_cli
add_worktree ../stable30 stable30
add_worktree ../stable31 stable31
add_worktree ../stable32 stable32
