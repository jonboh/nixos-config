{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellScriptBin "ffnnn" ''
  # This wrapper script is invoked by xdg-desktop-portal-termfilechooser.
  #
  # Inputs:
  # 1. "1" if multiple files can be chosen, "0" otherwise.
  # 2. "1" if a directory should be chosen, "0" otherwise.
  # 3. "0" if opening files was requested, "1" if writing to a file was
  #    requested. For example, when uploading files in Firefox, this will be "0".
  #    When saving a web page in Firefox, this will be "1".
  # 4. If writing to a file, this is recommended path provided by the caller. For
  #    example, when saving a web page in Firefox, this will be the recommended
  #    path Firefox provided, such as "~/Downloads/webpage_title.html".
  #    Note that if the path already exists, we keep appending "_" to it until we
  #    get a path that does not exist.
  # 5. The output path, to which results should be written.
  #
  # Output:
  # The script should print the selected paths to the output path (argument #5),
  # one path per line.
  # If nothing is printed, then the operation is assumed to have been canceled.


  save="$3"
  suggest="$4"
  out="$5"
  file="''${suggest##/*/}"
  out="''${out:-/tmp/ffnnn-out}"
  command="yazi --chooser-file $out"

  if [ "$save" = 1 ]; then
      touch "$suggest"
  else
    command="cd $suggest && $command"
  fi

  # NOTE: use kitty --hold to debug
  /run/current-system/sw/bin/kitty -e /run/current-system/sw/bin/zsh -c "$command"

  if [ "$save" = 1 ]; then
      if [ ! -s "$out" ] || [ ! -s "$suggest" ]; then
          rm "$suggest"
      fi
  fi
''
