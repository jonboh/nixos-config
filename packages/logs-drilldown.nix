{
  grafanaPlugin,
  lib,
}:
grafanaPlugin {
  pname = "grafana-lokiexplore-app";
  version = "1.0.10";
  zipHash = "sha256-1+5xil0XmcLCDKpObuxpnoMnQZaT1I62zL6xatlyKc4=";
  # meta = with lib; {
  #   description = "This is a streaming Grafana data source which can connect to the Tokio console subscriber.";
  #   license = licenses.asl20;
  #   maintainers = with maintainers; [nagisa];
  #   platforms = platforms.unix;
  # };
}
