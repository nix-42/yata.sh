#!/bin/sh
# Author : Stanley <git.io/monesonn>

# Script version
__version="0.1.0-rc2"

# General variables

# quiet mode is the default mode
# ISQUIET="-q --console-title"
ISQUIET=""
VERBOSE=0

DIR=''
YTDL_BIN=`which youtube-dl`
DEFAULT_DIR="$HOME/Music"
PLAYLIST_DIR="${DEFAULT_DIR}/playlists"
UPLOADER_DIR="${DEFAULT_DIR}/uploader"
YTDL_OUPUT_TEMPLATE='%(playlist_index)s - %(title)s.%(ext)s'
YTDL_FORMAT='mp3'

# Some variables to initialize colors for colorfull echo output
BLUE='\033[1;34m'
RED='\033[31m'
CYAN='\033[1;36m'
NC='\033[0m'

_help() {
cat << EOF

 ▀▄▀ ▄▀▄ ▀█▀ ▄▀▄  
  █  █▀█  █  █▀█.sh                
EOF
echo -e "${BLUE} Ultimate audio download script${NC}"

cat << EOF

 Description: CLI-wrapper for youtube-dl written on Shell

 Usage: $(basename $0) [OPTION] URL [URL...]

 Options:                       
  -h | --help | help            Show this message
  -v | --version | version      Show script version
  -p | --playlist | playlist    Download playlist ... 

 Example: yata -p url
EOF
}

download_playlist() {
  $YTDL_BIN \
  ${ISQUIET} \
  --embed-thumbnail \
  --ignore-errors \
  --extract-audio \
  --no-overwrites \
  --audio-format $YTDL_FORMAT \
  --output "${DEFAULT_DIR}/playlists/%(playlist)s/${YTDL_OUPUT_TEMPLATE}" \
  "$1"
}

err_msg() { echo -e "${RED}$1${NC}"; }

__main__() {
  case $# in
  0) _help ; exit 1 ;;
  1) case $1 in
      -h | --help | help) shift; _help ;;
      -v | --version | version) shift; printf "$__version\n" ;;
      # -p | --playlist | playlist)  ;;
      *) err_msg "No such option: $1" ; exit 1 ;;
    esac;;
  2) 
    if [[ "$1" == "-p" || "$1" == "--playlist" || "$1" == "playlist" ]]; then
      download_playlist "$2"
    else err_msg "Input error." ; exit 1
    fi;;  
  *) err_msg "Input error, too many arguments.\nType yata [-h|--help|help] to see a list of all options." ; exit 1 ;;
  esac
}

__main__ "$@" ; exit 0
