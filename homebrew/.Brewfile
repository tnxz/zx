# vim:ft=ruby
system "defaults write -g ApplePressAndHoldEnabled -bool false"
system "defaults write -g InitialKeyRepeat -int 10"
system "defaults write -g KeyRepeat -int 1"
system "defaults write com.apple.dock persistent-apps -array"

tap "yihui/tinytex"
tap "oven-sh/bun"

cask "brave-browser", greedy: true
cask "font-iosevka-ss03", greedy: true
cask "iina", greedy: true
cask "ghostty", greedy: true
cask "raycast", greedy: true

brew "bob", postinstall: "/opt/homebrew/bin/bob use nightly"

brew "openjdk", postinstall: <<~BASH
  mkdir -p "$HOME/Library/Java/JavaVirtualMachines"
  ln -sfn "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk" "$HOME/Library/Java/JavaVirtualMachines/openjdk.jdk"
BASH

brew "go", postinstall: "/opt/homebrew/bin/go telemetry off"

brew "uv", postinstall: <<~BASH
  /opt/homebrew/bin/uv tool install --python 3.13 --with="setuptools,audioop-lts" manimgl
  /opt/homebrew/bin/uv tool install --python 3.13 manim
  /opt/homebrew/bin/uv tool install yt-dlp
BASH

brew "yihui/tinytex/tinytex", args: ["HEAD"], postinstall: <<~BASH
  /opt/homebrew/bin/tlmgr install amsmath babel-english cbfonts-fd cm-super count1to ctex doublestroke dvisvgm everysel fontspec frcursive fundus-calligra gnu-freefont jknapltx latex-bin mathastext microtype multitoc physics preview prelim2e ragged2e relsize rsfs setspace standalone tipa wasy wasysym xcolor xetex xkeyval
  /opt/homebrew/bin/brew postinstall tinytex
  /opt/homebrew/bin/brew unlink tinytex
  /opt/homebrew/bin/brew link tinytex
BASH

brew "oven-sh/bun/bun"

brew "alejandra"
brew "fd"
brew "ffmpeg"
brew "fzf"
brew "gh"
brew "gofumpt"
brew "goimports"
brew "google-java-format"
brew "gopls"
brew "imagemagick"
brew "jdtls"
brew "lazygit"
brew "lua-language-server"
brew "node"
brew "nushell"
brew "pyright"
brew "python@3.13"
brew "python@3.14"
brew "ripgrep"
brew "ruff"
brew "rust"
brew "rust-analyzer"
brew "stow"
brew "stylua"
brew "tree"
brew "ty"
brew "typescript-language-server"
brew "zig"
brew "zls"
brew "zoxide"
