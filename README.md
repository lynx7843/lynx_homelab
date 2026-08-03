# Open Media Vault setup guide

this is a deployment reference for setting up openmediavault on repurposed consumer laptop hardware, with emphasis on system stability, flash storage preservation, and explicit hardware control.
<br/>

## Table of contents

#### Part 1 - Hardware
* [hardware overview](#hardware-overview)
* [storage topology](#storage-topology)

#### Part 2 - Base System Provisioning
* [bios initialization](#bios-initialization)
* [os installation](#os-installation)
* [network rectification](#network-rectification)
* [boot storage upgrade](#boot-storage-upgrade)

#### Part 3 - Security and System Logic
* [system hardening and plugins](#system-hardening-and-plugins)

#### Part 4 - Data Management and Services
* [storage integration](#storage-integration)
* [hot storage setup](#hot-storage-setup)
* [data migration](#data-migration)
* [mapping server shares on windows](#mapping-server-shares-on-windows)

#### Part 5 - Services
- [tailscale](#tailscale)
* [jellyfin](#jellyfin)
* [dawarich](#dawarich)
* [glance](#glance)
* [immich](#immich)
* [nextcloud](#nextcloud)
* [nginx](#nginx)
* [open webui](#open-webui)
* [vaultwarden](#vaultwarden)

#### Part 6 - Operations and Maintenance
* [sysadmin troubleshooting](#sysadmin-troubleshooting)

<br/>

## hardware overview
| Component | Detail |
|---|---|
| chassis | acer aspire es-575 |
| primary storage | 64 GB Kingstone flashdrive |
| secondary storage | two 1 TB SSD and HDD |
| power | direct ac / battery |
| network | built-in gigabit ethernet |
| boot environment | uefi |
| wi-fi module | physically removed |

> the wi-fi module is removed to eliminate interface conflicts, enforce ethernet as the sole network path and to minimize power consumption. First instance on omv was installed on a 8GB flash drive, but after installing the os, docker and jellyfin I was left with just ~700MB of free space. This is not sufficient for my requirements, thous I had to clone the os img to a 64 GB flash-drive. Old flash-drive is kept safely for redundancy.

<br/>


## storage topology

| Drive | Capacity | Final operational state | Purpose | Filesystem |
|---|---|---|---|---|
| target usb | 64 gb | connected (boot) | host os (omv) | ext4 |
| SSD | 1 tb | connected (internal sata) | hot storage — docker, databases, active projects | ext4 |
| HDD | 1 tb | connected (internal sata) | cold storage — archives, media, backups | ext4 |

> during installation, the ssd and hdd are deliberately disconnected to prevent misidentification. They are reintroduced individually in later phases — see [storage integration](#storage-integration) and [hot storage setup](#hot-storage-setup).

<br/>


## bios initialization

1. access bios via `f2` on boot.
2. navigate to **security** and set a temporary supervisor password to unlock secure boot controls.
3. navigate to **boot** and set **secure boot** to `disabled`.
4. return to **security** and clear the supervisor password by leaving both password fields blank.
5. navigate to **main** and enable **f12 boot menu**.
6. verify **sata mode** is set to `ahci`.
7. save and exit with `f10`.

<br/>

## os installation

1. trigger the boot menu with `f12` and boot the ventoy usb in uefi mode.
2. select and boot the openmediavault iso from the bootable drive.
3. if a dhcp timeout is triggered during network configuration, bypass it and apply static parameters manually:

   ```
   ip address  : 192.168.1.50
   subnet mask : 255.255.255.0
   hostname    : omv-server
   domain      : local
   ```

4. when prompted for a target disk, select the 8 gb usb. accept the uefi installation warning.
5. complete the installation. detach the boot usb before the system reboots.

<br/>

## boot storage upgrade

1. safely power down and remove the boot flash-drive from the system.
2. plug it to the main pc and open `balena etcher`.
3. click clone button and import as .img or .bin file.
4. plug in the new flash-drive and flash the os using the previously imported file.
5. to resize the new drive available space first we need to find the exact name of the boot partition, run:
   ```bash
   df -h /
   ```
6. now use Debian's visual partition manager to expand the boundary. Type this command, omitting the number at the end (e.g., if it was sdb2, just type sdb):
   ```bash
   cfdisk /dev/sdb
   ```
7. a visual terminal interface will appear. Use your keyboard arrows to highlight the partition that holds your OS.
8. if there is a swap partition between the free space and system partition we need to temporarily disable it, run in the normal terminal:
   ```bash
   swapoff -a
   ```
10. then go back to the previous interface and use the Left/Right arrows to select  **Resize** at the bottom and hit Enter.
11. It will ask for the new size. It automatically defaults to the absolute maximum available space. Just hit Enter.
12. arrow over to **Write** and hit Enter.
13. it will ask "Are you sure you want to write the partition table to disk?". Type yes and hit Enter.
14. arrow over to **Quit** and hit Enter.
> ignore the below commands if swap wasn't changed

<br/>

15. stretch the os filesystem into the new space:
    ```bash
    resize2fs /dev/sdc2
    ```
16. format the new swap partition
    ```bash
    mkswap /dev/sdc3
    ```
17. update the os map
    ```bash
    nano /etc/fstab
    ```
18. turn swap back on
    ```bash
    swapon -a
    ```

<br/>

## network rectificating

triggered if the server does not bind the configured ip address after installation.

1. log in locally using `root` credentials.
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

<br/>

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

<br/>

## storage integration

1. safely shut down the system and physically connect the 1 tb hdd via internal sata.
2. boot the system and navigate to **storage > disks** in the web gui.
3. select the 1 tb hdd, click **wipe** (quick), and confirm.
4. navigate to **storage > file systems**, create a new ext4 filesystem on the wiped hdd, and click **mount**.
5. navigate to **storage > shared folders**, create a folder named `ColdStorage`, and map it to the hdd.
6. click the **privileges** button for the folder and grant read/write access to the dedicated network user account.
7. navigate to **services > smb/cifs > settings** and enable the service.
8. navigate to **services > smb/cifs > shares**, add the `ColdStorage` folder, save, and apply all pending changes.

<br/>

## hot storage setup

1. safely shut down the server and install the 1 tb ssd.
2. boot the server and navigate to **storage > disks** to wipe the newly installed internal ssd.
3. format the ssd as ext4 under **storage > file systems** and mount it.
4. create two new shared folders:
   - `HotStorage` — active projects and files
   - `Appdata` — docker configurations
5. grant the network user read/write privileges to both folders.
6. expose `HotStorage` to the network via smb/cifs shares.

<br/>

## data migration

> if want to directly transfer from a drive formated in ntfs or having network bottlenecks due to bulk transfer.

1. connect the drive to the server via a usb 3.0 adapter.
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
   rsync -avh --progress "/mnt/windows_ssd/TV shows" "/srv/dev-disk-by-uuid-.../ColdStorage/"
   ```

6. unmount the drive once transfers are complete:

   ```bash
   umount /mnt/windows_ssd
   ```

<br/>

## mapping server shares on windows

adding the server shares directly to file explorer makes them behave like native drives on a windows pc. this is done by mapping a network drive, which assigns the share a dedicated drive letter (e.g. `z:`), making it more compatible with windows software and games than a plain network location shortcut.

1. open file explorer and click **this pc** in the left sidebar.
2. open the mapping tool:
   - windows 11: click the three horizontal dots in the top menu bar and select **map network drive**.
   - windows 10: click the **computer** tab at the top of the window, then click **map network drive**.
3. choose an available drive letter from the dropdown (e.g. `z:` for the hdd, `y:` for the ssd).
4. in the folder box, type the exact path to the share, using either the hostname or the ip address:
   - `\\omv-server.local\ColdStorage`
   - `\\omv-server.local\HotStorage`

   (if the `.local` address is unreliable on the network, substitute the server's current ip, e.g. `\\192.168.1.50\ColdStorage`.)
5. check both of these boxes:
   - **reconnect at sign-in** — reconnects the drive automatically every time the windows pc starts.
   - **connect using different credentials** — required, otherwise windows tries to authenticate with the signed-in microsoft account email instead of the server account.
6. click **finish**.
7. when the windows security prompt appears, enter the network credentials:
   - username: `user`
   - password: 
   - check **remember my credentials**.
8. click **ok**.

the server folders now appear alongside the `c:` drive under **this pc**, complete with a storage capacity bar so free space on the 1 tb drives can be monitored without logging into the web gui.

### fixing "multiple connections" errors when mapping

windows enforces a strict rule: it will not connect to the same server using two different usernames at the same time. if the server was accessed earlier in the session, windows may be holding an open background connection (e.g. a guest profile or cached credential). when the map network drive tool then tries to authenticate as `user`, windows blocks it with a multiple connections error.

**step 1: clear hidden connections**

1. open a command prompt (`cmd`).
2. disconnect any existing connection to the server:

   ```
   net use \\192.168.1.50 /delete
   ```

   if it reports "the network connection could not be found", that's fine — proceed to the next command.
3. clear all active network share connections:

   ```
   net use * /delete
   ```

   confirm with `y` when prompted.

**step 2: clear the credential cache**

1. open **credential manager** from the start menu.
2. click **windows credentials**.
3. look for any entries referencing `192.168.1.50` or `omv-server`.
4. select and **remove** any that are found.

**step 3: restart the windows networking stack (optional but recommended)**

restarting the laptop guarantees windows forgets the old connection. alternatively, restart the workstation service from a command prompt:

```
net stop workstation /y
net start workstation
```

**step 4: retry the mapping**

repeat the [mapping server shares on windows](#mapping-server-shares-on-windows) steps, ensuring **connect using different credentials** is checked. enter the `user` credentials when prompted and the connection should succeed.

<br/>

## tailscale

1. download and install the application
   ```bash
   curl -fsSL https://tailscale.com/install.sh | sh
   ```
2. spin it up
   ```bash
   tailscale up
   ```
3. login using the output link from the above command
4. after getting **success** output verify the connect using
   ```bash
   tailscale ip -4
   ```
5. test the ssh connect using the the output ip number

<br/>

## nginx

1. login to omv web dashboard and navigate to services > compose > files
2. create a file named `npm` and paste in the code from `NPM.yml`
> note: change `[SSD-UUID]` with the actual `HotStorage` drive ID

<br/>

3. save and click **up**
4. login to nginx dashboard using the default credentials:
   - email: `admin@example.com`
   - password: `changeme`
5. after logging in change the email and password

<br/>

## jellyfin

1. ensure media is split into strictly named directories (e.g. `/ColdStorage/Movies` and `/HotStorage/TV Shows`) to prevent scraper conflicts.
2. navigate to **system > omv-extras** and enable the docker repository.
3. navigate to **system > plugins** and install `openmediavault-compose`.
4. navigate to **services > compose > settings** and set the shared folder to `Appdata`.
5. navigate to **services > compose > files** and create a new file named `Jellyfin`.
6. copy and past the content at `Jellyfin.yaml`
7. map the `/config` volume to the `Appdata` path on the ssd for fast database loading.
8. map the `/data/movies` and `/data/tvshows` volumes to their respective folders.
9. click **up** to pull the `jellyfin` image and start the container.
10. access the setup wizard via `http://[SERVER_IP]:8096`.

pro tip: organize the file structure like below to to avoid meta-data mismatches or non at all
```bash
TV Shows/
└── Breaking Bad/
    └── Season 1/
        ├── Breaking Bad - S01E01.mp4
        ├── Breaking Bad - S01E02.mp4
        └── Breaking Bad - S01E03.mp4
```
<br/>
to speed up the remaining process use a tool like **powerrename** included in **powertoys** (only for windows users)

<br/>
<br/>

## dawarich 

1. run the following command to create the directories:
   ```bash
   mkdir -p /srv/dev-disk-by-uuid-1d3a96a7-14aa-4648-82ea-fb4ffec5d4c1/HotStorage/Appdata/dawarich/postgres
   mkdir -p /srv/dev-disk-by-uuid-1d3a96a7-14aa-4648-82ea-fb4ffec5d4c1/HotStorage/Appdata/dawarich/redis
   ```
2. deploy dawarich file (provided in the repository) using omv dashboard as `dawarich`
3. click `up` to pull the image and launch the stack
4. login to **duck dns** and create a new domain for dawarich
5. for the ip under the domain use tailscale ip (example: `100.104.53.16`)
6. to provide SSL certificate login to your **nginx proxy manager**
7. go to certificate > add certificate > let's encrypt via dns
8. input your **duck dns** domain created for dawarich and **duck dns** token
9. **save** and wait for the verification process to complete
10. if it crash try increasing the **propagation seconds** to 120 or 300
11. now to create proxy host, go to hosts > proxy hosts >  add proxy host
12. under the details:
    - domain name: `[dawarich domain name].duckdns.org`
    - scheme: `http`
    - forward hostname/IP: `192.168.1.50`
    - forward port: `[port set on dawarich.yml]`
    - toggle **command exploits** and **websockets support** `on`
13. under ssl tab 
    - select ssl certificate name set for dawarich
    - toggle force **SSL** and **HTTP/2 support** to `on`
14. click **save** 

<br/>

## glance

<br/>

## immich

1. run the following commands to create the infrastructure
   ```bash
   mkdir -p /srv/dev-disk-by-uuid-[YOUR ID]/HotStorage/Appdata/immich/postgres
   mkdir -p /srv/dev-disk-by-uuid-[YOUR ID]/HotStorage/Appdata/immich/model-cache
   mkdir -p /srv/dev-disk-by-uuid-[YOUR ID]/HotStorage/ImmichLibrary
   ```
2. navigate to services > compose > files
3. create a new file as immich
4. paste the code from `immich.yml`
5. click **save** and **up**
6. login to `duckdns` dashboard and allocate a new domain and point it to tailscale IP
7. open **nginx proxy manager**
8. generate a new Let's Encrypt certificate for l`ynx-photos.duckdns.org` using the DNS challenge method, just like before
9. go to hosts > proxy hosts > add proxy host
   - domain names: `[immich domain].duckdns.org`
   - scheme: `http`
   - forward hostname/ ip: `[server ip]`
   - forward port: `immich port`
   - toggle **block common exploits** and **websockets support** to **on**
10. attach your SSL certificate under the SSL tab, force SSL, and click Save
11. open immich dashboard click **Getting started** and create the master administrator account
12. to trigger the external scan navigate to **administration menu**
13. open the sidebar and click **External Libraries**
14. click **create library** and give it a name
15. under import paths click add path and type `/usr/src/app/external`
16. save the library, click the 3 dot menu next to it and select **scan new library files**

<br/>

## nextcloud

1. open omv dashboard and navigate to services > components > files
2. click create and enter `Nextcloud` for name
3. paste the code form `nextcloud.yml`
> Note: replace `[SSD-UUID]` and `[HDD-UUID]` with actual drive IDs.

<br/>

4. to setup external storage login to nextcloud dashboard
5. click profile icon and select **Apps**
6. in the left-hand menu, look for **Disabled apps** (or search for "External storage")
7. find the app called External storage support and click Enable.
8. click your profile picture again and go to **Administration settings**.
9. in the left-hand menu, under the **Administration** section, click **External storages**.
10. in the **Add storage** row, configure it exactly like this:
    - folder name: `Fast SSD Workspace`
    - external storage dropdown: Select **Local**
    - configuration: `/fast-workspace`
11. click checkmark icon to save

<br/>

## open webui

<br/>

## vaultwarden

1. navigate to services > components > files
2. create a file named `vaultwarden`
3. paste the code from `vaultwarden.yml`
4. change `SIGNUPS_ALLOWED=false` to `SIGNUPS_ALLOWED=true` under **environments**
5. save and click `**up**
6. login to **duck dns** and create a new domain for vaultwarden
7. for the ip under the domain use tailscale ip followed by port number of vaultwarden service
8. to provide SSL certificate login to your **nginx proxy manager**
9. go to certificate > add certificate > let's encrypt via dns
10. input your **duck dns** domain created for vaultwarden and **duck dns** token
11. **save** and wait for the verification process to complete
12. if it crash try increasing the **propagation seconds** to 120 or 300
13. now to create proxy host, go to hosts > proxy hosts >  add proxy host
14. under the details:
    - domain name: `[vaultwarden domain name].duckdns.org`
    - scheme: `http`
    - forward hostname/IP: `192.168.1.50`
    - forward port: `[port set on vaultwarden.yml]`
    - toggle **command exploits** and **websockets support** `on`
15. under ssl tab 
    - select ssl certificate name set for vaultwarden
    - toggle force **SSL** and **HTTP/2 support** to `on`
16. click **save**
17. test the service and signup
18. change docker file `SIGNUPS_ALLOWED` back to `false` for security

<br/>


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

**time-zone changing after installation**
if incorrect time zone is set during the os installation process use `timedatectl set-timezone Asia/[CITY]` to change it to the required timezone. also update omv dashboard time and date by navigating to **Date & Time** section and select the required time zone from the dropdown menu. finally don't forget to update docker files if they are set to different time zones different from system.

**ruby on rails application boots up crash (dawarich)**
sometimes if the server shutdowns abruptly due to power cut or docker engine shut down `server.pid` file never gets chance to clear itself and when the system restarts it thinks two identical services are running and dawarich crashes. to fix this run this simple command to delete that temporary file: `docker rm -f dawarich`

**immich initialization fail due to ghost database**
after changing immich docker file or after a critical service crash immich can leave ghost files behind which interrupts service starting procedure after a restart. to fix this run the following commands to purge the `postgres` folder and instantly recreate it, after that click up button under immich to restart the service
```bash
rm -rf /srv/dev-disk-by-uuid-1d3a96a7-14aa-4648-82ea-fb4ffec5d4c1/HotStorage/Appdata/immich/postgres
mkdir -p /srv/dev-disk-by-uuid-1d3a96a7-14aa-4648-82ea-fb4ffec5d4c1/HotStorage/Appdata/immich/postgres
```


