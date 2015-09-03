#!/usr/bin/env zsh

if [[ "$OSTYPE" =~ ^(darwin)+ ]]; then
  info () {
    # shellcheck disable=SC2059
    printf "[ \033[00;34m...\033[0m ] $1\n"
  }
  
  user () {
    # shellcheck disable=SC2059
    printf "\r  [ \033[0;33m?\033[0m ] $1 "
  }
  
  success () {
    # shellcheck disable=SC2059
    printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
  }
  
  error () {
    # shellcheck disable=SC2059
    printf "\r\033[2K  [ \033[0;31mERROR\033[0m ] $1\n"
    echo ''
  }

  # Get OS X Software Updates, and update installed Ruby gems, Homebrew, npm, and their installed packages
  installed() {
    command -v "${1}" >/dev/null 2>&1 && info "${1}" || return false
  }
  
  # TODO: verify the error output works correctly...
  update() {
    if [[ "$1" == "-osx" ]]; then
      # Keep-alive: update existing `sudo` time stamp until `update` has finished
      sudo -v && while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
      info "OS X Packages" && sudo softwareupdate -i -a || error "Updating OS X packages"
    fi
    
    installed "brew" && (brew update; brew upgrade --all; brew cleanup; brew cask cleanup;) && success "Updated brew" || error "Updating brew"
    installed "npm" && (npm install npm -g; npm update -g;) && success "Updated npm" || error "Updating npm"
    installed "gem" && (sudo gem update --system; sudo gem update) && success "Updated gem" || error "Updating gem"
    # upgrade outdated pip packages...
    installed "pip" && (pip install --upgrade pip && pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U) && success "Updated pip" || error "Updating pip"
    installed "pip3" && (pip3 install --upgrade pip && pip3 freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip3 install -U) && success "Updated pip3" || error "Updating pip3"
  }
  
  # IP addresses
  alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"
  
  # Flush Directory Service cache
  alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"
  
  # Clean up LaunchServices to remove duplicates in the “Open With” menu
  alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"
  
  # View HTTP traffic
  alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
  alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""
  
  # Canonical hex dump; some systems have this symlinked
  command -v hd > /dev/null || alias hd="hexdump -C"
  
  # OS X has no `md5sum`, so use `md5` as a fallback
  command -v md5sum > /dev/null || alias md5sum="md5"
  
  # OS X has no `sha1sum`, so use `shasum` as a fallback
  command -v sha1sum > /dev/null || alias sha1sum="shasum"
  
  # JavaScriptCore REPL
  jscbin="/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc";
  [ -e "${jscbin}" ] && alias jsc="${jscbin}";
  unset jscbin;
  
  # Trim new lines and copy to clipboard
  alias c="tr -d '\n' | pbcopy"
  
  # Empty the Trash on all mounted volumes and the main HDD
  # Also, clear Apple’s System Logs to improve shell startup speed
  alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl"
  
  # Show/hide hidden files in Finder
  alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
  alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"
  
  # Hide/show all desktop icons (useful when presenting)
  alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
  alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"
  
  # URL-encode strings
  alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'
  
  # Merge PDF files
  # Usage: `mergepdf -o output.pdf input{1,2,3}.pdf`
  alias mergepdf='/System/Library/Automator/Combine\ PDF\ Pages.action/Contents/Resources/join.py'
  
  # PlistBuddy alias, because sometimes `defaults` just doesn’t cut it
  alias plistbuddy="/usr/libexec/PlistBuddy"
  
  # Ring the terminal bell, and put a badge on Terminal.app’s Dock icon
  # (useful when executing time-consuming commands)
  alias badge="tput bel"
  
  # Intuitive map function
  # For example, to list all directories that contain a certain file:
  # find . -name .gitattributes | map dirname
  alias map="xargs -n1"
  
  # One of @janmoesen’s ProTip™s
  for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
    alias "$method"="lwp-request -m '$method'"
  done
  
  # Stuff I never really use but cannot delete either because of http://xkcd.com/530/
  alias stfu="osascript -e 'set volume output muted true'"
  alias pumpitup="osascript -e 'set volume 7'"
  
  # Diff
  alias gdiff='git diff --no-index --color-words '
  alias diff2='diff -y --suppress-common-lines '
  
  # turn ethernet on/off
  alias ethoff="sudo networksetup setnetworkserviceenabled 'Ethernet 1' off"
  alias ethon="sudo networksetup setnetworkserviceenabled 'Ethernet 1' on"
  
  trash() {
    if [[ "$1" =~ ^[-]?[aA]{1}(ll)*$ ]]; then
        sudo rm -rvf ~/Library/Logs/*
        sudo rm -rvf /Library/Logs/*
        sudo rm -rvf /var/log/*
        sudo rm -rfv /Volumes/*/.Trashes
    elif [[ "$1" =~ ^[-]?[uU]{1}(ser)*$ ]]; then
        rm -rvf ~/Library/Logs/*
    fi
    rm -rfv ~/.Trash/*
    rm -rfv ~/.Trash/.*
  }
fi
