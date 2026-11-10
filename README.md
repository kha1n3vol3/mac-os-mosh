# Restore remote tmux sessions on macOS
![Mosh tmux restore octopus badge](Mosh%20tmux%20restore%20octopus%20badge.jpg)

Restore existing remote tmux sessions into macOS Terminal.app. The script lists sessions over SSH and reattaches to each by ID over Mosh. Use separate windows or group the sessions as tabs in one window.

## Requirements

- macOS with Terminal.app and the Mosh client (`brew install mosh` if you use Homebrew).
- SSH access to the server, plus `mosh-server` and `tmux` installed there. Connect as the account that owns the tmux sessions.
- Mosh must already work from your Mac to the server, including its UDP connection.

## Usage

Save `mosh-tmux-restore.sh`, then run these commands from its directory. Replace the example address and username with your own.

```bash
chmod +x mosh-tmux-restore.sh
./mosh-tmux-restore.sh user@192.0.2.10         # one window per session
./mosh-tmux-restore.sh --tabs user@192.0.2.10  # one window with one tab per session
./mosh-tmux-restore.sh --tabs                  # prompt for a destination and use tabs
```

The destination can be an IP address, a hostname, or an SSH config alias. Include `user@` if you need to override the default SSH username. On the first run, macOS may ask for permission to control Terminal.

With `--tabs`, keep the new Terminal window in front while the tabs open. The script uses Command-T to create tabs. If macOS blocks the shortcut, enable Accessibility for the app you ran the script from (usually Terminal) under **System Settings → Privacy & Security → Accessibility**. If prompted, allow it to control System Events.

Rerunning can open duplicate views. To detach and leave the remote session running, press **Ctrl+b**, then **d** with the default tmux bindings.
