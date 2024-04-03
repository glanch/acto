{ lib, config, pkgs, firefox-addons, ... }:
with lib;
let
  cfg = config.custom.firefox;
in
{
  imports = [
    ./nur.nix
  ];

  options.custom.firefox = {
    enable = mkEnableOption "Enable VS Codium setup";
  };

  config = mkIf cfg.enable
    {
      # Screen sharing
      xdg = {
        portal = {
          enable = true;
          extraPortals = with pkgs; [
            xdg-desktop-portal-hyprland
          ];

        };
      };

      home-manager.users.christopher = { ... }: {
        programs.firefox = {
          enable = true;
          policies = {
            DisableTelemetry = true;
            DisableFirefoxStudies = true;
            EnableTrackingProtection = {
              Value = true;
              Locked = true;
              Cryptomining = true;
              Fingerprinting = true;
            };
            DisablePocket = true;
            DisableFirefoxAccounts = true;
            DisableAccounts = true;
            DisableFirefoxScreenshots = true;
            OverrideFirstRunPage = "";
            OverridePostUpdatePage = "";
            DontCheckDefaultBrowser = true;
            DisplayBookmarksToolbar = "newtab";
            DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
            SearchBar = "unified"; # alternative: "separate"
          };
          profiles = {
            webbrowsing = {
              isDefault = true;

              settings =
                let
                  lock-false = false;
                  lock-true = true; # TODO: check how to properly lock settings here
                in
                {
                  "browser.search.region" = "DE";
                  "dom.security.https_only_mode" = true;
                  "dom.security.https_only_mode_ever_enabled" = true;
                  "browser.contentblocking.category" = { Value = "strict"; Status = "locked"; };
                  "extensions.pocket.enabled" = lock-false;
                  "extensions.screenshots.disabled" = lock-true;
                  "browser.topsites.contile.enabled" = lock-false;
                  "browser.formfill.enable" = lock-false;
                  "browser.search.suggest.enabled" = lock-false;
                  "browser.search.suggest.enabled.private" = lock-false;
                  "browser.urlbar.suggest.searches" = lock-false;
                  "browser.urlbar.showSearchSuggestionsFirst" = lock-false;
                  "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
                  "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
                  "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
                  "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
                  "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
                  "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
                  "browser.newtabpage.activity-stream.showSponsored" = lock-false;
                  "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
                  "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
                };
              extensions = with firefox-addons.packages.${pkgs.system}; [ ublock-origin bitwarden darkreader multi-account-containers darkreader];
              containers = {
                "Dangerous" = {
                  color = "red";
                  icon = "fruit";
                  id = 2;
                };
                "Shopping" = {
                  color = "blue";
                  icon = "cart";
                  id = 1;
                };

                "Discord" = {
                  color = "blue";
                  icon = "fingerprint";
                  id = 3;
                };

                "Google Accounts" = {
                  color = "blue";
                  icon = "fingerprint";
                  id = 4;
                };

                "PayPal" = {
                  color = "blue";
                  icon = "dollar";
                  id = 5;
                };

                "Amazon" = {
                  color = "blue";
                  icon = "cart";
                  id = 6;
                };

                "University" = {
                  color = "blue";
                  icon = "briefcase";
                  id = 7;
                };

                "LinkedIn" = {
                  color = "blue";
                  icon = "briefcase";
                  id = 8;
                };
              };

              search =
                {
                  force = true;
                  engines = {
                    "Nix Packages" = {
                      urls = [{
                        template = "https://search.nixos.org/packages";
                        params = [
                          { name = "type"; value = "packages"; }
                          { name = "query"; value = "{searchTerms}"; }
                        ];
                      }];

                      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                      definedAliases = [ "@np" ];
                    };

                    "NixOS Options" = {
                      urls = [{
                        template = "https://search.nixos.org/options";
                        params = [
                          { name = "type"; value = "packages"; }
                          { name = "query"; value = "{searchTerms}"; }
                        ];
                      }];

                      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                      definedAliases = [ "@no" ];
                    };

                    "NixOS Wiki" = {
                      urls = [{ template = "https://nixos.wiki/index.php?search={searchTerms}"; }];
                      iconUpdateURL = "https://nixos.wiki/favicon.png";
                      updateInterval = 24 * 60 * 60 * 1000; # every day
                      definedAliases = [ "@nw" ];
                    };

                    "Bing".metaData.hidden = true;
                    "Google".metaData.alias = "@g"; # builtin engines only support specifying one additional alias
                    "DuckDuckGo".metaData.alias = "@ddg"; # builtin engines only support specifying one additional alias
                  };
                };


              /* ---- POLICIES ---- */
              # Check about:policies#documentation for options.

              #   /* ---- EXTENSIONS ---- */
              #   # Check about:support for extension/add-on ID strings.
              #   # Valid strings for installation_mode are "allowed", "blocked",
              #   # "force_installed" and "normal_installed".
              #   ExtensionSettings = {
              #     "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
              #     # uBlock Origin:
              #     "uBlock0@raymondhill.net" = {
              #       install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              #       installation_mode = "force_installed";
              #     };
              #     # Privacy Badger:
              #     "jid1-MnnxcxisBPnSXQ@jetpack" = {
              #       install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
              #       installation_mode = "force_installed";
              #     };
              #     # 1Password:
              #     "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
              #       install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
              #       installation_mode = "force_installed";
              #     };
              #   };

              #   /* ---- PREFERENCES ---- */
              #   # Check about:config for options.
              #   Preferences = {
              #     "browser.contentblocking.category" = { Value = "strict"; Status = "locked"; };
              #     "extensions.pocket.enabled" = lock-false;
              #     "extensions.screenshots.disabled" = lock-true;
              #     "browser.topsites.contile.enabled" = lock-false;
              #     "browser.formfill.enable" = lock-false;
              #     "browser.search.suggest.enabled" = lock-false;
              #     "browser.search.suggest.enabled.private" = lock-false;
              #     "browser.urlbar.suggest.searches" = lock-false;
              #     "browser.urlbar.showSearchSuggestionsFirst" = lock-false;
              #     "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
              #     "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
              #     "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
              #     "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
              #     "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
              #     "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
              #     "browser.newtabpage.activity-stream.showSponsored" = lock-false;
              #     "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
              #     "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
              #   };
              # };
            };
          };

        };
      };
    };
}

