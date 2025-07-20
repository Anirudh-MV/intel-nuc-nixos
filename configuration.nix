# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nuc = {
    isNormalUser = true;
    description = "nuc";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable zsh
  # commented because it's not working as the default shell. and bash shell is working alright
  # programs.zsh.enable = true;
  # programs.zsh.syntaxHighlighting.enable = true;
  # programs.zsh.ohMyZsh.enable = true;
  # programs.zsh.ohMyZsh.theme = "gnzh";


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
   vim
   neovim
   tailscale
   vscode
   dig # helpful DNS utility
   busybox # common linux utils - nslookup/printf
   xrdp # remote desktop
   git
   uptime-kuma
   ethtool
   networkd-dispatcher
   tmux
   gcc
   btop
  ];

  environment.shellAliases = {
    sudovim = "sudo -E -s nvim";
    sudonvim = "sudo -E -s nvim";
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages;
  [
    akonadi # The backend for Kontact (email, calendar, contacts, etc.)
    kmail # The KDE email client
    korganizer # The KDE calendar application
    kaddressbook # The KDE address book
    kontact # The KDE PIM suite (meta-package for the above)
    plasma-vault # For encrypted data vaults (optional, but often unwanted)
    elisa
    kwalletmanager
  ];

  systemd.user.services.akonadi-server.enable = false;
  systemd.user.services.akonadi-server.wantedBy = [ ];

  services.tailscale.enable = true;
  services.tailscale.extraSetFlags = ["--advertise-routes=172.30.0.0/16"];

  services.xrdp.enable = true;
  # services.xrdp.defaultWindowManager = "${pkgs.plasma-workspace}/bin/startplasma-x11";
  services.xrdp.defaultWindowManager = "xfce4-session";
  services.xrdp.openFirewall = true;

  systemd.services.tailscaled = {
    enable = true;
    serviceConfig = {
      User = "root";
      Group = "root";
    };
  };

  services.networkd-dispatcher = {
    enable = true;
     rules."50-tailscale" = {
       onState = ["routable"];
       script = ''
         "${pkgs.ethtool} -K eno1 rx-udp-gro-forwarding on rx-gro-list off"
       '';
     };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
 
 
  # Enable cron service
  services.cron = {
    enable = true;
    systemCronJobs = [
      ''
        */1 * * * *      root    curl --retry 3 https://hc-ping.com/$(cat /etc/HC_UUID)/intel-nuc
      ''

      # "*/1 * * * *      root    curl -s -w \"%{http_code}\" \"$(cat /etc/CCTV_IP)\""
       
      ''
        */1 * * * *      root    [[ $(curl -s -o /dev/null -w "\%{http_code}" "$(cat /etc/CCTV_IP)") -eq 200 ]] && curl --retry 3 https://hc-ping.com/$(cat /etc/HC_UUID)/cctv
      ''
    ];
  };

  services.nginx = {
    enable = true;
    virtualHosts.localhost = {
    listen = [
      { addr="0.0.0.0"; port = 1337; }
    ];
    locations."/" = {
      return = "200 '<html><body>It working</body></html>'";
      extraConfig = ''
        default_type text/html;
      '';
      };
    };
  };
 
  # traefik config
  services.traefik.enable = true;

  services.traefik.staticConfigOptions = {
    # 3.1 Define Entrypoints for HTTP and HTTPS
    entryPoints = {
      web = {
        address = ":80";
        # 3.2 Redirect all HTTP to HTTPS
        # http.redirections.entryPoint = {
          # to = "websecure";
          # scheme = "https";
        # };
      };
    };

    api.dashboard = true;
  };

   services.traefik.dynamicConfigOptions = {
    http = {
      # 4.1 Routers to handle incoming requests
      routers = {
        ollama = {
          rule = "Host(`ollama.home.anirudhmv.in`)";
          entryPoints = [ "web" ];
          service = "ollama";
        };
        uptime = {
          rule = "Host(`uptime.home.anirudhmv.in`)";
          entryPoints = [ "web" ];
          service = "uptime";
        };
        default = {
          rule = "Path(`/`)";
          entryPoints = [ "web" ];
          service = "default";
        };
      };

      # 4.2 Services that point to your applications
      services = {
        ollama = {
          loadBalancer.servers = [{
            url = "http://localhost:11480";
          }];
        };
        uptime = {
          loadBalancer.servers = [{
            url = "http://localhost:6000";
          }];
        };
        default = {
          loadBalancer.servers = [{
            url = "http://localhost:1337";
          }];
        };
      };
    };
  };

  # ollama
  services.ollama = {
    enable = true;
    # Optional: preload models, see https://ollama.com/library
    loadModels = [ "qwen2.5-coder:7b" "deepseek-r1:8b" ];
    host = "0.0.0.0";
  };

  services.open-webui = {
    enable = true;
    port = 11480;
    host = "0.0.0.0";
    environment = {
        # WEBUI_AUTH = "false";
      };
    };

  # Kernel options to set on boot for tailscale
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;

  # List services that you want to enable:
  services.uptime-kuma.enable = true;
  services.uptime-kuma.settings.PORT = "6000";

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      # Opinionated: forbid root login through SSH.
      PermitRootLogin = "no";
      # Opinionated: use keys only.
      # Remove if you want to SSH using passwords
      PasswordAuthentication = true;
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
