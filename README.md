# Home server setup guilde

A deployment reference for setting up openmediavault on repurposed consumer laptop hardware, with emphasis on system stability, flash storage preservation, and explicit hardware control.

## Table of contents

- [hardware overview](#hardware-overview)
- [storage topology](#storage-topology)
- [bios initialization](#bios-initialization)
- [os installation](#os-installation)
- [network rectification](#network-rectification)
- [system hardening and plugins](#system-hardening-and-plugins)
- [storage integration](#storage-integration)
- [data migration](#data-migration)
- [hot storage setup](#hot-storage-setup)
- [media server deployment](#media-server-deployment)
- [sysadmin troubleshooting](#sysadmin-troubleshooting)



## hardware overview

| Component | Detail |
|---|---|
| chassis | acer aspire es-575 |
| power | direct ac only (battery depleted) |
| network | built-in gigabit ethernet (hardwired) |
| boot environment | uefi |
| wi-fi module | physically removed |

The wi-fi module is removed to eliminate interface conflicts and enforce ethernet as the sole network path.



## storage topology

| Drive | Capacity | Final operational state | Purpose | Filesystem |
|---|---|---|---|---|
| target usb | 8 gb | connected (boot) | host os (omv) | ext4 |
| primary ssd | 1 tb | connected (internal sata) | hot storage — docker, databases, active projects | ext4 |
| secondary hdd | 1 tb | connected (internal sata) | cold storage — archives, media, backups | ext4 |

> during installation, the ssd and hdd are deliberately disconnected to prevent misidentification by the installer. they are reintroduced individually in later phases — see [storage integration](#storage-integration) and [hot storage setup](#hot-storage-setup).



## bios initialization

1. access bios via `f2` on boot.
2. navigate to **security** and set a temporary supervisor password to unlock secure boot controls.
3. navigate to **boot** and set **secure boot** to `disabled`.
4. return to **security** and clear the supervisor password by leaving both password fields blank.
5. navigate to **main** and enable **f12 boot menu**.
6. verify **sata mode** is set to `ahci`.
7. save and exit with `f10`.



## os installation

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



## network rectification

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



## system hardening and plugins

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



## storage integration

1. safely shut down the system and physically connect the 1 tb hdd via internal sata.
2. boot the system and navigate to **storage > disks** in the web gui.
3. select the 1 tb hdd, click **wipe** (quick), and confirm.
4. navigate to **storage > file systems**, create a new ext4 filesystem on the wiped hdd, and click **mount**.
5. navigate to **storage > shared folders**, create a folder named `ColdStorage`, and map it to the hdd.
6. click the **privileges** button for the folder and grant read/write access to the dedicated network user account.
7. navigate to **services > smb/cifs > settings** and enable the service.
8. navigate to **services > smb/cifs > shares**, add the `ColdStorage` folder, save, and apply all pending changes.



## data migration

1. connect the existing ntfs windows ssd to the server via a usb 3.0 adapter to bypass wi-fi bottlenecks for bulk transfer.
2. ssh into the server and identify the usb drive partition:

   ```bash
   lsblk
   ```

   (e.g. `/dev/sdb2`)

3. create a temporary mount point and mount the drive:

   ```bash
   mkdir /mnt/windows_ssd
   mount /dev/sdb2 /mnt/windows_ssd
   ```

4. verify the destination path is actively mounted before transferring, to prevent dumping data onto the os flash drive:

   ```bash
   df -h /srv/dev-disk-by-uuid...
   ```

5. transfer directories explicitly, using quotes to handle spaces:

   ```bash
   rsync -avh --progress "/mnt/windows_ssd/Movies" "/srv/dev-disk-by-uuid-.../ColdStorage/"
   ```

6. unmount the drive once transfers are complete:

   ```bash
   umount /mnt/windows_ssd
   ```



## hot storage setup

1. safely shut down the server, remove the usb adapter, and install the 1 tb ssd internally via sata.
2. boot the server and navigate to **storage > disks** to wipe the newly installed internal ssd.
3. format the ssd as ext4 under **storage > file systems** and mount it.
4. create two new shared folders:
   - `HotStorage` — active projects and files
   - `Appdata` — docker configurations
5. grant the network user read/write privileges to both folders.
6. expose `HotStorage` to the network via smb/cifs shares.



## media server deployment

1. ensure media is split into strictly named directories (e.g. `/ColdStorage/Movies` and `/ColdStorage/TV Shows`) to prevent scraper conflicts.
2. navigate to **system > omv-extras** and enable the docker repository.
3. navigate to **system > plugins** and install `openmediavault-compose`.
4. navigate to **services > compose > settings** and set the shared folder to `Appdata`.
5. navigate to **services > compose > files** and create a new file named `Jellyfin`.
6. map the `/config` volume to the `Appdata` path on the ssd for fast database loading.
7. map the `/data/movies` and `/data/tvshows` volumes to their respective folders on the `ColdStorage` hdd (enclose paths with spaces in quotation marks).
8. click **up** to pull the `linuxserver/jellyfin` image and start the container.
9. access the setup wizard via `http://[SERVER_IP]:8096`.



## sysadmin troubleshooting

**system lockups / blank menus**
often caused by background apt updates. never force reboot. ssh into the server and run `tail -f /var/log/dpkg.log` to monitor update progress, or `top` to check for active apt-get processes. wait for them to finish.

**permission denied on smb shares**
folders created via ssh terminal as root will block windows smb users from dragging and dropping files. fix this by running `chmod -R 777 "/path/to/folder"` in the terminal to grant network-wide write access.

**dynamic ip changes**
if the server is unreachable via its static ip, access it via `omv-server.local` or check the router's dhcp lease. lock the server's mac address to the ip in the router's dhcp address reservation settings to prevent future shifts.

**ghost mounts**
if a hard drive disconnects, the mount path folder remains on the os drive. running rsync will fill the 8 gb os drive instantly. always use `df -h` to verify the mount path reflects the full 1 tb capacity before transferring data.

**web gui pending configuration loops**
if a forced reboot interrupts omv, run `dpkg --configure -a` and `apt-get -f install` via ssh to repair damaged packages, then restart the engine with `systemctl restart openmediavault-engined`.
