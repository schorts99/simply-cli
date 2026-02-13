#!/bin/bash

# Ensure ~/.local/bin exists
mkdir -p "$HOME/.local/bin"

# Get git user name and email
GIT_USER_NAME=$(git config user.name)
GIT_USER_EMAIL=$(git config user.email)

# Use placeholders if git is not configured
if [ -z "$GIT_USER_NAME" ]; then
  GIT_USER_NAME="Author Name"
fi

if [ -z "$GIT_USER_EMAIL" ]; then
  GIT_USER_EMAIL="author@example.com"
fi

# Create a personalized design doc in ~/.simply
mkdir -p "$HOME/.simply"
cp resources/design-doc.md "$HOME/.simply/design-doc.md"

# Personalize the design doc
sed -i "s/AUTHOR_NAME/$GIT_USER_NAME/g" "$HOME/.simply/design-doc.md"
sed -i "s/AUTHOR_EMAIL/$GIT_USER_EMAIL/g" "$HOME/.simply/design-doc.md"

# Create the simply script in ~/.local/bin
cat > "$HOME/.local/bin/simply" <<EOL
#!/bin/bash

# Define the create design-doc command
if [ "\$1" == "create" ] && [ "\$2" == "design-doc" ]; then
  cp "$HOME/.simply/design-doc.md" ./
  echo "design-doc.md created"
else
  echo "Usage: simply create design-doc"
fi
EOL

# Make the simply script executable
chmod +x "$HOME/.local/bin/simply"

echo "simply CLI installed successfully to ~/.local/bin."

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo "WARNING: ~/.local/bin is not in your PATH."
  echo "Please add the following line to your shell's rc file (e.g., ~/.bashrc, ~/.zshrc):"
  echo 'export PATH="$HOME/.local/bin:$PATH"'
  echo "Then, restart your terminal or run 'source ~/.bashrc' (or your respective rc file)."
fi

echo "You can now use the 'simply create design-doc' command."
