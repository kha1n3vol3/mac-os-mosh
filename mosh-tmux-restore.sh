#!/bin/bash

usage() {
  printf 'Usage: %s [--tabs] [[user@]host]\n' "${0##*/}"
  printf '%s\n' '  --tabs   Open one tab per session in a new Terminal window.' \
    '           By default, each session opens in a separate window.' \
    '  Omit the host to enter it at a prompt.'
}

layout=windows
if [[ ${1-} == --tabs ]]; then
  layout=tabs
  shift
fi

case ${1-} in
  -h|--help) usage; exit 0 ;;
esac

if (( $# > 1 )); then
  usage >&2
  exit 2
fi

if (( $# == 1 )); then
  remote=$1
else
  if [[ ! -t 0 ]]; then
    usage >&2
    exit 2
  fi
  printf 'Remote IP or hostname ([user@]host): ' >&2
  IFS= read -r remote || exit 1
fi

case $remote in
  ''|-*|*[!a-zA-Z0-9_.:@%-]*)
    printf 'Enter an IP address or hostname, optionally prefixed with user@.\n' >&2
    exit 2
    ;;
esac

if ! mosh_path=$(type -P mosh); then
  printf 'Mosh is required. On macOS with Homebrew, run: brew install mosh\n' >&2
  exit 1
fi

if ! command -v osascript >/dev/null; then
  printf 'This script requires macOS Terminal.app and osascript.\n' >&2
  exit 1
fi

if ! sessions=$(ssh -T -- "$remote" 'tmux list-sessions -F "#{session_id}"'); then
  printf 'Could not list tmux sessions on %s.\n' "$remote" >&2
  exit 1
fi

if [[ -z $sessions ]]; then
  printf 'No tmux sessions found on %s.\n' "$remote"
  exit 0
fi

session_ids=()
while IFS= read -r session_id; do
  if [[ ! $session_id =~ ^\$[0-9]+$ ]]; then
    printf 'Expected tmux session IDs only. Check for output from the remote shell startup files.\n' >&2
    exit 1
  fi
  session_ids+=("$session_id")
done <<< "$sessions"

osascript - "$layout" "$mosh_path" "$remote" "${session_ids[@]}" >/dev/null <<'APPLESCRIPT'
on run argv
  set useTabs to (item 1 of argv is "tabs")
  set moshPath to quoted form of (item 2 of argv)
  set remoteHost to quoted form of (item 3 of argv)
  set commandPrefix to moshPath & " -- " & remoteHost & " tmux attach-session -t "
  set restoreWindowID to missing value

  repeat with sessionID in (items 4 thru -1 of argv)
    set attachCommand to commandPrefix & (quoted form of (contents of sessionID))
    if restoreWindowID is missing value then
      tell application "Terminal"
        set openedTab to do script attachCommand
        if useTabs then
          activate
          if (tty of openedTab) is not (tty of selected tab of front window) then
            error "Could not identify the new Terminal window."
          end if
          set restoreWindowID to id of front window
        end if
      end tell
    else
      runInNewTab(restoreWindowID, attachCommand)
    end if
  end repeat

  tell application "Terminal" to activate
end run

on runInNewTab(restoreWindowID, attachCommand)
  tell application "Terminal"
    if (id of front window) is not restoreWindowID then
      error "Keep the restore window in front while tabs are opening."
    end if
    set restoreWindow to window id restoreWindowID
    set knownTTYs to tty of every tab of restoreWindow
  end tell

  tell application "System Events" to tell process "Terminal"
    if not frontmost then error "Keep Terminal in front while tabs are opening."
    keystroke "t" using command down
  end tell

  -- Wait for the new tab's TTY before sending the attach command.
  tell application "Terminal"
    repeat 50 times
      set newTTY to tty of selected tab of restoreWindow
      if newTTY is not "" and newTTY is not in knownTTYs then
        do script attachCommand in (first tab of restoreWindow whose tty is newTTY)
        return
      end if
      delay 0.1
    end repeat
  end tell
  error "Terminal did not open a new tab in the restore window."
end runInNewTab
APPLESCRIPT
