#!/bin/bash

# Dartango Framework SDK Uninstaller
# Removes Dartango SDK from your system

set -e

DARTANGO_HOME="$HOME/.dartango"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                 Dartango Framework SDK                      ║"
echo "║                      Uninstaller                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [ ! -d "$DARTANGO_HOME" ]; then
    echo -e "${YELLOW}Dartango SDK not found at $DARTANGO_HOME${NC}"
    echo "Nothing to uninstall."
    exit 0
fi

echo -e "${YELLOW}This will remove Dartango SDK from your system.${NC}"
echo -e "${RED}This action cannot be undone!${NC}"
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo -e "${BLUE}Removing Dartango SDK...${NC}"

# Remove the SDK directory
rm -rf "$DARTANGO_HOME"
echo -e "${GREEN}✅ Removed SDK directory: $DARTANGO_HOME${NC}"

# Remove from shell profiles
SHELL_PROFILES=(
    "$HOME/.zshrc"
    "$HOME/.bashrc" 
    "$HOME/.bash_profile"
    "$HOME/.profile"
)

for profile in "${SHELL_PROFILES[@]}"; do
    if [ -f "$profile" ]; then
        # Check if it contains Dartango entries
        if grep -q "DARTANGO_HOME" "$profile"; then
            echo -e "${BLUE}Removing Dartango from $profile...${NC}"
            
            # Create a backup
            cp "$profile" "$profile.dartango-backup"
            
            # Remove Dartango lines
            sed -i.tmp '/# Dartango SDK/d' "$profile"
            sed -i.tmp '/DARTANGO_HOME/d' "$profile"
            sed -i.tmp '/dartango\/bin/d' "$profile"
            rm "$profile.tmp"
            
            echo -e "${GREEN}✅ Removed from $profile (backup saved as $profile.dartango-backup)${NC}"
        fi
    fi
done

echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                🗑️  Uninstallation Complete! 🗑️               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${GREEN}✅ Dartango SDK has been removed from your system${NC}"
echo ""
echo -e "${YELLOW}Manual cleanup (optional):${NC}"
echo "1. Restart your terminal to update PATH"
echo "2. Remove any remaining Dartango projects you created"
echo "3. Shell profile backups are saved with .dartango-backup extension"
echo ""
echo -e "${BLUE}Thank you for trying Dartango! 👋${NC}"