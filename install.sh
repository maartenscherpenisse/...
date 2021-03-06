#!/usr/bin/env bash

source ./lib/utilities.sh

if [[ -z "${BASH_VERSINFO[@]}" || "${BASH_VERSINFO[0]}" -lt 4 || "${BASH_VERSINFO[1]}" -lt 2 ]]; then
  echo "Requires Bash version 4.2 (you have ${BASH_VERSION:-a different shell})"
  echo "Attempting to install. Script will attmpet to restart itself. Otherwise, reload terminal when finished and try again"
fi

echo "Enter passwords upfront to continue"
if [ -z ${APPLE_ID_PASSWORD+x} ]; then
  read -s -p "Apple ID Password:" APPLE_ID_PASSWORD
  export APPLE_ID_PASSWORD=$APPLE_ID_PASSWORD
  echo ''
fi

cached_sudo -v

# Keep-alive: update existing `sudo` time stamp if set, otherwise do nothing
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Update computer's time
cached_sudo ntpdate -u us.pool.ntp.org

# Never go into computer sleep mode
cached_sudo systemsetup -setcomputersleep Off > /dev/null

# Never dim display
cached_sudo pmset force -a displaysleep 0

# Disable screensaver
defaults -currentHost write com.apple.screensaver idleTime 0

echo "Install Homebrew if not installed"
cached_psudo '/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null'

echo "Run Homebrew Doctor"
brew doctor

echo "Update Homebrew"
brew update

echo "Install coreutils"
brew install coreutils
brew upgrade coreutils

if [[ -z "${BASH_VERSINFO[@]}" || "${BASH_VERSINFO[0]}" -lt 4 || "${BASH_VERSINFO[1]}" -lt 2 ]]; then
  echo "Install Updated Bash"
  brew install bash
  brew upgrade bash

  if cat /etc/shells | grep /usr/local/bin/bash &> /dev/null; then
    echo "Add Homebrew's bash to available shells"
    cached_sudo 'bash -c "echo /usr/local/bin/bash >> /etc/shells"'
  fi

  echo "Change default shell to Homebrew bash"
  cached_sudo chsh -s /usr/local/bin/bash $(whoami)

  echo "Attempting to reload shell"
  exec bash --login -c "./install.sh"

  # Reload failed
  echo "Reload Failed. Reload terminal and try again."
  exit 1
fi

echo "Requires Bash version 4.2 (you have ${BASH_VERSION:-a different shell})"

# Switch to zsh
cached_sudo chsh -s $(which zsh) scott

# Run concurrent test

# (Re-)Download concurrent and use nocompact branch
rm -rf bash-concurrent
git clone https://github.com/sscotth/bash-concurrent
cd bash-concurrent
git checkout nocompact
cd ..

# Load concurrent tasks
bash ./lib/tasks/index.sh

# Homebrew installs (parallelize) Attempt 3 times (allowing for ctrl-c)
bash ./lib/tasks/osx/homebrew.sh
bash ./lib/tasks/osx/homebrew.sh
bash ./lib/tasks/osx/homebrew.sh

# Bundle Homebrew for missing parallelized homebrew installs
cached_psudo brew bundle --file=.Brewfile

# iTerm2 v3 Shell Integration
curl -L https://iterm2.com/misc/install_shell_integration.sh | bash

# Install atom plugins
apm stars --user sscotth --install
yes | apm upgrade

# Sublime Text 3
# Symlink settings
mkdir -p ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
ln -fs ~/.dotfiles/SublimeText/Preferences.sublime-settings ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
ln -fs ~/.dotfiles/SublimeText/highlighter.sublime-settings ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
# Install Package Control
curl https://packagecontrol.io/Package%20Control.sublime-package > ~/Library/Application\ Support/Sublime\ Text\ 3/Installed\ Packages/Package\ Control.sublime-package
# symlink requried packages
ln -sf ~/.dotfiles/SublimeText/Package\ Control.sublime-settings ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User

# Install Python apps
# Upgrade pip
pip install --upgrade pip
pip3 install --upgrade pip

# Virtual Environments for Python
pip install --upgrade virtualenv
pip3 install --upgrade virtualenv

pip install --upgrade virtualenvwrapper
pip3 install --upgrade virtualenvwrapper

# Setup directories
mkdir -p ~/code ~/.virtualenvs
WORKON_HOME=~/.virtualenvs
PROJECT_HOME=~/code
VIRTUALENVWRAPPER_SCRIPT=/usr/local/bin/virtualenvwrapper.sh
source /usr/local/bin/virtualenvwrapper_lazy.sh
workon

pip install SpoofMAC
# Finish SpoofMAC Install https://github.com/feross/SpoofMAC#startup-installation-instructions
  # Download the startup file for launchd
  curl https://raw.githubusercontent.com/feross/SpoofMAC/master/misc/local.macspoof.plist > /tmp/local.macspoof.plist

  # Customize location of `spoof-mac.py` to match your system
  cat /tmp/local.macspoof.plist | sed "s|/usr/local/bin/spoof-mac.py|`which spoof-mac.py`|" | tee /tmp/local.macspoof.plist

  # Copy file to the OS X launchd folder
  cached_sudo cp /tmp/local.macspoof.plist /Library/LaunchDaemons

  # Set file permissions
  cached_sudo chown root:wheel /Library/LaunchDaemonslocal.macspoof.plist
  cached_sudo chmod 0644 /Library/LaunchDaemonslocal.macspoof.plist

# Install Ruby
source /usr/local/opt/chruby/share/chruby/chruby.sh
ruby-install ruby
chruby ruby
gem install rails
gem install rubocop
gem install travis
gem isntall reek

# Fix asepsis failed update notifications
asepsisctl uninstall_updater

# echo "kill affected applications"
# sh kill.sh
