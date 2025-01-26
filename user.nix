{ config, pkgs, ... }:

{
    home.username = "nixos";
    home.homeDirectory = "/home/nixos";

    # Declare Home Manager state version
    home.stateVersion = "23.05";

    # Enable Bash autocompletion for commands
    programs.bash.enableCompletion = true;

    # Enable and configure Git
    programs.git = {
        enable = true;
        userName = "davidgatti";
        userEmail = "411114+davidgatti@users.noreply.github.com";
    };

    # Add a few system packages for the user
    home.packages = with pkgs; [
        tree
        gh
        jq
        btop
        git
        cmatrix
        fzf
        neofetch
        mesa-demos
        radeontop
        handbrake

        # Tools
        mc
        zip
        pv

        # Games
        bastet
        nudoku

        # Fun
        asciiquarium
        sl
        tty-clock
        nyancat
    ];

    # Enable Bash and customize the prompt
    programs.bash = {
        enable = true;
      
        # Set up custom aliases
        shellAliases = {
            ll = "ls -alh";                 # Convenient alias for directory listing
            ls = "ls --color=auto";         # Auto color for ls
            search = "fzf";                 # Fuzzy finder
            system_info = "neofetch";       # System info utility
        };
      
        # Add custom configurations and export variables
        initExtra = ''
            # .bashrc

            # Source global definitions
            if [ -f /etc/bashrc ]; then
            	. /etc/bashrc
            fi
            
            # User-specific environment
            if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
                PATH="$HOME/.local/bin:$HOME/bin:$PATH"
            fi
            
            # Export all the combined string.
            export PATH
            
            # Disable systemctl's auto-paging feature where it sends the output to less.
            export SYSTEMD_PAGER=
            
            # User-specific aliases and functions
            if [ -d ~/.bashrc.d ]; then
            	for rc in ~/.bashrc.d/*; do
            		if [ -f "$rc" ]; then
            			. "$rc"
            		fi
            	done
            fi
            
            unset rc
            
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
            
            function has_uncommitted_changes() {
                git diff --quiet && git diff --cached --quiet || echo " "
            }
            
            function simple_git_branch_and_status() {
                branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
                if [ -n "$branch" ]; then
                    changes=$(has_uncommitted_changes)
                    echo "($branch)$changes"
                fi
            }
            
            # Customize the bash prompt with auto-updating Git branch
            PROMPT_COMMAND='PS1="\[\e[0;30;48;2;255;0;0m\] \u][\W  $(simple_git_branch_and_status)\[\e[0m\]\[\e[38;2;255;0;0m\]\[\e[0m\] "'

        '';
    };

    # Replace Code-Server settings.json
    home.file.".local/share/code-server/User/settings.json".text = ''
    {
      "workbench.colorTheme": "Default Dark+",
      "editor.fontSize": 12,
      "terminal.integrated.fontSize": 12,
      "terminal.integrated.cwd": "/home/nixos",
      "explorer.confirmDelete": true,
      "files.autoSave": "onWindowChange",
      "explorer.compactFolders": false,
      "workbench.tree.indent": 16,
      "workbench.colorCustomizations": {
          "terminal.background": "#000000",
          "terminal.foreground": "#cc0000",
          "terminalCursor.foreground": "#ff0000",
          "terminal.ansiBlack": "#000000",
          "terminal.ansiRed": "#ff0000",
          "terminal.ansiGreen": "#006400",
          "terminal.ansiYellow": "#b8860b",
          "terminal.ansiBlue": "#8B0000",
          "terminal.ansiMagenta": "#ff1493",
          "terminal.ansiCyan": "#00ced1",
          "terminal.ansiWhite": "#d3d3d3",
          "terminal.ansiBrightBlack": "#696969",
          "terminal.ansiBrightRed": "#ff0000",
          "terminal.ansiBrightGreen": "#32cd32",
          "terminal.ansiBrightYellow": "#ffd700",
          "terminal.ansiBrightBlue": "#ff0000",
          "terminal.ansiBrightMagenta": "#ff69b4",
          "terminal.ansiBrightCyan": "#e0ffff",
          "terminal.ansiBrightWhite": "#ffffff",
          "statusBar.background": "#8b0000",
          "statusBar.foreground": "#ffffff",
          "statusBar.debuggingBackground": "#ff0000",
          "statusBar.debuggingForeground": "#ffffff",
          "statusBarItem.remoteBackground": "#8b0000",
          "statusBarItem.remoteForeground": "#ffffff",
          "terminal.tab.activeBackground": "#8b0000",
          "terminal.tab.activeForeground": "#ffffff",
          "terminal.tab.inactiveBackground": "#660000",
          "terminal.tab.inactiveForeground": "#d3d3d3"
      },
      "terminal.integrated.fontFamily": "'Hack Nerd Font', monospace",
      "terminal.integrated.cursorStyle": "block",
      "git.enableSmartCommit": true,
      "git.confirmSync": false,
      "terminal.integrated.autoFocus": true,
      "editor.suggest.showComments": false,
      "docker.containers.sortBy": "Label",
      "search.followSymlinks": false
    }
    '';
}
