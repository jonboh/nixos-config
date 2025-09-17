{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellScriptBin "macho" ''
  export MANPAGER='nixvim-light +Man\! "+set relativenumber" -'
  export FZF_DEFAULT_OPTS='
  --height=70%
  --layout=reverse
  --prompt="Manual: "
  --preview-window=right,70%
  --preview="echo {1} | xargs -I{S} man {S} {2} 2>/dev/null"'


  while getopts ":s:" opt; do
   case $opt in
   s ) SECTION=$OPTARG; shift; shift;;
   \?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
   : ) echo "Option -$OPTARG requires an argument" >&2; exit 1;;
   esac
  done

  manual=$(apropos -s ''${SECTION:-'''} ''${@:-.} | \
   grep -v -E '^.+ \(0\)' |\
   awk '{print $2 "	" $1}' | \
   sort | \
   fzf  )

  [ -z "$manual" ] && exit 0
  man $manual
''
