# Mise en place de l'environnement de dev

Structure des projets git :

```bash
.
├── nextcloud-docker-dev
├── nextcloud-plugins
└── notifications
```

Utilisez [nextcloud-docker-dev](https://github.com/juliusknorr/nextcloud-docker-dev) avec un version stable.

```bash
cd ..
git clone https://github.com/nextcloud/notifications.git
git clone https://github.com/juliusknorr/nextcloud-docker-dev.git
cd nextcloud-docker-dev
./bootstrap.sh --full-clone
cd workspace/server
git worktree add ../stable28 stable28
```
