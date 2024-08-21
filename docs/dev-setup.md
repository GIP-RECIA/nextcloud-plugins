# Mise en place de l'environnement de dev

Structure des projets git :

```bash
.
├── nextcloud-docker-dev
└── nextcloud-plugins
```

Utilisez [nextcloud-docker-dev](https://github.com/juliushaertl/nextcloud-docker-dev) avec un version stable.

```bash
cd ..
git clone https://github.com/juliushaertl/nextcloud-docker-dev
cd nextcloud-docker-dev
./bootstrap.sh --full-clone
cd workspace/server
git worktree add ../stable28 stable28
```
