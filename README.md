# SheLLM

> ⚠️ **Prototype — Work in progress. Expect rough edges.**

A lightweight AI assistant that lives directly in your Linux terminal. Type a question, get an answer — no browser, no app switching, no friction. SheLLM installs a shell function into your `~/.bashrc` that sends your query to any OpenAI-compatible API and prints the response inline.

---

## Table of Contents
- [Overview](#overview)
- [Requirements](#requirements)
- [Supported Distributions](#supported-distributions)
- [Supported Terminal Emulators](#supported-terminal-emulators)
- [Supported API Providers](#supported-api-providers)
- [How To](#how-to)
- [Installation Details](#installation-details)

---

## Overview

SheLLM is a single bash script that sets up an AI assistant function in your shell environment. Once installed, you can query any OpenAI-compatible language model directly from your terminal prompt without leaving your workflow.

It supports both GUI setup via `zenity` dialogs and fully headless terminal setup, making it suitable for desktop environments, minimal installs, and remote SSH sessions alike.

Everything SheLLM needs is already on most Linux systems: `bash`, `curl`, and `python3`. No pip packages, no Node.js, no virtual environments, no containers.

---

## Requirements

| Dependency | Minimum Version | Purpose |
| :--- | :--- | :--- |
| **bash** | 4.0 | Running the setup script |
| **curl** | any | Making API requests |
| **python3**| 3.6 | JSON encoding and parsing |
| **zenity** | any | GUI dialogs (optional) |

*If `curl`, `python3`, or `zenity` are missing, the setup script will offer to install them automatically using your system's package manager.*

*`zenity` is optional. If it is not installed or no display server is detected, setup falls back to plain terminal prompts automatically.*

---

## Supported Distributions

SheLLM auto-detects and uses the correct package manager for your distribution.

| Distribution Family | Package Manager |
| :--- | :--- |
| Debian, Ubuntu, Mint, Pop! | `apt-get` |
| Fedora, RHEL, CentOS Stream | `dnf` |
| Older CentOS, RHEL | `yum` |
| Arch, Manjaro, EndeavourOS | `pacman` |
| openSUSE, SLES | `zypper` |
| Alpine | `apk` |
| Gentoo | `emerge` |

*If your package manager is not listed, install `curl` and `python3` manually and re-run the setup script.*

---

## Supported Terminal Emulators

During setup you will be asked which terminal emulator to use for the SheLLM launcher. The following are detected and supported automatically:

* Terminator (`terminator`)
* GNOME Terminal (`gnome-terminal`)
* xterm (`xterm`)
* Konsole (`konsole`)
* XFCE Terminal (`xfce4-terminal`)
* Tilix (`tilix`)
* Kitty (`kitty`)
* Alacritty (`alacritty`)
* WezTerm (`wezterm`)
* Foot (`foot`)
* LXTerminal (`lxterminal`)
* MATE Terminal (`mate-terminal`)
* st (suckless) (`st`)
* URxvt (`urxvt`)
* rxvt (`rxvt`)

*If none are found, the setup script will offer to install `xterm` automatically.*

---

## Supported API Providers

SheLLM works with any API that implements the OpenAI `/v1/chat/completions` endpoint format. The following providers are known to work:

| Provider | Endpoint URL | Notes |
| :--- | :--- | :--- |
| **OpenAI** | `https://api.openai.com/v1/chat/completions` | Requires paid API key |
| **DeepSeek** | `https://api.deepseek.com/v1/chat/completions` | |
| **OpenRouter** | `https://openrouter.ai/api/v1/chat/completions` | Access to many models |
| **Groq** | `https://api.groq.com/openai/v1/chat/completions` | Very fast inference |
| **Ollama** | `http://localhost:11434/v1/chat/completions` | Local models, no API key |
| **vLLM** | `http://localhost:8000/v1/chat/completions` | Local models, no API key |
| **LM Studio**| `http://localhost:1234/v1/chat/completions` | Local models, no API key |
| **Any relay**| `http(s)://your-relay/v1/chat/completions` | Must be OpenAI-compatible |

> **Note:** The endpoint must implement the OpenAI chat completions format exactly. Providers with custom response schemas will not work without modifying the parser.

---

## How To

### Before You Start
Make sure you have the following ready:
* A Linux system with bash 4.0 or higher
* An API key from a supported provider, or a local model server running
* The endpoint URL for your chosen provider
* The model name you want to use

> **Note:** If you are using a local server like Ollama or vLLM, you do not need an API key. Just type `none` when prompted.

### Step 1 — Get the Script
Download or copy `shellm.sh` to your machine and make it executable:
```bash
chmod +x shellm.sh
```

### Step 2 — Run Setup
Execute the script from your terminal:
```bash
./shellm.sh
```
> ⚠️ **Do not run with sudo or as root.** It must be run as your normal user account.

### Step 3 — Install Dependencies
The setup script checks for `curl`, `python3`, and `zenity` automatically. If anything is missing you will see:
```text
[ MISSING ] zenity
Install them now via apt-get? [y/N]:
```
Type `y` and press **Enter**. The script handles the rest.

### Step 4 — Choose a Terminal Emulator
The setup lists every terminal emulator found on your system:
```text
1) GNOME Terminal (gnome-terminal)
2) xterm (xterm)
3) Kitty (kitty)
```
Type the number of the one you want and press **Enter**.

### Step 5 — Enter Your API Details
You will be asked for the following. If `zenity` is available these appear as GUI dialogs, otherwise as terminal prompts.
* **Endpoint URL** — the full URL to your provider's chat completions endpoint.
* **Model name** — the exact model identifier your provider uses (e.g., `gpt-4o`, `deepseek-reasoner`, `llama3`).
* **API key** — your secret key from your provider's dashboard. For local servers, type `none`.

### Step 6 — Set Advanced Options
All optional. Press **Enter** to accept the defaults.
* **Window title** → `AI Terminal` *(Label shown in the terminal title bar)*
* **Temperature** → `1.0` *(Response randomness, 0.0 to 2.0)*
* **Max tokens** → `4096` *(Maximum response length, 1 to 128000)*
* **Top-p** → `1.0` *(Nucleus sampling threshold, 0.0 to 1.0)*
* **System prompt** → `You are a helpful assistant.` *(Sets the AI's role and personality)*

**Temperature guide:**
* `0.7` → Focused, good for code and technical tasks
* `1.0` → Balanced, good for general use
* `1.5` → More creative, good for writing tasks
*(Tip: Adjust temperature or top-p, not both.)*

### Step 7 — Confirm and Install
You will see a full summary of your settings. Review and confirm.
* **GUI:** click Install
* **Terminal:** type `y` and press **Enter**

### Step 8 — Start Using SheLLM
Open a new terminal or reload your bash configuration:
```bash
source ~/.bashrc
```
Then just type:
```bash
shellm your question here
```

---

## Installation Details

To trigger the installation manually, run:
```bash
./shellm.sh
```
> ⚠️ **Do not run as root.** Run as your normal user account.

### What the installer does:
* Checks you are not running as root
* Verifies `bash` 4.0 or higher
* Creates `~/.local/bin` if it does not exist
* Adds `~/.local/bin` to your `PATH` in `~/.bashrc` if not already present
* Backs up your current `~/.bashrc`
* Checks for `curl`, `python3`, and `zenity` — installs missing ones if you agree
* Detects and configures your preferred terminal emulator

### Uninstallation Process:
Run the following in your terminal if you want to uninstall:
```text
rm -f ~/.local/bin/shellm
sed -i '/# >>> shellm config >>>/,/# <<< shellm config <<</d' ~/.bashrc
rm -rf ~/.local/share/shellm
rm -rf ~/.local/share/shellm-logs
rm -rf ~/.local/share/shellm-cache
```

## License

This project is licensed under the MIT License.

You are free to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, provided that the original copyright notice and this permission notice are included in all copies or substantial portions of the Software.

*See the `LICENSE` file in the root of this repository for the full text.*
