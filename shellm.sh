#!/bin/bash
# SheLLM - AI assistant for the Linux terminal
# Copyright (c) 2026 Taylor Whitesides
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# 
# ─── SheLLM Setup ─────────────────────────────────────────────────────────────
# Supports any OpenAI-compatible API endpoint.
# Works on any Linux distribution with bash 4+.
# Uses zenity for GUI input, falls back to terminal if unavailable.
# Re-running this script will safely overwrite any previous configuration.
# ──────────────────────────────────────────────────────────────────────────────

BASHRC="$HOME/.bashrc"
MARKER="# >>> shellm config >>>"
MARKER_END="# <<< shellm config <<<"
LAUNCHER="$HOME/.local/bin/shellm-terminal"
DESKTOP="$HOME/.local/share/applications/shellm-terminal.desktop"
LOGFILE="/tmp/shellm-setup-$(date +%Y%m%d-%H%M%S).log"
BACKUP=""
USE_GUI=false
PKG_MANAGER=""
PKG_INSTALL=""
PKG_UPDATE=""

# ─── Cleanup on exit ──────────────────────────────────────────────────────────

INSTALL_COMPLETE=false
AI_FUNC="shellm"

cleanup() {
  if [[ "$INSTALL_COMPLETE" == true ]]; then
    return
  fi

  log "Cleanup triggered. Install did not complete."
  echo ""
  echo "--- Cleaning up incomplete installation ---"

  # Restore ~/.bashrc
  if [[ -n "$BACKUP" && -f "$BACKUP" ]]; then
    cp "$BACKUP" "$BASHRC"
    echo "  Restored ~/.bashrc from backup."
    log "Restored $BASHRC from $BACKUP"
  else
    # No backup yet, just strip the config block if it was partially written
    if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
      TMPFILE=$(mktemp)
      awk "/$MARKER/{found=1} !found{print} /$MARKER_END/{found=0}" "$BASHRC" > "$TMPFILE"
      mv "$TMPFILE" "$BASHRC"
      echo "  Removed partial config block from ~/.bashrc."
      log "Removed partial config block from ~/.bashrc"
    fi
  fi

  # Unset the function from the current shell session if it was loaded
  if declare -f shellm &>/dev/null; then
    unset -f shellm
    echo "  Unloaded shellm function from current session."
    log "Unloaded shellm function from shell session"
  fi

  # Remove launcher
  if [[ -f "$LAUNCHER" ]]; then
    rm -f "$LAUNCHER"
    echo "  Removed launcher: $LAUNCHER"
    log "Removed launcher: $LAUNCHER"
  fi

  # Remove desktop entry
  if [[ -f "$DESKTOP" ]]; then
    rm -f "$DESKTOP"
    echo "  Removed desktop entry: $DESKTOP"
    log "Removed desktop entry: $DESKTOP"
    if command -v update-desktop-database &>/dev/null; then
      update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
  fi

  echo ""
  echo "  Cleanup complete. Your system is back to its original state."
  echo "  Log file: $LOGFILE"
  echo ""
  log "Cleanup complete."
}

# Trap ALL exit conditions: errors, Ctrl+C, kill, normal exit
trap cleanup EXIT
trap 'exit 1' INT TERM

# ─── Logging ──────────────────────────────────────────────────────────────────

log() {
  echo "[$(date +%H:%M:%S)] $*" >> "$LOGFILE"
}

die() {
  echo ""
  echo "ERROR: $*"
  echo "Check the log for details: $LOGFILE"
  log "FATAL: $*"

  # ── Restore ~/.bashrc ──────────────────────────────────────────────────────
  if [[ -n "$BACKUP" && -f "$BACKUP" ]]; then
    cp "$BACKUP" "$BASHRC"
    echo "Restored ~/.bashrc from backup: $BACKUP"
    log "Restored $BASHRC from $BACKUP"
  fi

  # ── Remove launcher if it was created ─────────────────────────────────────
  if [[ -f "$LAUNCHER" ]]; then
    rm -f "$LAUNCHER"
    echo "Removed launcher: $LAUNCHER"
    log "Removed launcher: $LAUNCHER"
  fi

  # ── Remove desktop entry if it was created ────────────────────────────────
  if [[ -f "$DESKTOP" ]]; then
    rm -f "$DESKTOP"
    echo "Removed desktop entry: $DESKTOP"
    log "Removed desktop entry: $DESKTOP"
    if command -v update-desktop-database &>/dev/null; then
      update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
  fi

  # ── Show GUI error if available ───────────────────────────────────────────
  if [[ "$USE_GUI" == true ]] && command -v zenity &>/dev/null; then
    zenity --error \
      --title="SheLLM Setup - Error" \
      --text="ERROR: $*\n\nAll changes have been rolled back.\n\nCheck the log for details:\n$LOGFILE" \
      --width=500 2>/dev/null || true
  fi

  exit 1
}

warn() {
  echo "  WARNING: $*"
  log "WARNING: $*"
}

# ─── Trap unexpected errors ───────────────────────────────────────────────────

set -o errtrace
trap 'die "Unexpected error on line $LINENO. Exit code: $?"' ERR

# ─── Detect package manager ───────────────────────────────────────────────────

detect_pkg_manager() {
  if command -v apt-get &>/dev/null; then
    PKG_MANAGER="apt-get"
    PKG_INSTALL="sudo apt-get install -y"
    PKG_UPDATE="sudo apt-get update -qq"
  elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
    PKG_INSTALL="sudo dnf install -y"
    PKG_UPDATE="sudo dnf check-update -q; true"
  elif command -v yum &>/dev/null; then
    PKG_MANAGER="yum"
    PKG_INSTALL="sudo yum install -y"
    PKG_UPDATE="sudo yum check-update -q; true"
  elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
    PKG_INSTALL="sudo pacman -S --noconfirm"
    PKG_UPDATE="sudo pacman -Sy"
  elif command -v zypper &>/dev/null; then
    PKG_MANAGER="zypper"
    PKG_INSTALL="sudo zypper install -y"
    PKG_UPDATE="sudo zypper refresh"
  elif command -v apk &>/dev/null; then
    PKG_MANAGER="apk"
    PKG_INSTALL="sudo apk add"
    PKG_UPDATE="sudo apk update"
  elif command -v emerge &>/dev/null; then
    PKG_MANAGER="emerge"
    PKG_INSTALL="sudo emerge"
    PKG_UPDATE="sudo emerge --sync"
  else
    PKG_MANAGER=""
    PKG_INSTALL=""
    PKG_UPDATE=""
  fi
  log "Detected package manager: ${PKG_MANAGER:-none}"
}

# ─── Map package names per distro ─────────────────────────────────────────────

get_pkg_name() {
  local NAME="$1"
  case "$PKG_MANAGER" in
    pacman)
      case "$NAME" in
        python3) echo "python" ;;
        *)       echo "$NAME" ;;
      esac
      ;;
    emerge)
      case "$NAME" in
        curl)    echo "net-misc/curl" ;;
        python3) echo "dev-lang/python" ;;
        zenity)  echo "gnome-extra/zenity" ;;
        xterm)   echo "x11-terms/xterm" ;;
        *)       echo "$NAME" ;;
      esac
      ;;
    *)
      echo "$NAME"
      ;;
  esac
}

# ─── Install a single package ─────────────────────────────────────────────────

install_pkg() {
  local DEP="$1"
  local CMD="${2:-$1}"
  local PKG_NAME
  PKG_NAME=$(get_pkg_name "$DEP")
  echo "  Installing $PKG_NAME..."
  log "Installing $PKG_NAME via $PKG_MANAGER"
  eval "$PKG_INSTALL $PKG_NAME" || die "Failed to install $PKG_NAME."
  command -v "$CMD" &>/dev/null || \
    die "$CMD not found after installing $PKG_NAME. Please install it manually and re-run."
  log "Successfully installed: $PKG_NAME"
}

# ─── Sanity checks ────────────────────────────────────────────────────────────

log "Script started by ${USER:-unknown} on $(date)"

if [[ "$EUID" -eq 0 ]]; then
  die "Do not run this script as root. Run it as your normal user account."
fi

if [[ -z "${HOME:-}" || ! -d "$HOME" ]]; then
  die "HOME directory not found or not set."
fi

if [[ -z "${BASH_VERSION:-}" ]]; then
  die "This script must be run with bash. Try: bash shellm-setup.sh"
fi

BASH_MAJOR="${BASH_VERSION%%.*}"
if [[ "$BASH_MAJOR" -lt 4 ]]; then
  die "bash 4.0 or higher is required. You have bash $BASH_VERSION."
fi

if [[ ! -f "$BASHRC" ]]; then
  warn "~/.bashrc not found. Creating it."
  touch "$BASHRC" || die "Could not create $BASHRC"
fi

mkdir -p "$HOME/.local/bin" || die "Could not create $HOME/.local/bin"
mkdir -p "$HOME/.local/share/applications" || \
  warn "Could not create $HOME/.local/share/applications. Desktop entry will be skipped."

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  warn "$HOME/.local/bin is not in your PATH. Adding it to ~/.bashrc."
  echo "" >> "$BASHRC"
  echo "# Added by shellm-setup" >> "$BASHRC"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
  export PATH="$HOME/.local/bin:$PATH"
  log "Added ~/.local/bin to PATH"
fi

# ─── Backup ~/.bashrc ─────────────────────────────────────────────────────────

BACKUP="$BASHRC.shellm.bak.$(date +%Y%m%d-%H%M%S)"
cp "$BASHRC" "$BACKUP" || die "Could not back up $BASHRC"
log "Backed up $BASHRC to $BACKUP"

echo ""
echo "=== SheLLM Setup ==="
echo ""
echo "  Log file:  $LOGFILE"
echo "  Backup:    $BACKUP"
echo ""

# ─── Detect package manager ───────────────────────────────────────────────────

detect_pkg_manager

# ─── Dependency check & install ───────────────────────────────────────────────

echo "--- Checking Dependencies ---"
echo ""

MISSING=()

check_dep() {
  local NAME="$1"
  local CMD="${2:-$1}"
  if ! command -v "$CMD" &>/dev/null; then
    echo "  [ MISSING ] $NAME"
    MISSING+=("$NAME")
    log "Missing dependency: $NAME"
  else
    echo "  [   OK    ] $NAME ($(command -v "$CMD"))"
    log "Found dependency: $NAME"
  fi
}

check_dep "curl"    "curl"
check_dep "python3" "python3"
check_dep "zenity"  "zenity"

echo ""

if [[ ${#MISSING[@]} -gt 0 ]]; then
  if [[ -z "$PKG_MANAGER" ]]; then
    echo "Missing dependencies: ${MISSING[*]}"
    echo "No supported package manager found."
    echo "Please install the above manually and re-run this script."
    log "No package manager found. Cannot auto-install: ${MISSING[*]}"
    exit 1
  fi

  echo "Missing dependencies: ${MISSING[*]}"
  echo ""
  read -p "Install them now via $PKG_MANAGER? [y/N]: " INSTALL_DEPS
  if [[ "$INSTALL_DEPS" == "y" || "$INSTALL_DEPS" == "Y" ]]; then
    echo ""
    echo "Updating package index..."
    eval "$PKG_UPDATE" || warn "Package index update failed. Trying to install anyway."
    echo ""
    for DEP in "${MISSING[@]}"; do
      case "$DEP" in
        python3) install_pkg "python3" "python3" ;;
        *)       install_pkg "$DEP" "$DEP" ;;
      esac
    done
    echo ""
    echo "All dependencies installed successfully."
  else
    echo "Cannot continue without required dependencies. Exiting."
    log "User declined dependency install."
    exit 1
  fi
else
  echo "All dependencies satisfied."
fi

echo ""

# ─── Check if GUI is available ────────────────────────────────────────────────

if command -v zenity &>/dev/null && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
  USE_GUI=true
  log "GUI mode enabled."
else
  USE_GUI=false
  warn "No display server or zenity unavailable. Using terminal input."
  log "GUI mode disabled."
fi

# ─── Terminal emulator detection ──────────────────────────────────────────────

echo "--- Detecting Terminal Emulators ---"
echo ""

TERMINALS=()
TERMINAL_LABELS=()

detect_terminal() {
  local CMD="$1"
  local LABEL="$2"
  if command -v "$CMD" &>/dev/null; then
    TERMINALS+=("$CMD")
    TERMINAL_LABELS+=("$LABEL")
    echo "  [FOUND] $LABEL ($CMD)"
    log "Found terminal: $LABEL"
  fi
}

detect_terminal "terminator"     "Terminator"
detect_terminal "gnome-terminal" "GNOME Terminal"
detect_terminal "xterm"          "xterm"
detect_terminal "konsole"        "Konsole (KDE)"
detect_terminal "xfce4-terminal" "XFCE Terminal"
detect_terminal "tilix"          "Tilix"
detect_terminal "kitty"          "Kitty"
detect_terminal "alacritty"      "Alacritty"
detect_terminal "wezterm"        "WezTerm"
detect_terminal "foot"           "Foot"
detect_terminal "lxterminal"     "LXTerminal"
detect_terminal "mate-terminal"  "MATE Terminal"
detect_terminal "st"             "st (suckless)"
detect_terminal "urxvt"          "URxvt"
detect_terminal "rxvt"           "rxvt"

echo ""

if [[ ${#TERMINALS[@]} -eq 0 ]]; then
  echo "No supported terminal emulators found."
  if [[ -n "$PKG_MANAGER" ]]; then
    read -p "Install xterm (lightweight, works everywhere)? [y/N]: " INSTALL_TERM
    if [[ "$INSTALL_TERM" == "y" || "$INSTALL_TERM" == "Y" ]]; then
      eval "$PKG_UPDATE" || true
      install_pkg "xterm" "xterm"
      TERMINALS+=("xterm")
      TERMINAL_LABELS+=("xterm")
    else
      echo "Cannot continue without a terminal emulator. Exiting."
      exit 1
    fi
  else
    die "No terminal emulator found and no package manager available."
  fi
fi

# ─── Build terminal launch command ────────────────────────────────────────────

build_launch_cmd() {
  local TERM="$1"
  local TITLE="$2"
  case "$TERM" in
    # Note: kitty, alacritty, wezterm and foot do not use -e; they take the
    # command directly as trailing arguments.
    terminator)     echo "terminator --title=\"$TITLE\" -e \"bash --rcfile ~/.bashrc\"" ;;
    gnome-terminal) echo "gnome-terminal --title=\"$TITLE\" -- bash --rcfile ~/.bashrc" ;;
    xterm)          echo "xterm -title \"$TITLE\" -e \"bash --rcfile ~/.bashrc\"" ;;
    konsole)        echo "konsole --title \"$TITLE\" -e bash --rcfile ~/.bashrc" ;;
    xfce4-terminal) echo "xfce4-terminal --title=\"$TITLE\" -e \"bash --rcfile ~/.bashrc\"" ;;
    tilix)          echo "tilix --title=\"$TITLE\" -e \"bash --rcfile ~/.bashrc\"" ;;
    kitty)          echo "kitty --title \"$TITLE\" bash --rcfile ~/.bashrc" ;;
    alacritty)      echo "alacritty --title \"$TITLE\" -e bash --rcfile ~/.bashrc" ;;
    wezterm)        echo "wezterm start --window-title \"$TITLE\" --cwd ~ -- bash --rcfile ~/.bashrc" ;;
    foot)           echo "foot --title \"$TITLE\" bash --rcfile ~/.bashrc" ;;
    lxterminal)     echo "lxterminal --title=\"$TITLE\" -e \"bash --rcfile ~/.bashrc\"" ;;
    mate-terminal)  echo "mate-terminal --title=\"$TITLE\" -e \"bash --rcfile ~/.bashrc\"" ;;
    st)             echo "st -t \"$TITLE\" -e bash --rcfile ~/.bashrc" ;;
    urxvt)          echo "urxvt -title \"$TITLE\" -e bash --rcfile ~/.bashrc" ;;
    rxvt)           echo "rxvt -title \"$TITLE\" -e bash --rcfile ~/.bashrc" ;;
    *)              echo "$TERM -e \"bash --rcfile ~/.bashrc\"" ;;
  esac
}

# ─── Validation helpers ───────────────────────────────────────────────────────

is_valid_identifier() {
  local VAL
  VAL=$(printf '%s' "$1" | tr -d '[:space:]\r\n\t\000-\037\177')
  local LEN=${#VAL}
  log "Validating identifier: '$VAL' (length: $LEN, hex: $(printf '%s' "$VAL" | od -A n -t x1 | tr -d ' \n'))"

  if [[ $LEN -eq 0 ]]; then
    log "Identifier validation failed: empty after stripping whitespace"
    return 1
  fi

  # Check first character is a letter or underscore
  local FIRST="${VAL:0:1}"
  if ! printf '%s' "$FIRST" | grep -q '[a-zA-Z_]'; then
    log "Identifier validation failed: first char '$FIRST' is not a letter or underscore"
    return 1
  fi

  # Check remaining characters are letters, numbers or underscores
  local REST="${VAL:1}"
  if [[ -n "$REST" ]]; then
    if printf '%s' "$REST" | grep -q '[^a-zA-Z0-9_]'; then
      log "Identifier validation failed: '$REST' contains invalid characters"
      return 1
    fi
  fi

  log "Identifier validation passed: '$VAL'"
  return 0
}

is_valid_url() {
  echo "$1" | grep -qE '^https?://[a-zA-Z0-9._:/-]+'
}

is_valid_model() {
  echo "$1" | grep -qE '^[a-zA-Z0-9_./-]+$'
}

is_valid_api_key() {
  echo "$1" | grep -qE '^[[:graph:]]{8,}$'
}

is_valid_number() {
  local VAL="$1"
  local MIN="$2"
  local MAX="$3"
  awk -v v="$VAL" -v mn="$MIN" -v mx="$MAX" \
    'BEGIN { exit !(v ~ /^[0-9]*\.?[0-9]+$/ && v+0 >= mn+0 && v+0 <= mx+0) }' 2>/dev/null
}

is_valid_title() {
  echo "$1" | grep -qE '^[[:print:]]+$'
}

is_valid_system_prompt() {
  echo "$1" | grep -qE '^[[:print:] [:space:]]+$'
}

# ─── GUI single field prompt ──────────────────────────────────────────────────

gui_entry() {
  local TITLE="$1"
  local LABEL="$2"
  local DEFAULT="$3"
  zenity --entry \
    --title="$TITLE" \
    --text="$LABEL" \
    --entry-text="$DEFAULT" \
    --width=640 2>/dev/null
}

# ─── GUI input ────────────────────────────────────────────────────────────────

gui_collect_input() {

  # ── Step 1: Terminal selection ─────────────────────────────────────────────

  local TERM_ARGS=()
  for i in "${!TERMINALS[@]}"; do
    if [[ $i -eq 0 ]]; then
      TERM_ARGS+=("TRUE" "${TERMINALS[$i]}" "${TERMINAL_LABELS[$i]}")
    else
      TERM_ARGS+=("FALSE" "${TERMINALS[$i]}" "${TERMINAL_LABELS[$i]}")
    fi
  done

  CHOSEN_TERM=$(zenity --list \
    --title="SheLLM Setup  -  Step 1 of 4: Terminal Emulator" \
    --text="Select the terminal emulator to launch SheLLM in:" \
    --radiolist \
    --column="Select" \
    --column="Command" \
    --column="Name" \
    --width=560 \
    --height=420 \
    "${TERM_ARGS[@]}" 2>/dev/null) || die "Setup cancelled by user."

  [[ -z "$CHOSEN_TERM" ]] && die "No terminal selected."

  CHOSEN_LABEL=""
  for i in "${!TERMINALS[@]}"; do
    if [[ "${TERMINALS[$i]}" == "$CHOSEN_TERM" ]]; then
      CHOSEN_LABEL="${TERMINAL_LABELS[$i]}"
      break
    fi
  done

  log "User selected terminal: $CHOSEN_LABEL ($CHOSEN_TERM)"

  # ── Step 2: Endpoint URL ───────────────────────────────────────────────────

  while true; do
    AI_URL=$(gui_entry \
      "SheLLM Setup  -  Step 2 of 4: API Configuration" \
      "API Endpoint URL\n\nSheLLM works with any OpenAI-compatible API endpoint.\nThe URL must point to a /v1/chat/completions endpoint.\n\nExamples:\n  OpenAI:      https://api.openai.com/v1/chat/completions\n  DeepSeek:    https://api.deepseek.com/v1/chat/completions\n  OpenRouter:  https://openrouter.ai/api/v1/chat/completions\n  Groq:        https://api.groq.com/openai/v1/chat/completions\n  Ollama:      http://localhost:11434/v1/chat/completions\n  vLLM:        http://localhost:8000/v1/chat/completions\n\nNOTE: Non-OpenAI-compatible endpoints will not work.\n\nEnter your endpoint URL below:" \
      "https://") || die "Setup cancelled by user."

    AI_URL="${AI_URL#"${AI_URL%%[![:space:]]*}"}"
    AI_URL="${AI_URL%"${AI_URL##*[![:space:]]}"}"

    if is_valid_url "$AI_URL"; then
      break
    fi
    zenity --warning \
      --title="SheLLM Setup - Invalid Input" \
      --text="Invalid URL: '$AI_URL'\n\nMust start with http:// or https:// and contain only valid URL characters." \
      --width=480 2>/dev/null || true
  done

  log "Endpoint URL: $AI_URL"

  # ── Step 3: Model name ─────────────────────────────────────────────────────

  while true; do
    AI_MODEL=$(gui_entry \
      "SheLLM Setup  -  Step 2 of 4: API Configuration" \
      "Model Name\n\nExamples:\n  OpenAI:      gpt-4o\n  DeepSeek:    deepseek-reasoner\n  OpenRouter:  deepseek/deepseek-r1\n  Groq:        llama-3.3-70b-versatile\n  Local vLLM:  mistral-7b-instruct\n\nEnter your model name below:" \
      "") || die "Setup cancelled by user."

    AI_MODEL="${AI_MODEL#"${AI_MODEL%%[![:space:]]*}"}"
    AI_MODEL="${AI_MODEL%"${AI_MODEL##*[![:space:]]}"}"

    if is_valid_model "$AI_MODEL"; then
      break
    fi
    zenity --warning \
      --title="SheLLM Setup - Invalid Input" \
      --text="Invalid model name: '$AI_MODEL'\n\nModel names may only contain letters, numbers, hyphens, underscores, dots and forward slashes." \
      --width=480 2>/dev/null || true
  done

  log "Model: $AI_MODEL"

  # ── Step 4: API key ────────────────────────────────────────────────────────

  while true; do
    AI_KEY=$(gui_entry \
      "SheLLM Setup  -  Step 2 of 4: API Configuration" \
      "API Key\n\nExamples:\n  OpenAI:      sk-proj-abc123...\n  DeepSeek:    sk-abc123...\n  OpenRouter:  sk-or-v1-abc123...\n  Groq:        gsk_abc123...\n  Local vLLM:  none (local servers usually ignore this)\n\nEnter your API key below:" \
      "") || die "Setup cancelled by user."

    AI_KEY="${AI_KEY#"${AI_KEY%%[![:space:]]*}"}"
    AI_KEY="${AI_KEY%"${AI_KEY##*[![:space:]]}"}"

    if is_valid_api_key "$AI_KEY"; then
      break
    fi
    zenity --warning \
      --title="SheLLM Setup - Invalid Input" \
      --text="Invalid API key.\n\nMust be at least 8 non-whitespace characters.\nIf using a local server, enter: none" \
      --width=480 2>/dev/null || true
  done

  log "API key entered (not logged for security)"

  # ── Step 5: Function name ──────────────────────────────────────────────────

  # Future release. For now just use "shellm" by default.

  # ── Step 6: Window title ───────────────────────────────────────────────────

  while true; do
    AI_TITLE=$(gui_entry \
      "SheLLM Setup  -  Step 3 of 4: Advanced Options" \
      "Window Title\n\nThis is shown in the terminal title bar.\n\nExamples:  AI Terminal   Ask AI   SheLLM   GPT Shell\n\nEnter your window title below:" \
      "AI Terminal") || die "Setup cancelled by user."

    AI_TITLE="${AI_TITLE#"${AI_TITLE%%[![:space:]]*}"}"
    AI_TITLE="${AI_TITLE%"${AI_TITLE##*[![:space:]]}"}"
    AI_TITLE="${AI_TITLE:-AI Terminal}"

    if is_valid_title "$AI_TITLE"; then
      break
    fi
    zenity --warning \
      --title="SheLLM Setup - Invalid Input" \
      --text="Invalid window title.\n\nMust contain only printable characters." \
      --width=480 2>/dev/null || true
  done

  log "Window title: $AI_TITLE"

  # ── Step 7: Temperature ────────────────────────────────────────────────────

  while true; do
    AI_TEMP=$(gui_entry \
      "SheLLM Setup  -  Step 3 of 4: Advanced Options" \
      "Temperature  (0.0 to 2.0)\n\nControls randomness of responses.\n\n  0.0  =  deterministic, always the same answer\n  0.7  =  focused, good for coding and factual tasks\n  1.0  =  default, balanced\n  1.5  =  more creative and varied\n\nEnter temperature below:" \
      "1.0") || die "Setup cancelled by user."

    AI_TEMP="${AI_TEMP#"${AI_TEMP%%[![:space:]]*}"}"
    AI_TEMP="${AI_TEMP%"${AI_TEMP##*[![:space:]]}"}"
    AI_TEMP="${AI_TEMP:-1.0}"

    if is_valid_number "$AI_TEMP" "0.0" "2.0"; then
      break
    fi
    zenity --warning \
      --title="SheLLM Setup - Invalid Input" \
      --text="Invalid temperature: '$AI_TEMP'\n\nMust be a number between 0.0 and 2.0." \
      --width=480 2>/dev/null || true
  done

  log "Temperature: $AI_TEMP"

  # ── Step 8: Max tokens ─────────────────────────────────────────────────────

  while true; do
    AI_MAX_TOKENS=$(gui_entry \
      "SheLLM Setup  -  Step 3 of 4: Advanced Options" \
      "Max Tokens  (1 to 128000)\n\nMaximum length of the AI response.\n\n  512    =  short answers\n  2048   =  medium length\n  4096   =  default, good for most tasks\n  8192   =  long responses\n  128000 =  maximum (model dependent)\n\nEnter max tokens below:" \
      "4096") || die "Setup cancelled by user."

    AI_MAX_TOKENS="${AI_MAX_TOKENS#"${AI_MAX_TOKENS%%[![:space:]]*}"}"
    AI_MAX_TOKENS="${AI_MAX_TOKENS%"${AI_MAX_TOKENS##*[![:space:]]}"}"
    AI_MAX_TOKENS="${AI_MAX_TOKENS:-4096}"

    if is_valid_number "$AI_MAX_TOKENS" "1" "128000"; then
      break
    fi
    zenity --warning \
      --title="SheLLM Setup - Invalid Input" \
      --text="Invalid max tokens: '$AI_MAX_TOKENS'\n\nMust be a whole number between 1 and 128000." \
      --width=480 2>/dev/null || true
  done

  log "Max tokens: $AI_MAX_TOKENS"

  # ── Step 9: Top-p ──────────────────────────────────────────────────────────

  while true; do
    AI_TOP_P=$(gui_entry \
      "SheLLM Setup  -  Step 3 of 4: Advanced Options" \
      "Top-p  (0.0 to 1.0)\n\nControls diversity of word choices.\nAdjust this OR temperature, not both.\n\n  0.5  =  conservative, sticks to likely words\n  0.9  =  slightly varied\n  1.0  =  default, no restriction\n\nEnter top-p below:" \
      "1.0") || die "Setup cancelled by user."

    AI_TOP_P="${AI_TOP_P#"${AI_TOP_P%%[![:space:]]*}"}"
    AI_TOP_P="${AI_TOP_P%"${AI_TOP_P##*[![:space:]]}"}"
    AI_TOP_P="${AI_TOP_P:-1.0}"

    if is_valid_number "$AI_TOP_P" "0.0" "1.0"; then
      break
    fi
    zenity --warning \
      --title="SheLLM Setup - Invalid Input" \
      --text="Invalid top-p: '$AI_TOP_P'\n\nMust be a number between 0.0 and 1.0." \
      --width=480 2>/dev/null || true
  done

  log "Top-p: $AI_TOP_P"

  # ── Step 10: System prompt ─────────────────────────────────────────────────

  while true; do
    AI_SYSTEM=$(gui_entry \
      "SheLLM Setup  -  Step 4 of 4: System Prompt" \
      "System Prompt\n\nSets the AI's role and personality.\n\nExamples:\n  You are a helpful assistant.\n  You are a Linux expert. Give concise terminal-focused answers.\n  You are a code reviewer. Be critical and suggest improvements.\n\nEnter your system prompt below:" \
      "You are a helpful assistant.") || die "Setup cancelled by user."

    AI_SYSTEM="${AI_SYSTEM#"${AI_SYSTEM%%[![:space:]]*}"}"
    AI_SYSTEM="${AI_SYSTEM%"${AI_SYSTEM##*[![:space:]]}"}"
    AI_SYSTEM="${AI_SYSTEM:-You are a helpful assistant.}"

    if is_valid_system_prompt "$AI_SYSTEM"; then
      break
    fi
    zenity --warning \
      --title="SheLLM Setup - Invalid Input" \
      --text="Invalid system prompt.\n\nMust contain only printable characters and spaces." \
      --width=480 2>/dev/null || true
  done

  log "System prompt: $AI_SYSTEM"
}

# ─── Terminal fallback input helpers ──────────────────────────────────────────

prompt_required() {
  local VARNAME="$1"
  local PROMPT_TEXT="$2"
  local VALIDATOR="$3"
  local ERR_MSG="$4"
  local VALUE=""
  while true; do
    read -p "$PROMPT_TEXT" VALUE
    VALUE="${VALUE#"${VALUE%%[![:space:]]*}"}"
    VALUE="${VALUE%"${VALUE##*[![:space:]]}"}"
    if [[ -z "$VALUE" ]]; then
      echo "  This field is required. Please enter a value."
      continue
    fi
    if [[ -n "$VALIDATOR" ]] && ! $VALIDATOR "$VALUE"; then
      echo "  Invalid input: $ERR_MSG"
      continue
    fi
    printf -v "$VARNAME" '%s' "$VALUE"
    return
  done
}

prompt_optional() {
  local VARNAME="$1"
  local PROMPT_TEXT="$2"
  local DEFAULT="$3"
  local VALIDATOR="$4"
  local ERR_MSG="$5"
  local VALUE=""
  while true; do
    read -p "$PROMPT_TEXT" VALUE
    VALUE="${VALUE#"${VALUE%%[![:space:]]*}"}"
    VALUE="${VALUE%"${VALUE##*[![:space:]]}"}"
    VALUE="${VALUE:-$DEFAULT}"
    if [[ -n "$VALIDATOR" ]] && ! $VALIDATOR "$VALUE"; then
      echo "  Invalid input: $ERR_MSG"
      continue
    fi
    printf -v "$VARNAME" '%s' "$VALUE"
    return
  done
}

prompt_number() {
  local VARNAME="$1"
  local PROMPT_TEXT="$2"
  local DEFAULT="$3"
  local MIN="$4"
  local MAX="$5"
  local VALUE=""
  while true; do
    read -p "$PROMPT_TEXT" VALUE
    VALUE="${VALUE:-$DEFAULT}"
    if is_valid_number "$VALUE" "$MIN" "$MAX"; then
      printf -v "$VARNAME" '%s' "$VALUE"
      return
    fi
    echo "  Please enter a number between $MIN and $MAX."
  done
}

# ─── Terminal fallback input ──────────────────────────────────────────────────

terminal_collect_input() {

  # Terminal selection
  echo "Which terminal emulator would you like to use?"
  echo ""
  for i in "${!TERMINALS[@]}"; do
    echo "  $((i+1))) ${TERMINAL_LABELS[$i]} (${TERMINALS[$i]})"
  done
  echo ""

  local TERM_CHOICE=""
  while true; do
    read -p "Enter number [default: 1]: " TERM_CHOICE
    TERM_CHOICE="${TERM_CHOICE:-1}"
    if echo "$TERM_CHOICE" | grep -qE '^[0-9]+$' && \
       [[ "$TERM_CHOICE" -ge 1 ]] && \
       [[ "$TERM_CHOICE" -le "${#TERMINALS[@]}" ]]; then
      break
    fi
    echo "  Invalid choice. Please enter a number between 1 and ${#TERMINALS[@]}."
  done

  CHOSEN_TERM="${TERMINALS[$((TERM_CHOICE-1))]}"
  CHOSEN_LABEL="${TERMINAL_LABELS[$((TERM_CHOICE-1))]}"
  log "User chose terminal: $CHOSEN_LABEL ($CHOSEN_TERM)"
  echo ""

  echo "--- Required Fields ---"
  echo ""

  echo "API Endpoint URL:"
  echo "  SheLLM works with any OpenAI-compatible API endpoint only."
  echo "  The URL must point to a /v1/chat/completions endpoint."
  echo ""
  echo "  OpenAI:      https://api.openai.com/v1/chat/completions"
  echo "  DeepSeek:    https://api.deepseek.com/v1/chat/completions"
  echo "  OpenRouter:  https://openrouter.ai/api/v1/chat/completions"
  echo "  Groq:        https://api.groq.com/openai/v1/chat/completions"
  echo "  Ollama:      http://localhost:11434/v1/chat/completions"
  echo "  vLLM:        http://localhost:8000/v1/chat/completions"
  echo ""
  echo "  NOTE: Non-OpenAI-compatible endpoints will not work."
  echo ""
  prompt_required AI_URL \
    "Endpoint URL: " \
    "is_valid_url" \
    "Must start with http:// or https:// and contain only valid URL characters."
  echo ""

  echo "Model name:"
  echo "  OpenAI:      gpt-4o"
  echo "  DeepSeek:    deepseek-reasoner"
  echo "  OpenRouter:  deepseek/deepseek-r1"
  echo "  Groq:        llama-3.3-70b-versatile"
  echo "  Local vLLM:  mistral-7b-instruct"
  echo ""
  prompt_required AI_MODEL \
    "Model name: " \
    "is_valid_model" \
    "Letters, numbers, hyphens, underscores, dots and forward slashes only."
  echo ""

  echo "API Key:"
  echo "  OpenAI:      sk-proj-abc123..."
  echo "  DeepSeek:    sk-abc123..."
  echo "  OpenRouter:  sk-or-v1-abc123..."
  echo "  Groq:        gsk_abc123..."
  echo "  Local vLLM:  none"
  echo ""
  prompt_required AI_KEY \
    "API Key: " \
    "is_valid_api_key" \
    "Must be at least 8 non-whitespace characters. For local servers enter: none"
  echo ""

  echo "Window title - shown in the terminal title bar."
  echo "  Examples: AI Terminal, Ask AI, SheLLM"
  echo ""
  prompt_optional AI_TITLE \
    "Window title [default: AI Terminal]: " \
    "AI Terminal" \
    "is_valid_title" \
    "Must contain only printable characters."
  echo ""

  echo "--- Optional Parameters (press Enter to use defaults) ---"
  echo ""

  echo "Temperature - randomness of responses."
  echo "  0.0 = deterministic  |  0.7 = focused  |  1.0 = default  |  1.5 = creative"
  echo ""
  prompt_number AI_TEMP "Temperature [default: 1.0]: " "1.0" "0.0" "2.0"
  echo ""

  echo "Max tokens - maximum response length."
  echo "  512 = short  |  2048 = medium  |  4096 = default  |  8192 = long"
  echo ""
  prompt_number AI_MAX_TOKENS "Max tokens [default: 4096]: " "4096" "1" "128000"
  echo ""

  echo "Top-p - adjust this OR temperature, not both."
  echo "  0.5 = conservative  |  0.9 = varied  |  1.0 = default"
  echo ""
  prompt_number AI_TOP_P "Top-p [default: 1.0]: " "1.0" "0.0" "1.0"
  echo ""

  echo "System prompt - sets the AI's role and personality."
  echo "  Example 1: You are a helpful assistant."
  echo "  Example 2: You are a Linux expert. Give concise terminal-focused answers."
  echo "  Example 3: You are a code reviewer. Be critical and suggest improvements."
  echo ""
  prompt_optional AI_SYSTEM \
    "System prompt [default: You are a helpful assistant.]: " \
    "You are a helpful assistant." \
    "is_valid_system_prompt" \
    "Must contain only printable characters and spaces."
  echo ""
}

# ─── Collect input via GUI or terminal ────────────────────────────────────────

if [[ "$USE_GUI" == true ]]; then
  gui_collect_input
  AI_API_KEY="$AI_KEY"
else
  terminal_collect_input
  AI_API_KEY="$AI_KEY"
fi

# ─── Confirm summary ──────────────────────────────────────────────────────────

SUMMARY="Terminal:      $CHOSEN_LABEL ($CHOSEN_TERM)
Endpoint:      $AI_URL
Model:         $AI_MODEL
API Key:       $(echo "$AI_API_KEY" | cut -c1-6)******
Temperature:   $AI_TEMP
Max tokens:    $AI_MAX_TOKENS
Top-p:         $AI_TOP_P
System prompt: $AI_SYSTEM
Function name: $AI_FUNC
Window title:  $AI_TITLE"

if [[ "$USE_GUI" == true ]]; then
  zenity --question \
    --title="SheLLM Setup - Confirm Installation" \
    --text="Ready to install with these settings:\n\n$SUMMARY\n\nProceed?" \
    --ok-label="Install" \
    --cancel-label="Cancel" \
    --width=580 2>/dev/null || {
      log "User cancelled at confirmation."
      echo "Aborted. Nothing was written."
      exit 0
    }
else
  echo "=== Summary ==="
  echo ""
  echo "$SUMMARY"
  echo ""
  read -p "Install everything? [y/N]: " CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborted. Nothing was written."
    log "User aborted at confirmation."
    exit 0
  fi
fi

# ─── Remove existing config block ─────────────────────────────────────────────

if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
  echo ""
  echo "Removing existing config block from ~/.bashrc..."
  TMPFILE=$(mktemp) || die "Could not create temp file."
  sed "/^$MARKER$/,/^$MARKER_END$/d" "$BASHRC" > "$TMPFILE"
  mv "$TMPFILE" "$BASHRC" || die "Could not update $BASHRC"
  log "Removed existing config block."
fi

# ─── Write config block to ~/.bashrc ──────────────────────────────────────────

log "Writing config block to $BASHRC"

cat >> "$BASHRC" << BASHRC_EOF

$MARKER
export AI_API_URL="$AI_URL"
export AI_API_KEY="$AI_API_KEY"
export AI_MODEL="$AI_MODEL"
export AI_TEMP="$AI_TEMP"
export AI_MAX_TOKENS="$AI_MAX_TOKENS"
export AI_TOP_P="$AI_TOP_P"
export AI_SYSTEM="$AI_SYSTEM"

$AI_FUNC() {
  if [[ -z "\$*" ]]; then
    echo "Usage: $AI_FUNC <your question>"
    return 1
  fi

  local PROMPT
  PROMPT=\$(python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" <<< "\$*") || {
    echo "Error: Failed to encode prompt."
    return 1
  }

  local SYSTEM
  SYSTEM=\$(python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" <<< "\$AI_SYSTEM") || {
    echo "Error: Failed to encode system prompt."
    return 1
  }

  local RESPONSE
  RESPONSE=\$(curl -s --max-time 120 --retry 2 --retry-delay 3 "\$AI_API_URL" \
    -H "Authorization: Bearer \$AI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"\$AI_MODEL\",
      \"temperature\": \$AI_TEMP,
      \"max_tokens\": \$AI_MAX_TOKENS,
      \"top_p\": \$AI_TOP_P,
      \"messages\": [
        {\"role\": \"system\", \"content\": \$SYSTEM},
        {\"role\": \"user\", \"content\": \$PROMPT}
      ]
    }") || {
    echo "Error: curl failed. Check your internet connection and endpoint URL."
    return 1
  }

  if [[ -z "\$RESPONSE" ]]; then
    echo "Error: Empty response from server. Check your endpoint and API key."
    return 1
  fi

  echo "\$RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'error' in data:
        msg = data['error'].get('message', 'Unknown error')
        code = data['error'].get('code', '')
        print('API Error' + (' (' + str(code) + ')' if code else '') + ': ' + msg)
        sys.exit(1)
    for choice in data.get('choices', []):
        msg = choice.get('message', {})
        text = msg.get('content')
        if text is not None:
            print(text)
            sys.exit(0)
    print('Error: No content in response.')
    sys.exit(1)
except json.JSONDecodeError:
    print('Error: Could not parse server response as JSON.')
    sys.exit(1)
"
}
$MARKER_END
BASHRC_EOF

log "Config block written successfully."

# ─── Create launcher script ───────────────────────────────────────────────────

LAUNCH_CMD=$(build_launch_cmd "$CHOSEN_TERM" "$AI_TITLE")

cat > "$LAUNCHER" << LAUNCHER_EOF
#!/bin/bash
# SheLLM Terminal Launcher - generated by shellm-setup.sh
# To reconfigure, re-run shellm-setup.sh
$LAUNCH_CMD
LAUNCHER_EOF

chmod +x "$LAUNCHER" || die "Could not make launcher executable."
log "Launcher written to $LAUNCHER"

# ─── Create .desktop entry ────────────────────────────────────────────────────

if [[ -d "$HOME/.local/share/applications" ]]; then
  cat > "$DESKTOP" << DESKTOP_EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$AI_TITLE
Comment=Terminal with AI assistant ($AI_FUNC) via $CHOSEN_LABEL
Exec=$LAUNCHER
Icon=utilities-terminal
Terminal=false
Categories=Utility;TerminalEmulator;
StartupNotify=true
DESKTOP_EOF

  chmod +x "$DESKTOP" 2>/dev/null || true

  if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  fi

  log "Desktop entry written to $DESKTOP"
else
  warn "Skipping desktop entry: $HOME/.local/share/applications not found."
fi

# ─── Find config block line number ────────────────────────────────────────────

CONFIG_LINE=$(grep -n "$MARKER" "$BASHRC" 2>/dev/null | cut -d: -f1 || echo "unknown")

# ─── Done ─────────────────────────────────────────────────────────────────────

DONE_MSG="All done!

Three ways to launch your AI terminal:

  1. From your app menu:  search for '$AI_TITLE'
  2. From any terminal:   shellm-terminal
  3. Direct command:      $LAUNCH_CMD

Then just type:
  $AI_FUNC how do I find files larger than 100MB
  $AI_FUNC explain what a segmentation fault is
  $AI_FUNC write a bash script to back up my home folder

Your config is stored in:
  $BASHRC  (line ~$CONFIG_LINE)

Look for the block between these markers:
  $MARKER
  $MARKER_END

Re-run this script at any time to reconfigure.

To apply changes in your current terminal:
  source ~/.bashrc

Log:    $LOGFILE
Backup: $BACKUP"

echo ""
echo "=== $DONE_MSG"

if [[ "$USE_GUI" == true ]]; then
  zenity --info \
    --title="SheLLM Setup - Complete" \
    --text="$DONE_MSG" \
    --width=600 \
    --height=500 2>/dev/null || true
fi

INSTALL_COMPLETE=true

log "Setup complete"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Run this now to start using shellm immediately:"
echo ""
echo "    source ~/.bashrc"
echo ""
echo "  Or just open a new terminal tab and type something like: shellm are you there?"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ─── Reload bashrc ────────────────────────────────────────────────────────────

if [[ -f "$HOME/.bashrc" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.bashrc" 2>/dev/null || true
  log "Reloaded ~/.bashrc"
fi
