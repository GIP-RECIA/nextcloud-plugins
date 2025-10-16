# Mise en place de l'environnement de dev

Utilisation de [nextcloud-docker-dev](https://github.com/juliusknorr/nextcloud-docker-dev)

**Structure des projets**

```sh
.
└── workspace
    ├── nextcloud-docker-dev
    │   └── workspace
    │       ├── server
    │       └── stable30
    ├── nextcloud-ent
    ├── nextcloud-gip
    ├── notifications
    ├── onlyoffice-nextcloud
    └── richdocuments
```

**Initialisation des sous projets**

```sh
git clone git@github.com:GIP-RECIA/nextcloud-plugins.git
mkdir workspace
cd workspace
git worktree add nextcloud-gip master-gip
git worktree add nextcloud-ent master-ent
git clone https://github.com/nextcloud/notifications.git
git clone https://github.com/ONLYOFFICE/onlyoffice-nextcloud.git
git clone https://github.com/juliusknorr/nextcloud-docker-dev.git
git clone https://github.com/nextcloud/richdocuments.git
cd nextcloud-docker-dev
./bootstrap.sh --full-clone
cd workspace/server
git submodule update --init
git worktree add ../stable30 stable30
```

**Lancer une version stable de Nextcloud**

```sh
cd workspace/nextcloud-docker-dev/workspace/stable30
git checkout v30.0.8 -b v30.0.8
docker compose up -d stable30
```
