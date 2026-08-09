# WireGuard VPN (on the Linux instance)

Ad-hoc full-tunnel VPN for personal use, not managed by CDK.

## Usage

```bash
bin/allow-my-ip.sh wireguard          # allow your current public IP through the security group on UDP 51820
wireguard/setup-server.sh             # install and configure WireGuard on the running Linux instance (idempotent, safe to re-run)
wireguard/add-client.sh <name>         # add a new client peer (e.g. mac, android) and print its config as a QR code
wireguard/add-client.sh <name> --text  # same, but print the raw config text instead of a QR code (see macOS below)
```

Scan the printed QR code with the WireGuard app on the client device to import it. Nothing is written to disk locally, and client private keys never leave the device that generates them, unless you use `--text` and redirect it to a file yourself.

### Android

1. Install the official **WireGuard** app from the Play Store.
2. Run `wireguard/add-client.sh android` and keep the terminal with the QR code visible.
3. In the app, tap **+** → **Scan from QR code**, and scan the QR code.
4. Name the tunnel and save. Toggle it on whenever you want traffic to go through the VPN.

### macOS

The official WireGuard Mac app (App Store) can't scan a QR code shown on the same screen (there's no separate device to scan with), so use `--text` mode to get the raw config instead of a QR code:

1. `mkdir -p ~/.wireguard && chmod 700 ~/.wireguard`
2. `wireguard/add-client.sh mac --text > ~/.wireguard/mac.conf` — this writes the config straight to a local file; avoid running it without the redirect, since that would print the private key to your terminal (and to shell history / any logging you have on that terminal).
3. Connect either via:
   * **Command line:** `brew install wireguard-tools`, then `sudo wg-quick up ~/.wireguard/mac.conf` to connect, `sudo wg-quick down ~/.wireguard/mac.conf` to disconnect.
   * **Official GUI app:** install from the App Store, then **Import tunnel(s) from file** and pick `~/.wireguard/mac.conf`.

`~/.wireguard/mac.conf` contains a private key — keep it out of this repo, and delete it (`rm ~/.wireguard/mac.conf`) if you no longer need that device.

To turn the VPN server off (e.g. when not travelling), run `wireguard/stop-server.sh`. Existing peers stay configured; running `wireguard/setup-server.sh` again brings it back up.

### Managing clients

* `wireguard/list-clients.sh` — list all configured peers with their internal IP and last handshake time
* `wireguard/remove-client.sh <name>` — revoke a device's access; its old QR code/config text stops working immediately, other peers are unaffected

A peer never expires on its own — once a device's public key is written into the server config it stays valid forever, regardless of how old the QR code or `.conf` file is. Use `remove-client.sh` when you no longer want a device to be able to connect.

## Scripts

 * `bin/allow-my-ip.sh wireguard [ip]` — allow an IP (default: your current public IP) through the security group on UDP 51820
 * `bin/allow-my-ip.sh wireguard --clean` — revoke all IPs previously allowed for WireGuard
 * `wireguard/setup-server.sh` — install and configure WireGuard on the running Linux instance
 * `wireguard/add-client.sh <name> [--text]` — add a new client peer and print its config as a QR code (or raw text with `--text`)
 * `wireguard/list-clients.sh` — list all configured peers with their internal IP and last handshake time
 * `wireguard/remove-client.sh <name>` — remove a client peer, revoking its access immediately
 * `wireguard/stop-server.sh` — stop and disable the WireGuard service without touching the peer configuration
