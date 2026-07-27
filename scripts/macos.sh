#!/bin/zsh
# Sensible macOS defaults for a developer machine.
# Safe to re-run. Most settings are reversible in System Settings.

set -euo pipefail

log() {
  print -r -- "==> $*"
}

# Close System Settings so defaults take effect cleanly when possible.
osascript -e 'tell application "System Settings" to quit' >/dev/null 2>&1 || true
osascript -e 'tell application "System Preferences" to quit' >/dev/null 2>&1 || true

###############################################################################
# General UI / UX
###############################################################################
log "General UI"

# Expand save and print panels by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable the "Are you sure you want to open this application?" dialog for good
defaults write com.apple.LaunchServices LSQuarantine -bool false

###############################################################################
# Keyboard
###############################################################################
log "Keyboard"

# Fast key repeat (lower is faster; 1–2 is aggressive)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Full keyboard access (Tab in dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

###############################################################################
# Trackpad
###############################################################################
log "Trackpad"

# Tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

###############################################################################
# Finder
###############################################################################
log "Finder"

# Show path bar and status bar
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Use list view in all Finder windows by default
# Four-letter codes: icnv, Nlsv, clmv, Flwv
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

###############################################################################
# Screenshots
###############################################################################
log "Screenshots"

screenshot_dir="$HOME/Desktop/Screenshots"
mkdir -p "$screenshot_dir"
defaults write com.apple.screencapture location -string "$screenshot_dir"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

###############################################################################
# Dock
###############################################################################
log "Dock"

# Reasonable icon size; do not force autohide
defaults write com.apple.dock tilesize -int 48

# Minimize windows into their application icon
defaults write com.apple.dock minimize-to-application -bool true

# Do not show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Faster Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

###############################################################################
# Activity Monitor / Misc
###############################################################################
log "Misc"

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Auto-play videos when opened with QuickTime Player
defaults write com.apple.QuickTimePlayerX MGPlayMovieOnOpen -bool true

###############################################################################
# Apply
###############################################################################
log "Restarting affected apps"

for app in "Dock" "Finder" "SystemUIServer"; do
  killall "$app" >/dev/null 2>&1 || true
done

log "macOS defaults applied"
log "Some changes may need a logout/restart to fully take effect"
