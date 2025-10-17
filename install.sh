#!/bin/bash

# Dartango Framework SDK Installer
# Installs Dartango globally on your system

set -e

DARTANGO_VERSION="1.0.0"
DARTANGO_HOME="$HOME/.dartango"
DARTANGO_BIN="$DARTANGO_HOME/bin"
DARTANGO_PACKAGES="$DARTANGO_HOME/packages"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    Dartango Framework SDK                    ║"
echo "║                   Django for Dart Developers                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}Installing Dartango SDK v$DARTANGO_VERSION...${NC}"

# Check if Dart is installed
if ! command -v dart &> /dev/null; then
    echo -e "${RED}Error: Dart SDK not found!${NC}"
    echo "Please install Dart SDK first: https://dart.dev/get-dart"
    exit 1
fi

# Check if Flutter is installed (optional but recommended)
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}Warning: Flutter not found. Flutter is required for admin interface.${NC}"
    echo "Install Flutter from: https://flutter.dev/docs/get-started/install"
fi

echo -e "${BLUE}Creating Dartango SDK directory...${NC}"
mkdir -p "$DARTANGO_HOME"
mkdir -p "$DARTANGO_BIN"
mkdir -p "$DARTANGO_PACKAGES"

echo -e "${BLUE}Installing Dartango packages...${NC}"

# Copy the entire dartango project to SDK location
cp -r "$(dirname "$0")/packages" "$DARTANGO_HOME/"
cp -r "$(dirname "$0")/examples" "$DARTANGO_HOME/"
cp -r "$(dirname "$0")/docs" "$DARTANGO_HOME/"

# Create the global dartango CLI script
cat > "$DARTANGO_BIN/dartango" << 'EOF'
#!/bin/bash

# Dartango Framework CLI
# Global entry point for Dartango commands

DARTANGO_HOME="${DARTANGO_HOME:-$HOME/.dartango}"
DARTANGO_CLI="$DARTANGO_HOME/packages/dartango_cli/bin/dartango.dart"

if [ ! -f "$DARTANGO_CLI" ]; then
    echo "Error: Dartango SDK not found at $DARTANGO_HOME"
    echo "Please reinstall Dartango SDK"
    exit 1
fi

# Run the Dartango CLI with all arguments
exec dart run "$DARTANGO_CLI" "$@"
EOF

# Make the CLI script executable
chmod +x "$DARTANGO_BIN/dartango"

echo -e "${BLUE}Installing dependencies...${NC}"

# Install CLI dependencies
cd "$DARTANGO_HOME/packages/dartango_cli"
dart pub get > /dev/null 2>&1

# Install core framework dependencies  
cd "$DARTANGO_HOME/packages/dartango"
dart pub get > /dev/null 2>&1

# Install admin dependencies
cd "$DARTANGO_HOME/packages/dartango_admin" 
flutter pub get > /dev/null 2>&1

echo -e "${BLUE}Setting up PATH...${NC}"

# Detect shell and update PATH
SHELL_PROFILE=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_PROFILE="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_PROFILE="$HOME/.bash_profile"
elif [ -f "$HOME/.profile" ]; then
    SHELL_PROFILE="$HOME/.profile"
fi

if [ -n "$SHELL_PROFILE" ]; then
    # Check if DARTANGO_BIN is already in PATH
    if ! grep -q "DARTANGO_HOME" "$SHELL_PROFILE"; then
        echo "" >> "$SHELL_PROFILE"
        echo "# Dartango SDK" >> "$SHELL_PROFILE"
        echo "export DARTANGO_HOME=\"$DARTANGO_HOME\"" >> "$SHELL_PROFILE"
        echo "export PATH=\"\$DARTANGO_HOME/bin:\$PATH\"" >> "$SHELL_PROFILE"
        echo -e "${GREEN}Added Dartango to PATH in $SHELL_PROFILE${NC}"
    else
        echo -e "${YELLOW}Dartango already in PATH${NC}"
    fi
fi

# Create version file
echo "$DARTANGO_VERSION" > "$DARTANGO_HOME/VERSION"

# Create SDK info file
cat > "$DARTANGO_HOME/SDK_INFO" << EOF
Dartango Framework SDK
Version: $DARTANGO_VERSION
Install Date: $(date)
Install Path: $DARTANGO_HOME

Packages:
- dartango (core framework)
- dartango_cli (command line tools)  
- dartango_admin (Flutter admin interface)
- dartango_shared (shared utilities)

Documentation: $DARTANGO_HOME/docs/
Examples: $DARTANGO_HOME/examples/
EOF

echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                 🎉 Installation Complete! 🎉                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${GREEN}✅ Dartango SDK v$DARTANGO_VERSION installed successfully!${NC}"
echo -e "${BLUE}📍 Installation directory: $DARTANGO_HOME${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Restart your terminal or run: source $SHELL_PROFILE"
echo "2. Verify installation: dartango --version"
echo "3. Create your first project: dartango create my_project"
echo "4. Start developing: cd my_project && dartango serve"
echo ""
echo -e "${BLUE}🚀 Happy coding with Dartango!${NC}"
echo ""
echo -e "${YELLOW}Documentation: https://dartango.dev/docs${NC}"
echo -e "${YELLOW}Examples: $DARTANGO_HOME/examples/${NC}"