# 🌐 Home Assistant Add-on: RDTCLIENT - 🚀

Welcome to the **RDTCLIENT for Home Assistant** repository! This add-on is designed to host the alldebrid client independently within your Home Assistant environment, providing easy and direct access to your Posterr.

## 🎉 Features

- **Independent Hosting**: Seamlessly runs rdtclient as a standalone service within Home Assistant.
- **Direct Access**: rdtclient is available at `http://<your-home-assistant-ip>:6500`.
- **Persistent Storage**: Configurations and data are preserved across restarts.
- **Continuous Data Sync**: Regular synchronization ensures data integrity and up-to-date backups.

## 💡 About RDTCLIENT
# Real-Debrid Torrent Client

This is a web interface to manage your torrents on Real-Debrid, AllDebrid, Premiumize TorBox or DebridLink. It supports the following features:

- Add new torrents through magnets or files
- Download all files from Real-Debrid, AllDebrid, Premiumize or TorBox to your local machine automatically
- Unpack all files when finished downloading
- Implements a fake qBittorrent API so you can hook up other applications like Sonarr, Radarr or Couchpotato.
- Built with Angular 15 and .NET 9

**You will need a Premium service at Real-Debrid, AllDebrid, Premiumize or Torbox!**

[Click here to sign up for Real-Debrid.](https://real-debrid.com/?id=1348683)

[Click here to sign up for AllDebrid.](https://alldebrid.com/?uid=2v91l)

[Click here to sign up for Premiumize.](https://www.premiumize.me/)

[Click here to sign up for TorBox.](https://torbox.app/subscription?referral=3d25018e-f30d-4c4b-a714-48c04bc76765)

[Click here to sign up for DebridLink.](https://debrid-link.fr/id/6duif)

<sub>(referal links so I can get a few free premium days)</sub>

## 🚀 Quick Start

1. **Install the Add-on**: Add this add-on to your Home Assistant instance from the add-on store.
2. **Run**: Start the add-on to get Homepage up and running on port 3000.
3. **Access**: Open your browser and navigate to `http://<your-home-assistant-ip>:3000` to access your Homepage dashboard.

Your files are safely backed up to `/share/posterr` in your Home Assistant installation. 

## 🛠 Installation

1. Open your Home Assistant Supervisor paneland go to the Add-on store.
2. Add this repository URL to your add-on store or you can click this button

    [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fdmtg%2Fha-addons)

3. Install the "RDTCLIENT" add-on.
4. Start the add-on and check the logs to ensure everything is running smoothly.
5. Access Posterr at `http://<your-home-assistant-ip>:6500`.

## Updating

Whenever there's an update to posterr you can try updating the addon by rebuilding on the addon-page in Home Assistant. However, there is no guarantee that it will work. Please open an issue if you face difficulties after upgrading.

## 📚 Documentation & Support

For more detailed setup and configuration instructions, visit [Posterr's official documentation](https://github.com/rogerfar/rdt-client/).

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/dmtg/ha-addons/issues).
