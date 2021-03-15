#!/bin/sh

##
# Establish an SSH tunnel to balboa.syapse.com
# and a VNC connection through it.
#

##
# Kill open ssh tunnels to the vnc_host.
kill_ssh_tunnel() {
  echo "Checking for an open SSH tunnel..."
  ssh -S ~/.ssh/vnc-ctrl-sock -O exit "$1"
}

##
# Open a new SSH tunnel.
open_ssh_tunnel() {
  echo "Opening a new SSH tunnel..."
  ssh -M -S ~/.ssh/vnc-ctrl-sock -NfL "5901:localhost:59$2" "$1"
}

##
# Kill the remote VNC server.
kill_vnc() {
  echo "Killing the remote VNC server..."
  ssh "$1" "vncserver -kill :$2"
}

##
# Start the remote VNC server.
start_vnc() {
  echo "Starting a new remote VNC server..."
  ssh "$1" "vncserver :$2 -geometry "$3" -dpi "$4" -localhost"
}

##
# Describe what to do next.
fini() {
  echo 'VNC is running and an SSH tunnel is established.'
  echo 'You can now connect to vnc at localhost:5901'
  echo 'On macOS you can do this with `open vnc://localhost:5901`'
}

main() {
  vnc_username=$1
  vnc_display=$2
  geometry="${3:-1920x1080}"
  dpi="${4:-96}"
  vnc_host="${5:-balboa.syapse.com}"
  vnc_target="${vnc_username}@${vnc_host}"

  kill_ssh_tunnel "$vnc_target"
  kill_vnc "$vnc_target" "$vnc_display"
  open_ssh_tunnel "$vnc_target" "$vnc_display"
  start_vnc "$vnc_target" "$vnc_display" "$geometry" "$dpi"

  fini
}

main "$@"

