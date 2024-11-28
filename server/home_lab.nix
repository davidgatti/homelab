{ config, pkgs, ... }:

{
  home.username = "nixos";  # Replace with your actual username
  home.homeDirectory = "/home/nixos";  # Adjust if your home directory is different

  # Declare Home Manager state version
  home.stateVersion = "23.05";  # Match the release of Home Manager you installed

  # Enable Bash autocompletion for commands
  programs.bash.enableCompletion = true;

  # Enable and configure Git
  programs.git = {
    enable = true;
    userName = "davidgatti";  # Replace with your actual name
    userEmail = "411114+davidgatti@users.noreply.github.com";  # Replace with your actual email
  };

  # Add a few system packages for the user
  home.packages = with pkgs; [
    tree    # Directory listing in tree format
    gh
    btop
    git
    cmatrix
    fzf
    neofetch
    mesa-demos
    radeontop
    handbrake
    tmux

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
      ll = "ls -alh";  # Convenient alias for directory listing
      ls = "ls --color=auto";
      search = "fzf";
      system_info = "neofetch";
    };

    # Download git-prompt.sh if not available and source it in the prompt
    initExtra = ''
      # Check if git-prompt.sh exists; if not, download it
      if [ ! -f ~/.git-prompt.sh ]; then
        curl -o ~/.git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
      fi

      # Source git-prompt.sh to enable Git info in the prompt
      source ~/.git-prompt.sh

      # Set options for Git prompt
      export GIT_PS1_SHOWDIRTYSTATE=1
      export GIT_PS1_SHOWUNTRACKEDFILES=1

      # Customize the bash prompt
      export PS1="\[\e[0;30;48;2;255;0;0m\] \u][\W  $(__git_ps1 '%s')\[\e[0m\]\[\e[38;2;255;0;0m\]\[\e[0m\] "

    '';
  };

  # Create a configuration file for code-server
  # Create configuration files for code-server and Neovim
  home.file = {
    ".local/share/code-server/User/settings.json" = {
      force = true;
      text = ''
        {
          "workbench.colorTheme": "Default Dark+",
          "editor.fontSize": 12,
          "terminal.integrated.fontSize": 12,
          "explorer.confirmDelete": true,
          "files.autoSave": "onWindowChange",
          "explorer.compactFolders": false,
          "workbench.tree.indent": 16,
          "terminal.integrated.fontFamily": "'Hack Nerd Font', monospace",
          "terminal.integrated.cursorStyle": "block",
          "git.enableSmartCommit": true,
          "git.confirmSync": false,
          "editor.cursorBlinking": "smooth",
          "editor.bracketPairColorization.enabled": true,
          "editor.guides.bracketPairs": "active",
          "editor.stickyScroll.enabled": false,
          "workbench.editor.enablePreview": false,
          "editor.rulers": [ 80 ],
          "editor.minimap.enabled": false,
          "workbench.colorCustomizations": {
              "terminal.background": "#000000",
              "terminal.foreground": "#cc0000",
              "terminalCursor.foreground": "#FFD700",
              "terminal.ansiBlack": "#000000",
              "terminal.ansiRed": "#ff0000",
              "terminal.ansiGreen": "#006400",
              "terminal.ansiYellow": "#FFD700",
              "terminal.ansiBlue": "#8B0000",
              "terminal.ansiMagenta": "#ff1493",
              "terminal.ansiCyan": "#FFD700",
              "terminal.ansiWhite": "#d3d3d3",
              "terminal.ansiBrightBlack": "#696969",
              "terminal.ansiBrightRed": "#ff0000",
              "terminal.ansiBrightGreen": "#FFD700",
              "terminal.ansiBrightYellow": "#FFD700",
              "terminal.ansiBrightBlue": "#FFD700",
              "terminal.ansiBrightMagenta": "#FFD700",
              "terminal.ansiBrightCyan": "#FFD700",
              "terminal.ansiBrightWhite": "#ffffff",
              "statusBar.background": "#8b0000",
              "statusBar.foreground": "#ffffff",
              "statusBar.debuggingBackground": "#ff0000",
              "statusBar.debuggingForeground": "#ffffff",
              "statusBarItem.remoteBackground": "#8b0000",
              "statusBarItem.remoteForeground": "#FFD700",
              "terminal.tab.activeBackground": "#8b0000",
              "terminal.tab.activeForeground": "#FFD700",
              "terminal.tab.inactiveBackground": "#660000",
              "terminal.tab.inactiveForeground": "#d3d3d3"
          },
          "workbench.startupEditor": "none",
          "aws.suppressPrompts": {
              "ecsRunCommand": true
          },
          "terminal.integrated.shellIntegration.enabled": true
      }
      '';
    };
  };


}
