{
  flake.modules.nixos.tools = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [tree];

    environment.shellAliases = {
      nix-switch = "nixos-rebuild switch --flake /home/z/zrc/zx#zx --impure --sudo";
      c = "clear";
      t = "tree -al -I '.venv|.git'";
      l = "ls -AS";
      ll = "ls -AlSh";
    };

    users.defaultUserShell = pkgs.zsh;

    programs.zsh.enable = true;
    environment.pathsToLink = ["/share/zsh"];
  };

  flake.modules.homeManager.tools = {
    programs = {
      zsh = {
        enable = true;
        setOptions = [
          "interactivecomments"
          "appendhistory"
          "sharehistory"
          "incappendhistory"
          "histignorealldups"
        ];
        defaultKeymap = "viins";
        initContent =
          # zsh
          ''
            print_osc7() {
              if [ "$ZSH_SUBSHELL" -eq 0 ]; then
                printf "\033]7;file://$PWD\033\\"
              fi
            }
            autoload -Uz add-zsh-hook
            add-zsh-hook -Uz chpwd print_osc7
            print_osc7

            zstyle ':completion:*' menu select

            bindkey -v
            export KEYTIMEOUT=1

            function zle-keymap-select zle-line-init {
              case $KEYMAP in
                vicmd) print -n '\e[2 q';;
                viins|main) print -n '\e[6 q';;
              esac
            }
            zle -N zle-line-init
            zle -N zle-keymap-select

            function preexec { print -n '\e[2 q' }

            function vi-yank-pbcopy { zle vi-yank; echo "$CUTBUFFER" | pbcopy }
            zle -N vi-yank-pbcopy
            bindkey -M vicmd 'y' vi-yank-pbcopy

            function vi-put-after-pbcopy { CUTBUFFER=$(pbpaste); zle vi-put-after }
            zle -N vi-put-after-pbcopy
            bindkey -M vicmd 'p' vi-put-after-pbcopy

            function vi-put-before-pbcopy { CUTBUFFER=$(pbpaste); zle vi-put-before }
            zle -N vi-put-before-pbcopy
            bindkey -M vicmd 'P' vi-put-before-pbcopy

            bindkey '^[[Z' reverse-menu-complete
            bindkey -v '^?' backward-delete-char
            bindkey -M vicmd -r :
            bindkey -M vicmd "^U" vi-change-whole-line
            bindkey -M vicmd "^E" vi-add-eol
            bindkey -M vicmd "^A" vi-insert-bol
            bindkey -M vicmd "^K" vi-change-eol
            bindkey -M viins "^A" beginning-of-line
            bindkey -M viins "^E" end-of-line
            bindkey -M viins "^K" kill-line
            bindkey -M viins "^L" clear-screen
            bindkey -M viins "^W" backward-kill-word
            bindkey -M viins "^Y" yank
            bindkey -M viins "^U" kill-whole-line
            bindkey -M viins "^P" history-search-backward
            bindkey -M viins "^N" history-search-forward

            prompt="%n@%m %1~ %# "
          '';
      };
      bash = {
        enable = true;
        initExtra =
          # bash
          ''
            function print_osc7() {
              printf "\033]7;file://$PWD\033\\"
            }
            PROMPT_COMMAND='print_osc7'
          '';
      };
      nushell = {
        enable = true;
        settings = {
          edit_mode = "vi";
          cursor_shape = {
            emacs = "line";
            vi_insert = "line";
            vi_normal = "block";
          };
        };
      };
      readline = {
        enable = true;
        variables = {
          keyseq-timeout = 0;
          editing-mode = "vi";
          show-mode-in-prompt = "on";
          vi-cmd-mode-string = ''"\1\e[2 q\2"'';
          vi-ins-mode-string = ''"\1\e[6 q\2"'';
        };
        bindings = {
          "\\C-a" = "beginning-of-line";
          "\\C-b" = "backward-char";
          "\\C-e" = "end-of-line";
          "\\C-f" = "forward-char";
          "\\C-j" = "next-history";
          "\\C-k" = "previous-history";
          "\\C-l" = "clear-screen";
          "\\C-r" = "reverse-search-history";
          "\\C-s" = "forward-search-history";
          "\\C-u" = "unix-line-discard";
          "\\C-w" = "backward-kill-word";
          "\\C-y" = "copy-region-as-kill";
        };
      };
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      zoxide.enable = true;
      fd = {
        enable = true;
        hidden = true;
      };
      ripgrep.enable = true;
      ripgrep-all.enable = true;
      fzf = {
        enable = true;
        defaultOptions = [
          "--bind 'tab:down,shift-tab:up'"
          "--cycle"
        ];
      };
      gh = {
        enable = true;
        settings.git_protocol = "ssh";
        hosts = {
          "github.com" = {
            user = "tnxz";
          };
        };
      };
      git = {
        enable = true;
        settings = {
          user = {
            name = "tnxz";
            email = "tnxz@protonmail.com";
          };
          init.defaultBranch = "main";
        };
      };
      lazygit = {
        enable = true;
        settings = {
          gui = {
            border = "single";
            showCommandLog = false;
            showBottomLine = false;
          };
          git = {
            autoFetch = false;
          };
        };
      };
      lazydocker = {
        enable = true;
        settings = {
          gui = {
            border = "single";
            showCommandLog = false;
            showBottomLine = false;
          };
        };
      };
    };
  };
}
