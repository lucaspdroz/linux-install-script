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
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash

# Load NVM immediately (important for scripts)
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

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
# Build tools
# -----------------------------
echo "Installing build-essential..."
sudo apt install -y build-essential


# -----------------------------
# steam
# -----------------------------
echo "Installing steam..."
sudo apt install -y steam

echo "Setup complete!"
