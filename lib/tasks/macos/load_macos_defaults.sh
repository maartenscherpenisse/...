#!/usr/bin/env bash
#
# SUDO: Load OSX defaults

load_macos_defaults () {
  mathiasbynens_macos_edit
  mathiasbynens_macos_load
  personal_macos_load

  echo "(may require restart)" >&3
}

### LOCAL ###

mathiasbynens_macos_edit () {
  echo "remove kill affected applicaitons at end of mathiasbynens .macos script"
  sed '/^# Kill affected applications/,$d' math_dotfiles/.macos > /tmp/.macos_nokill
}

mathiasbynens_macos_load () {
  echo "loading mathiasbynens' sensible hacker defaults"
  cd math_dotfiles
  yes | sh /tmp/.macos_nokill
  cd ..
}

personal_macos_load () {
  echo "loading personal macos preferences"
  sh .macos_supplement
}

load_macos_defaults