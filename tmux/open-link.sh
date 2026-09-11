#!/usr/bin/env bash
#
# Pick a link out of a pane and open it in the default browser.
#
# Ctrl+click works because the terminal knows where the pointer is. tmux has no
# equivalent notion of "the link under the cursor" for the keyboard, so the next
# best thing is to list every link the pane has scrolled past and let fzf narrow
# it down. Bound to prefix+u, run inside a display-popup.

set -uo pipefail

# The tmux server inherits the PATH it was started with, which for a server
# started outside a login shell will not have mise's shims on it.
PATH="$HOME/.local/share/mise/shims:$PATH"

# Normally empty: a popup is not a pane, so an untargeted capture-pane below
# already reads the pane this was opened from. The argument exists so the
# script can be pointed at a specific pane when testing it outside a popup,
# and anything that is not a pane id is ignored rather than passed through to
# fail as a target.
pane=${1:-}
case $pane in
  %[0-9]*) ;;
  *) pane='' ;;
esac
scrollback=${2:-5000}

capture() {
  # -J rejoins wrapped lines, without which any URL long enough to hit the
  # right edge is silently cut in half.
  tmux capture-pane -p -J -S "-$scrollback" ${pane:+-t "$pane"} "$@"
}

# Two passes. The plain one finds URLs written out on screen. The escaped one
# finds OSC 8 hyperlinks, where the URL is attached to some other text -- those
# are the ones worth having a picker for, since they cannot be read off the
# screen at all.
links=$(
  {
    capture | grep -oE '((https?|ftp|file)://|www\.)[^[:space:]<>"`]+'
    capture -e | grep -oP '\x1b]8;[^;]*;\K[^\x1b\x07]+'
  } 2>/dev/null |
    # Trailing punctuation from prose around the link. Quotes get their own
    # expressions on either side because embedding one in a single-quoted sed
    # script costs more than the repetition does.
    sed -E -e "s/'+$//" -e 's/[][(){}<>.,;:!?"`\\]+$//' -e "s/'+$//" |
    grep -v '^[[:space:]]*$' |
    # Newest first, then dedupe, so a link repeated down the scrollback keeps
    # its most recent position rather than its first.
    tac |
    awk '!seen[$0]++'
)

# Note on a limit worth knowing about: zsh emits a real newline when a line you
# are typing outgrows the terminal rather than letting it wrap, so -J cannot
# rejoin it. A URL longer than the pane is wide that you typed yourself will
# therefore appear cut off. Output printed by a program wraps properly and
# rejoins fine, which is the case this is actually for. Filtering the cut-off
# halves out was tried and reverted: it cannot recover a URL whose whole self
# was never on screen, and it would sometimes drop the clean copy of a link in
# favour of one that had picked up trailing junk.

if [ -z "$links" ]; then
  printf 'No links in the last %s lines of this pane.\n' "$scrollback"
  sleep 1.5
  exit 0
fi

# --no-sort keeps the newest-first order above; fzf would otherwise reorder by
# its own match score and bury the link you just saw scroll by.
choice=$(printf '%s\n' "$links" | fzf --no-sort --reverse --height=100% \
  --prompt='open > ' --header='enter opens in the default browser') || exit 0
[ -n "$choice" ] || exit 0

# A bare www.example.com has no scheme for the browser to dispatch on.
case $choice in
  www.*) choice="https://$choice" ;;
esac

if command -v wslview >/dev/null 2>&1; then
  wslview "$choice" >/dev/null 2>&1
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$choice" >/dev/null 2>&1
else
  printf 'No URL opener found (wanted wslview or xdg-open).\n'
  sleep 2
  exit 1
fi
