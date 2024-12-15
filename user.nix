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
            # History configurations
            export HISTFILESIZE=100000
            export HISTSIZE=10000
            shopt -s histappend
            shopt -s checkwinsize
            shopt -s extglob
            shopt -s globstar
            shopt -s checkjobs
        
            # Download and source git-prompt.sh if not present
            if [ ! -f ~/.git-prompt.sh ]; then
            curl -o ~/.git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
            fi

            source ~/.git-prompt.sh
        
            # Set options for Git prompt
            export GIT_PS1_SHOWDIRTYSTATE=1
            export GIT_PS1_SHOWUNTRACKEDFILES=1
        
            # Customize the bash prompt
            export PS1="\[\e[0;30;48;2;255;0;0m\] \u][\W  $(__git_ps1 '%s')\[\e[0m\]\[\e[38;2;255;0;0m\]\[\e[0m\] "
        '';
      };      
}
