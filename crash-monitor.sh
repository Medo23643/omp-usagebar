#!/usr/bin/env bash
# ==============================================================================
# Omarchy Crash Sentinel — Universal System-Wide "Fix with AI" Daemon
# Monitors crashes across ALL applications on Arch Linux / Omarchy in real-time
# and triggers interactive desktop notifications with 1-click OMP AI diagnostics.
# ==============================================================================

set -euo pipefail

DISABLED_FLAG="$HOME/.cache/omp-crash-sentinel-disabled"

# Check if sentinel is disabled by user in widget settings
if [ -f "$DISABLED_FLAG" ] && [ "${1:-}" != "--force" ] && [ "${2:-}" != "--force" ]; then
  if [ "${1:-}" = "--test" ]; then
    echo "Crash Sentinel is currently DISABLED in widget settings. Re-enable it in the AI Usage panel or run with '--test --force'."
  fi
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROBOT_ICON="${SCRIPT_DIR}/assets/robot-icon.svg"
[ ! -f "$ROBOT_ICON" ] && ROBOT_ICON="dialog-error"

LAUNCH_TERMINAL() {
  local prompt="$1"
  local app_name="${2:-Application}"
  local tmp_dir="/tmp/omp-crash-${app_name}-$$"
  mkdir -p "$tmp_dir"
  local prompt_file="$tmp_dir/prompt.md"
  local run_script="$tmp_dir/launch.sh"

  cat <<EOF > "$prompt_file"
$prompt
EOF

  cat <<'EOF' > "$run_script"
#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="$DIR/prompt.md"
cd "$HOME"
if [ -f "$PROMPT_FILE" ]; then
  echo "════════════════════════════════════════════════════════════════════"
  echo " 󱚣 OMP Universal Crash Sentinel — Diagnostic Session"
  echo "════════════════════════════════════════════════════════════════════"
  omp "$(cat "$PROMPT_FILE")"
  rm -rf "$DIR" 2>/dev/null || true
fi
exec bash
EOF
  chmod +x "$run_script"

  cd "$HOME" || true

  # Try standard xdg-terminal-exec first, then fallbacks
  if command -v xdg-terminal-exec >/dev/null 2>&1; then
    xdg-terminal-exec "$run_script" &
  elif command -v foot >/dev/null 2>&1; then
    foot "$run_script" &
  elif command -v kitty >/dev/null 2>&1; then
    kitty "$run_script" &
  elif command -v ghostty >/dev/null 2>&1; then
    ghostty -e "$run_script" &
  elif command -v alacritty >/dev/null 2>&1; then
    alacritty -e "$run_script" &
  else
    notify-send -u critical -i "$ROBOT_ICON" "Crash Sentinel Error" "No supported terminal emulator found to launch OMP."
  fi
}

HANDLE_CRASH() {
  # Double check disabled flag before displaying notification
  if [ -f "$DISABLED_FLAG" ] && [ "${1:-}" != "--force" ] && [ "${2:-}" != "--force" ]; then
    return 0
  fi

  local comm="$1"
  local exe="$2"
  local pid="$3"
  local signal="$4"
  local details="$5"

  # Format human-friendly signal name
  local sig_name="Crash (Signal $signal)"
  case "$signal" in
    11) sig_name="SIGSEGV (Segmentation Fault)" ;;
    6)  sig_name="SIGABRT (Aborted)" ;;
    8)  sig_name="SIGFPE (Floating Point Exception)" ;;
    4)  sig_name="SIGILL (Illegal Instruction)" ;;
    7)  sig_name="SIGBUS (Bus Error)" ;;
    9)  sig_name="SIGKILL (Killed)" ;;
    13) sig_name="SIGPIPE (Broken Pipe)" ;;
  esac

  local notif_title="Application Crashed: ${comm}"
  local notif_body="${exe} (PID ${pid}) crashed with ${sig_name}.\nClick 'Fix with AI' to analyze with OMP."

  # Dispatch notification with action button and robot icon
  # 'default' captures body click; 'fix' captures button click
  local action=""
  action=$(notify-send -u critical \
    -a "Omarchy Crash Sentinel" \
    -i "$ROBOT_ICON" \
    "$notif_title" \
    "$notif_body" \
    --action="default=Fix with AI" \
    --action="fix=Fix with AI" \
    --action="dismiss=Dismiss" 2>/dev/null || echo "")

  if [ "$action" = "fix" ] || [ "$action" = "default" ] || [ "$action" = "0" ]; then
    # Gather rich system context
    local pkg_info=""
    if [ -f "$exe" ]; then
      pkg_info=$(pacman -Qo "$exe" 2>/dev/null || echo "Custom / Local Binary ($exe)")
    else
      pkg_info="Executable: $exe"
    fi

    local recent_logs=""
    recent_logs=$(journalctl -n 12 _COMM="$comm" --no-pager 2>/dev/null || true)

    # Generate structured AI troubleshooting prompt
    local prompt
    prompt=$(cat <<EOF
# System Crash Diagnostic Report

A process crashed on this system (**Arch Linux / Omarchy**). Please analyze the root cause of this failure, check for known bugs or upstream issues, and provide step-by-step guidance or terminal commands to resolve it.

## Crash Summary
- **Application / Process:** \`${comm}\`
- **Package Info:** \`${pkg_info}\`
- **Executable Path:** \`${exe}\`
- **PID:** \`${pid}\`
- **Signal:** \`${sig_name}\`
- **Timestamp:** $(date '+%Y-%m-%d %H:%M:%S')

## Stack Trace & Coredump
\`\`\`text
${details}
\`\`\`

## Recent Application Logs (journalctl)
\`\`\`text
${recent_logs:-"No recent journal logs found for this process."}
\`\`\`

## Instructions for AI:
1. Identify which function, library, or system call triggered the crash based on the stack trace.
2. Check if this is a known issue on Arch Linux / Wayland / Hyprland (e.g. missing dependencies, graphics driver bugs, configuration corruption).
3. Explain the root cause in concise technical terms and provide actionable terminal commands or fixes to resolve it.
EOF
)

    LAUNCH_TERMINAL "$prompt" "$comm"
  fi
}

# --- CLI TEST MODE ---
if [ "${1:-}" = "--test" ]; then
  echo "Simulating crash notification test (click body or 'Fix with AI')..."
  HANDLE_CRASH "nautilus" "/usr/bin/nautilus" "213406" "11" "Stack trace of thread 213406:
#0  0x00007f990a6655aa n/a (libwayland-client.so.0 + 0x55aa)
#1  0x00007f990a665aeb wl_display_dispatch_queue_pending (libwayland-client.so.0 + 0x5aeb)
#2  0x00007f98ce688355 n/a (libvulkan_intel.so + 0x488355)
#3  0x00007f98ce6798d9 n/a (libvulkan_intel.so + 0x4798d9)
#4  0x00007f98ce282e73 n/a (libvulkan_intel.so + 0x82e73)
#5  0x00007f9909b64878 n/a (libgtk-4.so.1 + 0x564878)"
  exit 0
fi

# --- REAL-TIME MONITORING LOOP ---
echo "Starting Omarchy Universal Crash Sentinel listener..."

# Stream journalctl coredump JSON events across the entire system
exec journalctl -f -o json MESSAGE_ID=fc2e22bc6ee647b6b90729ab34a250b1 2>/dev/null | while read -r line; do
  [ -z "$line" ] && continue

  # Check disabled state on each incoming event
  [ -f "$DISABLED_FLAG" ] && continue

  # Parse JSON fields with python
  read -r comm exe pid signal details < <(python3 -c '
import sys, json
try:
    d = json.loads(sys.stdin.read())
    comm = d.get("COREDUMP_COMM", d.get("_COMM", "Unknown"))
    exe = d.get("COREDUMP_EXE", d.get("_EXE", "Unknown"))
    pid = d.get("COREDUMP_PID", d.get("_PID", "0"))
    sig = d.get("COREDUMP_SIGNAL", "Unknown")
    msg = d.get("MESSAGE", "No stack trace available.")
    
    # Avoid recursion if crash sentinel or omp itself was the process
    if "crash-monitor" in comm or "omp.usagebar" in comm:
        sys.exit(1)
        
    print(f"{comm}\t{exe}\t{pid}\t{sig}\t{msg.replace(chr(10), \"\\n\")}")
except Exception:
    sys.exit(1)
' <<< "$line" 2>/dev/null || true)

  if [ -n "${comm:-}" ] && [ "$comm" != "Unknown" ]; then
    # Unescape newlines in details
    details=$(printf '%b' "$details")
    HANDLE_CRASH "$comm" "$exe" "$pid" "$signal" "$details" &
  fi
done
