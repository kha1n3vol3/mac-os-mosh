# Restore remote tmux sessions on macOS

Open one macOS Terminal.app window for each existing tmux session on a remote server. The script lists sessions over SSH and reattaches to each by ID over Mosh.

## Requirements

- macOS with Terminal.app and the Mosh client (`brew install mosh` if you use Homebrew).
- SSH access to the server, plus `mosh-server` and `tmux` installed there. Connect as the account that owns the tmux sessions.
- Mosh must already work from your Mac to the server, including its UDP connection.

## Usage

Save `mosh-tmux-restore.sh`, then run these commands from its directory. Replace the example address and username with your own.

```bash
chmod +x mosh-tmux-restore.sh
./mosh-tmux-restore.sh user@192.0.2.10  # pass a destination
./mosh-tmux-restore.sh                  # prompt for a destination
```

The destination can be an IP address, a hostname, or an SSH config alias. Include `user@` if you need to override the default SSH username. On the first run, macOS may ask for permission to control Terminal.

Each run opens a new window per session, so rerunning can open duplicate views. To detach and leave the remote session running, press **Ctrl+b**, then **d** with the default tmux bindings.
