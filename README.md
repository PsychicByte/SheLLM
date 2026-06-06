# SheLLM

> ⚠️ **Prototype — Work in progress.** Expect rough edges.

A lightweight AI assistant that lives directly in your Linux terminal. Type a question, get an answer — no browser, no app switching, no friction. SheLLM installs a shell function into your `~/.bashrc` that sends your query to any OpenAI-compatible API and prints the response inline.

---

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Supported Distributions](#supported-distributions)
- [Supported Terminal Emulators](#supported-terminal-emulators)
- [Supported API Providers](#supported-api-providers)
- [How To](#how-to)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [How It Works](#how-it-works)
- [File Locations](#file-locations)
- [Reconfiguring](#reconfiguring)
- [Uninstalling](#uninstalling)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Limitations](#limitations)
- [License](#license)

---

## Overview

SheLLM is a single bash script that sets up an AI assistant function in your shell environment. Once installed, you can query any OpenAI-compatible language model directly from your terminal prompt without leaving your workflow.

It supports both GUI setup via zenity dialogs and fully headless terminal setup, making it suitable for desktop environments, minimal installs, and remote SSH sessions alike.

Everything SheLLM needs is already on most Linux systems: `bash`, `curl`, and `python3`. No pip packages, no Node.js, no virtual environments, no containers.

---

## Requirements

| Dependency | Minimum Version | Purpose                   |
|------------|-----------------|---------------------------|
| bash       | 4.0             | Running the setup script  |
| curl       | any             | Making API requests       |
| python3    | 3.6             | JSON encoding and parsing |
| zenity     | any             | GUI dialogs (optional)    |

If `curl`, `python3`, or `zenity` are missing, the setup script will offer to install them automatically using your system's package manager.

`zenity` is optional. If it is not installed or no display server is detected, setup falls back to plain terminal prompts automatically.

---

## Supported Distributions

SheLLM auto-detects and uses the correct package manager for your distribution.

| Distribution Family          | Package Manager |
|------------------------------|-----------------|
| Debian, Ubuntu, Mint, Pop!   | apt-get         |
| Fedora, RHEL, CentOS Stream  | dnf             |
| Older CentOS, RHEL           | yum             |
| Arch, Manjaro, EndeavourOS   | pacman          |
| openSUSE, SLES               | zypper          |
| Alpine                       | apk             |
| Gentoo                       | emerge          |

If your package manager is not listed, install `curl` and `python3` manually and re-run the setup script.

---

## Supported Terminal Emulators

During setup you will be asked which terminal emulator to use for the SheLLM launcher. The following are detected and supported automatically:

| Terminal       | Command        |
|----------------|----------------|
| Terminator     | terminator     |
| GNOME Terminal | gnome-terminal |
| xterm          | xterm          |
| Konsole        | konsole        |
| XFCE Terminal  | xfce4-terminal |
| Tilix          | tilix          |
| Kitty          | kitty          |
| Alacritty      | alacritty      |
| WezTerm        | wezterm        |
| Foot           | foot           |
| LXTerminal     | lxterminal     |
| MATE Terminal  | mate-terminal  |
| st (suckless)  | st             |
| URxvt          | urxvt          |
| rxvt           | rxvt           |

If none are found, the setup script will offer to install `xterm` automatically.

---

## Supported API Providers

SheLLM works with any API that implements the OpenAI `/v1/chat/completions` endpoint format. The following providers are known to work:

| Provider   | Endpoint URL                                            | Notes                     |
|------------|---------------------------------------------------------|---------------------------|
| OpenAI     | https://api.openai.com/v1/chat/completions              | Requires paid API key     |
| DeepSeek   | https://api.deepseek.com/v1/chat/completions            |                           |
| OpenRouter | https://openrouter.ai/api/v1/chat/completions           | Access to many models     |
| Groq       | https://api.groq.com/openai/v1/chat/completions         | Very fast inference       |
| Ollama     | http://localhost:11434/v1/chat/completions              | Local models, no API key  |
| vLLM       | http://localhost:8000/v1/chat/completions               | Local models, no API key  |
| LM Studio  | http://localhost:1234/v1/chat/completions               | Local models, no API key  |
| Any relay  | http(s)://your-relay/v1/chat/completions                | Must be OpenAI-compatible |

> **Note:** The endpoint must implement the OpenAI chat completions format exactly. Providers with custom response schemas will not work without modifying the parser.

---

## How To

### Before You Start

Make sure you have the following ready:

- A Linux system with bash 4.0 or higher
- An API key from a supported provider, or a local model server running
- The endpoint URL for your chosen provider
- The model name you want to use

> If you are using a local server like Ollama or vLLM, you do not need an API key. Just type `none` when prompted.

### Step 1 — Get the Script

Download or copy `shellm.sh` to your machine and make it executable:

```bash
chmod +x shellm.sh

