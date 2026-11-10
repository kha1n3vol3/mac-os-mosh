#!/bin/bash

usage() {
  printf 'Usage: %s [user@]host\n       %s   # prompt for the remote host\n' "${0##*/}" "${0##*/}"
}

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

osascript - "$mosh_path" "$remote" "${session_ids[@]}" >/dev/null <<'APPLESCRIPT'
on run argv
  set moshPath to quoted form of (item 1 of argv)
  set remoteHost to quoted form of (item 2 of argv)
  set commandPrefix to moshPath & " -- " & remoteHost & " tmux attach-session -t "

  repeat with sessionID in (items 3 thru -1 of argv)
    set attachCommand to commandPrefix & quoted form of (contents of sessionID)
    tell application "Terminal" to do script attachCommand
  end repeat

  tell application "Terminal" to activate
end run
APPLESCRIPT
