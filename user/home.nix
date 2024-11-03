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
    tree
    gh
    btop
    git
    cmatrix
    fzf
    neofetch
    mesa-demos
    radeontop
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

    # Customize the Bash prompt
    initExtra = ''
      export PS1="\[\e[35m\][\u@\h \A] \[\e[33m\]\w\[\e[0m\]\$ "
    '';
  };

  
}
