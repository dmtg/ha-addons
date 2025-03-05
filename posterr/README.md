# 🌐 Home Assistant Add-on: Homepage Server 🚀

Welcome to the **Homepage Server for Home Assistant** repository! This add-on is designed to host the Homepage dashboard independently within your Home Assistant environment, providing easy and direct access to your self-hosted dashboard.

## 🎉 Features

- **Independent Hosting**: Seamlessly runs Homarr as a standalone service within Home Assistant.
- **Direct Access**: Homepage is available at `http://<your-home-assistant-ip>:3000`.
- **Persistent Storage**: Configurations and data are preserved across restarts.
- **Continuous Data Sync**: Regular synchronization ensures data integrity and up-to-date backups.

## 💡 About Homepage
g
Homepage is a versatile, self-hosted dashboard that allows you to centralize and manage access to your web services and frequently visited websites. Customize it to create a personal or home hub for easy access to all your essential online resources. Read more about Homepage [here](https://gethomepage.dev/).

## 🚀 Quick Start

1. **Install the Add-on**: Add this add-on to your Home Assistant instance from the add-on store.
2. **Run**: Start the add-on to get Homepage up and running on port 3000.
3. **Access**: Open your browser and navigate to `http://<your-home-assistant-ip>:3000` to access your Homepage dashboard.

Your files are safely backed up to `/share/homepage/configs` in your Home Assistant installation. 

## 🛠 Installation

1. Open your Home Assistant Supervisor paneland go to the Add-on store.
2. Add this repository URL to your add-on store or you can click this button

    [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fdmtg%2Fha-homepage-server)

3. Install the "Homepage Server" add-on.
4. Start the add-on and check the logs to ensure everything is running smoothly.
5. Access Homepage at `http://<your-home-assistant-ip>:3000`.

## Updating

Whenever there's an update to Homepage you can try updating the addon by rebuilding on the addon-page in Home Assistant. However, there is no guarantee that it will work. Please open an issue if you face difficulties after upgrading.

## 📚 Documentation & Support

For more detailed setup and configuration instructions, visit [Homepage's official documentation](https://gethomepage.dev/docs/about).

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/dmtg/ha-homepage-server/issues).
