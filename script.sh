#!/bin/bash
set -e  # stop on error

echo "Updating system..."
sudo apt update && sudo apt upgrade -y

echo "Installing basic dependencies..."
sudo apt install -y wget gpg curl apt-transport-https software-properties-common

# -----------------------------
# VS Code
# -----------------------------
echo "Installing VS Code..."

wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -D -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg
rm -f microsoft.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
| sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

sudo apt update
sudo apt install -y code

# -----------------------------
# Git config
# -----------------------------

echo "Installing Git..."
sudo apt install -y git

echo "Configuring Git..."
git config --global user.name "Pacheco"
git config --global user.email "lucaspdroz@gmail.com"

# -----------------------------
# Desktop / Wallpaper
# -----------------------------

# URL do wallpaper que será baixado e aplicado
WALLPAPER_URL="https://github.com/lucaspdroz/linux-install-script/blob/main/wallpapers/ada.jpg?raw=true"
WALLPAPER_DIR="$HOME/Pictures"
WALLPAPER_FILE="$WALLPAPER_DIR/ada.jpg"

AVATAR_URL="https://github.com/lucaspdroz/linux-install-script/blob/main/wallpapers/avatar.jpg?raw=true"
AVATAR_FILE="$WALLPAPER_DIR/avatar.jpg"

echo "🖼️ Configuring dark theme and wallpaper..."
mkdir -p "$WALLPAPER_DIR"

if [ -n "$WALLPAPER_URL" ]; then
    echo "📥 Downloading wallpaper..."
    curl -fL "$WALLPAPER_URL" -o "$WALLPAPER_FILE"

    if command -v gsettings >/dev/null; then
        gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_FILE" || true
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_FILE" || true
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
        gsettings set org.cinnamon.desktop.interface gtk-theme 'Mint-Y-Dark' || true
    fi

    echo "✅ Wallpaper and dark theme configured."
else
    echo "⚠️ WALLPAPER_URL is empty; skipping wallpaper download."
fi


echo "👤 Configuring user avatar..."

AVATAR_URL="https://github.com/lucaspdroz/linux-install-script/blob/main/wallpapers/avatar.jpg?raw=true"
AVATAR_FILE="$WALLPAPER_DIR/avatar.jpg"
AVATAR_ICON="/var/lib/AccountsService/icons/$USER"
AVATAR_ACCOUNT="/var/lib/AccountsService/users/$USER"

if [ -n "$AVATAR_URL" ]; then
    echo "📥 Downloading avatar..."
    curl -fL "$AVATAR_URL" -o "$AVATAR_FILE"

    # ~/.face — compatibilidade
    cp "$AVATAR_FILE" "$HOME/.face"
    chmod 644 "$HOME/.face"

    # AccountsService — Cinnamon / LightDM
    sudo mkdir -p /var/lib/AccountsService/icons

    sudo cp "$AVATAR_FILE" "$AVATAR_ICON"
    sudo chmod 644 "$AVATAR_ICON"

    # Configura o AccountsService para usar o avatar
    if [ -f "$AVATAR_ACCOUNT" ]; then
        if grep -q '^Icon=' "$AVATAR_ACCOUNT"; then
            sudo sed -i "s|^Icon=.*|Icon=$AVATAR_ICON|" "$AVATAR_ACCOUNT"
        else
            echo "Icon=$AVATAR_ICON" | sudo tee -a "$AVATAR_ACCOUNT" > /dev/null
        fi
    else
        sudo mkdir -p /var/lib/AccountsService/users

        sudo tee "$AVATAR_ACCOUNT" > /dev/null <<EOF
[User]
Icon=$AVATAR_ICON
SystemAccount=false
EOF

        sudo chmod 644 "$AVATAR_ACCOUNT"
    fi

    echo "✅ User avatar configured."
else
    echo "⚠️ AVATAR_URL is empty; skipping avatar."
fi

# -----------------------------
# Zsh + Oh My Zsh
# -----------------------------
echo "Installing Zsh..."
sudo apt install -y zsh

echo "Setting Zsh as default shell..."
chsh -s $(which zsh)

echo "Installing Oh My Zsh..."
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"


# -----------------------------
# Zsh theme
# -----------------------------

# Define variables
REPO_URL="https://github.com/lucaspdroz/lodash-zsh-theme.git"
TEMP_DIR="$HOME/lodash-zsh-theme"
ZSH_CUSTOM_THEMES="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes"

echo "🚀 Starting Lodash Zsh Theme installation..."

# 1. Clone or Update the repository
if [ -d "$TEMP_DIR" ]; then
    echo "📂 Directory exists, updating..."
    cd "$TEMP_DIR" && git pull
else
    echo "📥 Cloning repository..."
    git clone "$REPO_URL" "$TEMP_DIR"
fi

# 2. Copy the theme file
mkdir -p "$ZSH_CUSTOM_THEMES"
cp "$TEMP_DIR/lodash.zsh-theme" "$ZSH_CUSTOM_THEMES/lodash.zsh-theme"

# 3. Update ZSH_THEME in .zshrc
if [ -f "$HOME/.zshrc" ]; then
    echo "✍️ Updating ZSH_THEME in ~/.zshrc..."
    sed -i 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="lodash"/' "$HOME/.zshrc"
fi

# 4. Force Bash to launch Zsh (Editing ~/.bashrc)
echo "🐚 Forcing Bash to launch Zsh..."

# Check if we've already added the redirect to avoid duplicates
if ! grep -q "exec zsh" "$HOME/.bashrc"; then
    # Create a temporary file to prepend the command
    echo -e "if [ -t 1 ]; then\n  exec zsh\nfi\n\n$(cat "$HOME/.bashrc")" > "$HOME/.bashrc"
    echo "✅ Added exec zsh to the top of ~/.bashrc"
else
    echo "ℹ️ Zsh redirect already exists in ~/.bashrc"
fi

echo "🎉 Done! Next time you open Bash, it will automatically switch to Zsh."

# -----------------------------
#  Installing FiraCode Nerd Font
# -----------------------------

echo "📥 Installing FiraCode Nerd Font..."

# Create fonts directory
mkdir -p ~/.local/share/fonts
cd /tmp

# Download latest FiraCode Nerd Font
curl -fLo FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip

# Unzip
unzip -o FiraCode.zip -d firacode

# Install fonts
cp firacode/*.ttf ~/.local/share/fonts/

# Refresh font cache
fc-cache -fv

echo "✅ Font installed."

# -----------------------------
# VS Code integrated terminal font
# -----------------------------
echo "🎨 Configuring FiraCode Nerd Font in VS Code terminal..."

VSCODE_USER_DIR="$HOME/.config/Code/User"
VSCODE_SETTINGS="$VSCODE_USER_DIR/settings.json"

mkdir -p "$VSCODE_USER_DIR"

if [ -f "$VSCODE_SETTINGS" ]; then
    python3 - "$VSCODE_SETTINGS" << 'PY'
import json
import sys

path = sys.argv[1]

with open(path, "r", encoding="utf-8") as f:
    settings = json.load(f)

settings["terminal.integrated.fontFamily"] = "FiraCode Nerd Font"

with open(path, "w", encoding="utf-8") as f:
    json.dump(settings, f, indent=4, ensure_ascii=False)
    f.write("\n")
PY
else
    cat > "$VSCODE_SETTINGS" << 'EOF'
{
    "terminal.integrated.fontFamily": "FiraCode Nerd Font"
}
EOF
fi

echo "✅ VS Code terminal font configured."

# Try to configure GNOME Terminal / Cinnamon Terminal
if command -v gsettings >/dev/null; then
    echo "🎨 Setting font in terminal..."

    PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
    PROFILE_PATH="/org/gnome/terminal/legacy/profiles:/:$PROFILE/"

    gsettings set "org.gnome.Terminal.Legacy.Profile:$PROFILE_PATH" use-system-font false
    gsettings set "org.gnome.Terminal.Legacy.Profile:$PROFILE_PATH" font 'FiraCode Nerd Font 12'

    echo "✅ Terminal font updated."
else
    echo "⚠️ Could not auto-configure terminal."
fi

echo "🧪 Testing glyph:"
echo ""

echo "🚀 Done! Restart your terminal if needed."

# -----------------------------
# Fix ç (Gnome)
# -----------------------------
echo "Fixing ç character issue..."

wget -q https://raw.githubusercontent.com/marcopaganini/gnome-cedilla-fix/master/fix-cedilla -O fix-cedilla
chmod 755 fix-cedilla
./fix-cedilla

rm -f "fix-cedilla"

# -----------------------------
# Instal localsend
# -----------------------------

echo "Installing LocalSend via Flatpak..."

# No need to install flatpak or add flathub; they are already there on Mint!
flatpak install -y flathub org.localsend.localsend_app

echo "------------------------------------------"
echo "LocalSend installation complete!"
echo "You can find it in your Internet/Network menu."

# -----------------------------
# Brave Browser
# -----------------------------
echo "Installing Brave..."
curl -fsS https://dl.brave.com/install.sh | sudo sh

# -----------------------------
# Steam
# -----------------------------
echo "Installing Steam..."
sudo apt install -y steam

# -----------------------------
# Node.js (via NVM)
# -----------------------------
echo "Installing NVM (Node Version Manager)..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.7/install.sh | bash

# Load NVM immediately (important for scripts)
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Ensure NVM is available in Zsh (the default shell configured above)
if ! grep -q 'NVM_DIR=.*\.nvm' "$HOME/.zshrc"; then
cat << 'EOF' >> "$HOME/.zshrc"

# NVM (Node Version Manager)
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
EOF
fi

echo "Installing latest Node.js..."
nvm install --lts
nvm use --lts

zsh -ic "source ~/.zshrc"

# -----------------------------
# scrcpy
# -----------------------------

echo "==> Installing scrcpy..."
sudo apt update
sudo apt install -y ffmpeg libsdl2-2.0-0 adb wget \
    gcc git pkg-config meson ninja-build libsdl2-dev \
    libavcodec-dev libavdevice-dev libavformat-dev libavutil-dev \
    libswresample-dev libusb-1.0-0 libusb-1.0-0-dev

echo "==> Cloning scrcpy..."
if [ ! -d "scrcpy" ]; then
    git clone https://github.com/Genymobile/scrcpy
fi

cd scrcpy

echo "==> Building and installing scrcpy..."
./install_release.sh

echo "==> Adding scrcpy helper function to ~/.zshrc..."

# Append function only if not already present
if ! grep -q "scrcpy_full()" ~/.zshrc; then
cat << 'EOF' >> ~/.zshrc

# Scrcpy with mouse, keyboard, and audio
mobile() {
    scrcpy \
        --audio-source=output \
        --keyboard=uhid \
        --mouse=uhid \
        --max-size=1024 \
        --video-bit-rate=18M \
        --max-fps=60 \
        --render-driver=opengl \
        "$@"
}

EOF
fi

echo "==> Done!"
echo "Restart your terminal or run: source ~/.zshrc"
zsh -ic "source ~/.zshrc"

# -----------------------------
# Docker
# -----------------------------

echo "==> Updating package index and installing prerequisites..."
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

echo "==> Adding Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "==> Setting up the repository (mapping Mint to Ubuntu base)..."
# O Linux Mint usa a variável UBUNTU_CODENAME no /etc/os-release
. /etc/os-release
UBUNTU_BASE=${UBUNTU_CODENAME:-$VERSION_CODENAME}

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $UBUNTU_BASE stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "==> Installing Docker Engine, CLI, and Compose..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> Managing Docker as a non-root user (Post-install)..."
# Cria o grupo se não existir e adiciona o usuário atual
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

echo "==> Enabling and starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

echo "==> Running Hello-World container..."
# Nota: Como o grupo acabou de ser associado, precisamos do 'sg' 
# para rodar o comando com o novo grupo sem deslogar da sessão atual.
docker run hello-world

echo "==> Done!"
echo "Para aplicar a permissão do grupo permanentemente no seu terminal atual, execute:"
echo "newgrp docker"

# -----------------------------
# Build tools
# -----------------------------
echo "Installing build-essential..."
sudo apt install -y build-essential


# -----------------------------
# steam
# -----------------------------
echo "Installing steam..."
sudo apt install -y steam

echo "🎉🎉🎉 Setup complete! 🎉🎉🎉"
