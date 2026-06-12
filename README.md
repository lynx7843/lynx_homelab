# openmediavault home server

a deployment reference for setting up openmediavault on repurposed consumer laptop hardware, with emphasis on system stability, flash storage preservation, and explicit hardware control.



## table of contents

- [hardware overview](#hardware-overview)
- [storage topology](#storage-topology)
- [milestone a — bios initialization](#milestone-a--bios-initialization)
- [milestone b — os installation](#milestone-b--os-installation)
- [milestone c — network rectification](#milestone-c--network-rectification)
- [milestone d — system hardening and plugins](#milestone-d--system-hardening-and-plugins)
- [milestone e — storage integration](#milestone-e--storage-integration)



## hardware overview

| component | detail |
|||
| chassis | acer aspire es-575 |
| power | direct ac only (battery depleted) |
| network | built-in gigabit ethernet (hardwired) |
| boot environment | uefi |
| wi-fi module | physically removed |

the wi-fi module is removed to eliminate interface conflicts and enforce ethernet as the sole network path.



## storage topology

| drive | capacity | state during install | purpose | filesystem |
||||||
| ventoy usb | variable | connected | installation media | exfat / fat32 |
| target usb | 8 gb | connected | host os (omv) | ext4 |
| primary ssd | 1 tb | **disconnected** | hot storage — docker, databases, active projects | ext4 / btrfs |
| secondary hdd | 1 tb | **disconnected** | cold storage — archives, media, backups | ext4 |

the ssd and hdd are deliberately disconnected during installation to prevent misidentification by the installer.



## milestone a — bios initialization

1. access bios via `f2` on boot.
2. navigate to **security** and set a temporary supervisor password to unlock secure boot controls.
3. navigate to **boot** and set **secure boot** to `disabled`.
4. return to **security** and clear the supervisor password by leaving both password fields blank.
5. navigate to **main** and enable **f12 boot menu**.
6. verify **sata mode** is set to `ahci`.
7. save and exit with `f10`.



## milestone b — os installation

1. trigger the boot menu with `f12` and boot the ventoy usb in uefi mode.
2. select and boot the openmediavault iso from the ventoy menu.
3. if a dhcp timeout is triggered during network configuration, bypass it and apply static parameters manually:

   ```
   ip address  : 192.168.1.50
   subnet mask : 255.255.255.0
   hostname    : omv-server
   domain      : local
   ```

4. when prompted for a target disk, select the 8 gb usb. accept the uefi installation warning.
5. complete the installation. detach the ventoy usb before the system reboots.



## milestone c — network rectification

triggered if the server does not bind the configured ip address after installation.

1. log in locally via the tty interface using `root` credentials.
2. run `ip a` to inspect the current interface state.
3. launch the network rescue utility:

   ```bash
   omv-firstaid
   ```

4. select **configure network interface**, choose the physical ethernet adapter, then:
   - enable ipv4 (static or dhcp as appropriate)
   - disable ipv6
   - disable wake-on-lan
5. confirm the interface is bound to `192.168.1.50`.



## milestone d — system hardening and plugins

1. connect via ssh:

   ```bash
   ssh root@192.168.1.50
   ```

2. install the omv-extras repository to enable community packages and docker support:

   ```bash
   wget -O - https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install | bash
   ```

3. open the web gui at `http://192.168.1.50` in a browser.
   default credentials: `admin` / `openmediavault`

4. navigate to **system > plugins**, trigger a repository refresh, and install `openmediavault-flashmemory`.

5. apply pending configuration changes.

> **note:** the web gui will return a `500 internal server error` and drop the connection while nginx restarts to apply the plugin. this is expected. wait 60 seconds, then refresh the page.



## milestone e — storage integration

*pending next phase — drives are currently disconnected.*

1. safely shut down the system via the web gui or by running `poweroff`.
2. physically connect the 1 tb ssd and 1 tb hdd via internal sata.
3. boot the system.
4. navigate to **storage > disks** in the web gui to format and mount the drives.
5. navigate to **storage > shared folders** to configure access controls.

