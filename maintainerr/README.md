Home Assistant Add-on: Maintainerr
"Looks and smells like Overseerr, does the opposite."

Maintainerr is a rule-based media management tool for your Plex, Jellyfin, or Emby ecosystem. It creates smart collections based on configurable rules (watched status, age, ratings, ...) and can optionally delete unwatched content to keep your library clean.

About
Maintainerr integrates with:

Plex / Jellyfin / Emby — media server
Sonarr / Radarr — to remove media files
Overseerr / Jellyseerr — to reset requests
Tautulli — for advanced watch statistics
Installation
Add the repository to Home Assistant.
Install the Maintainerr add-on.
Start the add-on.
Open the Web UI on port 6246.
Configuration
Option	Description
TZ	Timezone (e.g. Europe/Paris). Defaults to Europe/London.
env_vars	Extra environment variables passed to the container.
Available extra env vars
Variable	Default	Description
UI_PORT	6246	Change the listening port
BASE_PATH	(empty)	Serve under a URL subpath
Data
Persistent data (database, configuration) is stored in the HA addon config directory and survives add-on updates and reinstalls.

Support
Maintainerr upstream project
Addon repository issues
