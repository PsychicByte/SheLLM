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


### Step 2 — Run Setup
./shellm.sh
> ⚠️ Do not run with sudo or as root. It must be run as your normal user account.

### Step 3 — Install Dependencies
The setup script checks for curl, python3, and zenity automatically. If anything is missing you will see:
[ MISSING ] zenity
Install them now via apt-get? [y/N]:
Type y and press Enter. The script handles the rest.

### Step 4 — Choose a Terminal Emulator
The setup lists every terminal emulator found on your system:
1) GNOME Terminal (gnome-terminal)
2) xterm (xterm)
3) Kitty (kitty)
Type the number of the one you want and press Enter.

### Step 5 — Enter Your API Details
You will be asked for the following. If zenity is available these appear as GUI dialogs, otherwise as terminal prompts.
Endpoint URL — the full URL to your provider's chat completions endpoint.
Model name — the exact model identifier your provider uses (e.g., gpt-4o, deepseek-reasoner, llama3).
API key — your secret key from your provider's dashboard. For local servers, type none.

### Step 6 — Set Advanced Options
All optional. Press Enter to accept the defaults.
Window title  -> AI Terminal (Label shown in the terminal title bar)
Temperature   -> 1.0 (Response randomness, 0.0 to 2.0)
Max tokens    -> 4096 (Maximum response length, 1 to 128000)
Top-p         -> 1.0 (Nucleus sampling threshold, 0.0 to 1.0)
System prompt -> You are a helpful assistant. (Sets the AI's role and personality)
Temperature guide:
0.7 -> Focused, good for code and technical tasks
1.0 -> Balanced, good for general use
1.5 -> More creative, good for writing tasks
> Adjust temperature or top-p, not both.

### Step 7 — Confirm and Install
You will see a full summary of your settings. Review and confirm.
GUI: click Install
Terminal: type y and press Enter

### Step 8 — Start Using SheLLM
Open a new terminal or run:
source ~/.bashrc
Then just type:
shellm your question here

Installation
⚠️ Do not run as root. Run as your normal user account.

bash

Copy
./shellm.sh
What the installer does
Checks you are not running as root
Verifies bash 4.0 or higher
Creates ~/.local/bin if it does not exist
Adds ~/.local/bin to your PATH in ~/.bashrc if not already present
Backs up your current ~/.bashrc
Checks for curl, python3, and zenity — installs missing ones if you agree
Detects available terminal emulators
Collects your configuration via GUI or terminal prompts
Writes a configuration block to ~/.bashrc
Creates a launcher script at ~/.local/bin/shellm-terminal
Creates a .desktop entry so SheLLM appears in your application menu
Sources ~/.bashrc so the function is available immediately
Setup wizard fields
Field	Required	Default	Description
Endpoint URL	Yes	—	Full URL to the /v1/chat/completions endpoint
Model name	Yes	—	The model identifier string
API key	Yes	—	Your API key. Use none for local servers
Window title	No	AI Terminal	Title shown in the terminal title bar
Temperature	No	1.0	Response randomness, 0.0 to 2.0
Max tokens	No	4096	Maximum response length, 1 to 128000
Top-p	No	1.0	Nucleus sampling threshold, 0.0 to 1.0
System prompt	No	You are a helpful assistant.	Sets the AI's role and personality
Usage
After installation, open a new terminal or run source ~/.bashrc, then:

bash

Copy
shellm <your question>
Examples
bash

Copy
shellm how do I find files larger than 100MB
shellm explain what a segmentation fault is
shellm write a bash script to back up my home folder
shellm what does the grep -P flag do
shellm how do I list all open ports on this machine
shellm what is the difference between a hard link and a soft link
shellm how do I kill a process by name
shellm what is a cron job and how do I set one up
shellm how do I search for text inside files recursively
Launching the dedicated AI terminal
bash

Copy
# From any terminal
shellm-terminal

# Or search for your chosen window title in your application menu
# e.g. "AI Terminal"
Configuration
All configuration is stored as environment variables in ~/.bashrc between these markers:

bash

Copy
# >>> shellm config >>>
...
# <<< shellm config <<<
Environment variables
Variable	Description	Example
AI_API_URL	Full endpoint URL	https://api.openai.com/v1/chat/completions
AI_API_KEY	Your API key	sk-proj-abc123...
AI_MODEL	Model identifier	gpt-4o
AI_TEMP	Temperature (0.0–2.0)	1.0
AI_MAX_TOKENS	Max response tokens (1–128000)	4096
AI_TOP_P	Top-p (0.0–1.0)	1.0
AI_SYSTEM	System prompt	You are a helpful assistant.
You can edit these directly in ~/.bashrc and run source ~/.bashrc to apply changes, or re-run shellm.sh to go through the wizard again.

How It Works
When you run shellm your question here:

Your input is JSON-encoded using python3 to safely handle quotes and special characters
The system prompt is JSON-encoded the same way
curl sends a POST request to your configured endpoint with the encoded payload
The raw JSON response is piped to a python3 parser
The parser iterates the choices array, extracts the first available content field, and prints it
If the API returns an error object, the error message and code are printed instead
If the response cannot be parsed as JSON, a clear error is shown
Request payload structure
json

Copy
{
  "model": "your-model",
  "temperature": 1.0,
  "max_tokens": 4096,
  "top_p": 1.0,
  "messages": [
    { "role": "system", "content": "You are a helpful assistant." },
    { "role": "user", "content": "your question here" }
  ]
}
File Locations
File	Purpose
~/.bashrc	Contains the shellm function and env vars
~/.local/bin/shellm-terminal	Launcher script for the AI terminal
~/.local/share/applications/shellm-terminal.desktop	Desktop entry for the app menu
/tmp/shellm-setup-YYYYMMDD-HHMMSS.log	Setup log file
~/.bashrc.shellm.bak.YYYYMMDD-HHMMSS	Automatic backup of ~/.bashrc
Reconfiguring
Re-run the setup script at any time to update any setting:

bash

Copy
./shellm.sh
Your previous ~/.bashrc is backed up automatically before any changes are made.

Uninstalling
bash

Copy
# Remove the config block from ~/.bashrc
sed -i '/# >>> shellm config >>>/,/# <<< shellm config <<</d' ~/.bashrc

# Remove the launcher and desktop entry
rm -f ~/.local/bin/shellm-terminal
rm -f ~/.local/share/applications/shellm-terminal.desktop

# Refresh the application menu
update-desktop-database ~/.local/share/applications 2>/dev/null || true

# Unload from the current session
unset AI_API_URL AI_API_KEY AI_MODEL AI_TEMP AI_MAX_TOKENS AI_TOP_P AI_SYSTEM
unset -f shellm
Troubleshooting
shellm: command not found after setup

bash

Copy
source ~/.bashrc
Error: curl failed

Check your internet connection
Verify the endpoint URL is correct and reachable
Error: Empty response from server

Your API key may be invalid or expired
The endpoint may be down
API Error: Insufficient credits

Log into your provider dashboard and check your quota
Error: No content in response

The model may have returned an empty completion
Try a different prompt or check the model name is correct
Error: Could not parse server response as JSON

The endpoint may not be OpenAI-compatible
There may be a network issue returning an HTML error page instead of JSON
Setup fails with Unexpected error on line N

Check the log: /tmp/shellm-setup-*.log
Your ~/.bashrc will have been automatically restored from the backup
Want to restore your original bashrc

bash

Copy
ls ~/.bashrc.shellm.bak.*
cp ~/.bashrc.shellm.bak.YYYYMMDD-HHMMSS ~/.bashrc
source ~/.bashrc
Security
Your API key is stored in plain text in ~/.bashrc. Do not use SheLLM on shared multi-user systems without understanding this risk.
Never paste your API key into public forums, chat logs, or version control. If you do, rotate the key immediately through your provider's dashboard.
Local model servers (Ollama, vLLM, LM Studio) do not require a real API key. Use none when prompted.
The setup script refuses to run as root to prevent accidental system-wide changes.
All changes are reversible. A backup of ~/.bashrc is created before every run.
Limitations
No conversation history. Each shellm call is a single-turn request. The model has no memory of previous questions in the same session.
No streaming. Responses are returned all at once after the full completion is received.
No image or file input. Text only.
Single user session only. The function and credentials are tied to the user account that ran setup.
OpenAI-compatible endpoints only. Providers with custom API schemas will not work without modifying the parser in ~/.bashrc.
Response length is capped by the AI_MAX_TOKENS setting and by the model's own context window limit.
