{config, ...}: {
  services.hostapd = {
    enable = true;
    radios = {
      wlan0 = {
        band = "2g";
        countryCode = "ES";
        channel = 0; # ACS (Automatic Channel Detection)

        wifi4 = {
          enable = true;
          capabilities = [
            # NOTE: use 'iw phy#1 info' to determine your VHT capabilities
            # TODO: locate where are these names defined in hostapd documentation
            "HT40+"
            "LDPC"
            "SHORT-GI-20"
            "SHORT-GI-40"
            "TX-STBC"
            "RX-STBC1"
            "MAX-AMSDU-7935"
          ];
        };
        networks = {
          wlan0 = {
            ssid = "charon";
            authentication = {
              enableRecommendedPairwiseCiphers = true;
              mode = "wpa3-sae-transition";
              wpaPasswordFile = config.sops.secrets.wifiPasswordCharon.path;
              saePasswordsFile = config.sops.secrets.wifiPasswordCharon.path;
            };
            settings = {
              ieee80211w = "1";
            };
          };
          wlan0-rift = {
            ssid = "rift";
            authentication = {
              enableRecommendedPairwiseCiphers = true;
              mode = "wpa2-sha256";
              wpaPasswordFile = config.sops.secrets.wifiPasswordRift.path;
              # saePasswordsFile = config.sops.secrets.wifiPasswordRift.path;
            };
            settings = {
              ieee80211w = "1";
            };
          };
          wlan0-warp = {
            ssid = "warp";
            authentication = {
              enableRecommendedPairwiseCiphers = true;
              mode = "wpa3-sae-transition";
              wpaPasswordFile = config.sops.secrets.wifiPasswordWarp.path;
              saePasswordsFile = config.sops.secrets.wifiPasswordWarp.path;
            };
            settings = {
              ieee80211w = "1";
            };
          };
        };
      };
      wlan1 = {
        band = "5g";
        channel = 36;
        countryCode = "ES";

        # use 'iw phy#1 info' to determine your VHT capabilities
        wifi4 = {
          enable = true;
          capabilities = ["HT40+" "LDPC" "SHORT-GI-20" "SHORT-GI-40" "TX-STBC" "RX-STBC1" "MAX-AMSDU-7935"];
        };
        wifi5 = {
          enable = true;
          operatingChannelWidth = "80";
          capabilities = ["RXLDPC" "SHORT-GI-80" "SHORT-GI-160" "TX-STBC-2BY1" "SU-BEAMFORMER" "SU-BEAMFORMEE" "MU-BEAMFORMER" "MU-BEAMFORMEE" "RX-ANTENNA-PATTERN" "TX-ANTENNA-PATTERN" "RX-STBC-1" "SOUNDING-DIMENSION-4" "BF-ANTENNA-4" "VHT160" "MAX-MPDU-11454" "MAX-A-MPDU-LEN-EXP7"];
        };
        wifi6 = {
          enable = true;
          singleUserBeamformer = true;
          singleUserBeamformee = true;
          multiUserBeamformer = true;
          operatingChannelWidth = "80";
        };
        # https://w1.fi/cgit/hostap/plain/hostapd/hostapd.conf
        settings = {
          # NOTE: leave out strict (10 min listen requirement) DFS channels and channel 144, see:
          # https://bandaancha.eu/articulos/todas-canales-bandas-wifi-2-4-5-6ghz-10117
          # https://bandaancha.eu/articulos/canales-wifi-banda-5-ghz-espana-mejor-9826
          # https://avancedigital.mineco.gob.es/espectro/CNAF/notas-UN-2017.pdf
          # https://www.etsi.org/deliver/etsi_en/301800_301899/301893/02.01.01_60/en_301893v020101p.pdf
          # after testing the speed of the 80 Mhz band around 42 I get full speed, so
          # no need to touch the DFS channels, this allows the 5G radio to be online immediately
          chanlist = "36 40 44 48";
          acs_exclude_dfs = 1;
          # these two are mandatory for wifi 5 & 6 to work. They set the center of the band.
          # in my case 42 is the center of the 80 Mhz band from 36 to 48
          vht_oper_centr_freq_seg0_idx = 42;
          he_oper_centr_freq_seg0_idx = 42; # TODO: check effect

          # TODO: check the rest of parameters

          # The "tx_queue_data2_burst" parameter in Linux refers to the burst size for
          # transmitting data packets from the second data queue of a network interface.
          # It determines the number of packets that can be sent in a burst.
          # Adjusting this parameter can impact network throughput and latency.
          tx_queue_data2_burst = 2;

          # The "he_bss_color" parameter in Wi-Fi 6 (802.11ax) refers to the BSS Color field in the HE (High Efficiency) MAC header.
          # BSS Color is a mechanism introduced in Wi-Fi 6 to mitigate interference and improve network efficiency in dense deployment scenarios.
          # It allows multiple overlapping Basic Service Sets (BSS) to differentiate and coexist in the same area without causing excessive interference.
          he_bss_color = 63; # was set to 128 by openwrt but range of possible values in 2.10 is 1-63

          # Magic values that were set by openwrt but I didn't bother inspecting every single one
          he_spr_sr_control = 3;
          he_default_pe_duration = 4;
          he_rts_threshold = 1023;

          he_mu_edca_qos_info_param_count = 0;
          he_mu_edca_qos_info_q_ack = 0;
          he_mu_edca_qos_info_queue_request = 0;
          he_mu_edca_qos_info_txop_request = 0;

          # he_mu_edca_ac_be_aci=0; missing in 2.10
          he_mu_edca_ac_be_aifsn = 8;
          he_mu_edca_ac_be_ecwmin = 9;
          he_mu_edca_ac_be_ecwmax = 10;
          he_mu_edca_ac_be_timer = 255;

          he_mu_edca_ac_bk_aifsn = 15;
          he_mu_edca_ac_bk_aci = 1;
          he_mu_edca_ac_bk_ecwmin = 9;
          he_mu_edca_ac_bk_ecwmax = 10;
          he_mu_edca_ac_bk_timer = 255;

          he_mu_edca_ac_vi_ecwmin = 5;
          he_mu_edca_ac_vi_ecwmax = 7;
          he_mu_edca_ac_vi_aifsn = 5;
          he_mu_edca_ac_vi_aci = 2;
          he_mu_edca_ac_vi_timer = 255;

          he_mu_edca_ac_vo_aifsn = 5;
          he_mu_edca_ac_vo_aci = 3;
          he_mu_edca_ac_vo_ecwmin = 5;
          he_mu_edca_ac_vo_ecwmax = 7;
          he_mu_edca_ac_vo_timer = 255;
        };
        networks = {
          wlan1 = {
            ssid = "charon";
            authentication = {
              enableRecommendedPairwiseCiphers = true;
              mode = "wpa3-sae-transition";
              wpaPasswordFile = config.sops.secrets.wifiPasswordCharon.path;
              saePasswordsFile = config.sops.secrets.wifiPasswordCharon.path;
            };
          };
          wlan1-rift = {
            ssid = "rift";
            authentication = {
              enableRecommendedPairwiseCiphers = true;
              mode = "wpa2-sha256";
              wpaPasswordFile = config.sops.secrets.wifiPasswordRift.path;
              # saePasswordsFile = config.sops.secrets.wifiPasswordRift.path;
            };
          };
          wlan1-warp = {
            ssid = "warp";
            authentication = {
              enableRecommendedPairwiseCiphers = true;
              mode = "wpa3-sae-transition";
              wpaPasswordFile = config.sops.secrets.wifiPasswordWarp.path;
              saePasswordsFile = config.sops.secrets.wifiPasswordWarp.path;
            };
          };
        };
      };
    };
  };
  # you can probe the state with
  # `sudo iw wlan1 info`
  # NOTE: see https://github.com/NixOS/nixpkgs/issues/25378#issuecomment-1097034289
  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="ES"
  '';
}
