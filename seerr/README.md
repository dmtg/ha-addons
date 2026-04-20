Home Assistant add-on: Seerr
About
This add-on packages Seerr, an open-source media request and discovery manager for Jellyfin, Plex, and Emby.
This add-on is based on the existing Overseerr add-on structure, adapted for the Seerr upstream project and container image. It supports Home Assistant Ingress via an internal NGINX reverse proxy.
Upstream repositories reviewed:
Overseerr: https://github.com/sct/overseerr
Seerr: https://github.com/seerr-team/seerr
Installation
Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%253A%252F%252Fgithub.com%252Falexbelgium%252Fhassio-addons)
Install Seerr.
Configure options, then start the add-on.
Open the Web UI on port `5055` or via Home Assistant Ingress.
Configuration
Use `env\_vars` to pass extra environment variables when needed. Seerr configuration is stored in `/config`.
Options
Option	Type	Default	Description
`NODE\_MEMORY\_LIMIT`	int	`512`	Maximum Node.js heap memory in MB. Increase if Seerr crashes with large libraries; decrease on memory-constrained systems.
`PGID`	int	`0`	Group ID for file permissions
`PUID`	int	`0`	User ID for file permissions
`TZ`	str		Timezone (e.g. `Europe/London`)
Example
```yaml
NODE\_MEMORY\_LIMIT: 512
env\_vars: \[]
PGID: 0
PUID: 0
TZ: Europe/London
```
Migration
From Overseerr
Seerr is compatible with Overseerr's data format. To migrate your existing configuration:
Stop the Overseerr add-on.
Install and start the Seerr add-on once to create its config directory (`/addon\_configs/db21ed7f\_seerr/`), then stop it.
Open the Filebrowser add-on (or any file manager with access to `/addon\_configs/`).
Navigate to `/addon\_configs/db21ed7f\_overseerr/` and copy all files into `/addon\_configs/db21ed7f\_seerr/`.
Start the Seerr add-on. Your existing settings, users, and requests will be preserved.
---
From Jellyseerr
Seerr is compatible with Jellyseerr's data format. To migrate your existing configuration:
Stop the Jellyseerr add-on.
Install and start the Seerr add-on once to create its config directory (`/addon\_configs/db21ed7f\_seerr/`), then stop it.
Open the Filebrowser add-on (or any file manager with access to `/addon\_configs/`).
Navigate to `/addon\_configs/db21ed7f\_jellyseerr/` and copy all files into `/addon\_configs/db21ed7f\_seerr/`.
Start the Seerr add-on. Your existing settings, users, and requests will be preserved.
---
From Ombi
Ombi uses a different data format and there is no automated migration path to Seerr. You will need to configure Seerr from scratch:
Note down your Ombi configuration (media servers, users, notification settings, etc.).
Stop the Ombi add-on.
Install and start the Seerr add-on.
Use the Seerr web UI to reconnect your media server(s) and reconfigure your preferences.
---
Support
If you find a bug, open an issue in this repository.
