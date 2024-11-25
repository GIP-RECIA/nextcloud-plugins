# Mise en place de l'environnement de dev

Utilisation de [nextcloud-docker-dev](https://github.com/juliusknorr/nextcloud-docker-dev)

**Structure des projets**

```sh
.
└── workspace
    ├── nextcloud-docker-dev
    │   └── workspace
    │       ├── server
    │       └── stable28
    ├── nextcloud-ent
    ├── nextcloud-gip
    └── notifications
```

**Initialisation des sous projets**

```sh
git clone git@github.com:GIP-RECIA/nextcloud-plugins.git
mkdir workspace
cd workspace
git worktree add nextcloud-gip master-gip
git worktree add nextcloud-ent master-ent
git clone https://github.com/nextcloud/notifications.git
git clone https://github.com/juliusknorr/nextcloud-docker-dev.git
cd nextcloud-docker-dev
./bootstrap.sh --full-clone
cd workspace/server
git worktree add ../stable28 stable28
```

**Lancer une version stable de Nextcloud**

```sh
cd workspace/nextcloud-docker-dev/workspace/stable28
git checkout v28.0.11 -b v28.0.11
docker compose up -d stable28
```
