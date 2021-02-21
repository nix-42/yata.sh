#!/bin/sh
# Author : Stanley <git.io/monesonn>

# Script version
__version="0.1.0-rc3"

# General variables

# quiet mode is the default mode
ISQUIET="--quiet --console-title"
# VERBOSE=0

DEFAULT_DIR="$HOME/Music/yata"
PLAYLIST_DIR="${DEFAULT_DIR}/playlists"
UPLOADER_DIR="${DEFAULT_DIR}/uploader"

AUDIO_EXT='mp3'
BITRATE='128K'

# Some variables to initialize colors for colorfull echo output
BLUE='\033[1;34m'
RED='\033[31m'
CYAN='\033[1;36m'
NC='\033[0m'

_help() {

echo -e \
"${BLUE}
 ▀▄▀ ▄▀▄ ▀█▀ ▄▀▄     
  █  █▀█  █  █▀█.sh 
  Audio download script \
${NC}"

cat << EOF

 Description: CLI-wrapper for youtube-dl written on Shell
 Usage: $(basename $0) [OPTIONS] -d [URL]                                          
                                                                                   |OPTIONS|
 +----+------------+-----------+-----------------------------------------------------------+                       
 | -h | --help     | help      | Show this message                                         |
 | -v | --version  | version   | Show script version                                       |
 | -p | --path     | path      | Set path [default: ~/Music/yata]                          |
 | -a | --audio    | audio     | Set audio extension [default: mp3; best, aac, flac, etc]  |
 | -b | --bitrate  | bitrate   | Set audio bitrate [default: 128K; 256K, 320K, best]       |                        
 | -v | --verbose  | verbose   | Turn off quiet mode                                       |
 | -p | --playlist | playlist  | Flag for playlists                                        |
 | -d | --download | download  | Handle URL                                                |
 +----+------------+-----------+-----------------------------------------------------------+

 Example: yta download url or yta playlist url...

EOF
}

download() {
  echo "[yata] Starting to download playlist"
  youtube-dl \
  ${ISQUIET} \
  --format 'bestaudio[asr = 48000]' \
  --ignore-errors \
  --extract-audio \
  --audio-format ${AUDIO_EXT} \
  --audio-quality ${BITRATE} \
  --embed-thumbnail \
  --metadata-from-title "%(title)s" \
  --output "${PLAYLIST_DIR}/%(playlist)s/%(title)s.%(ext)s'" \
  --exec 'echo "[yata]: {} is downloaded"'
  echo "[yata] All is done"
  exit 0
}

download_playlist() {
  echo "[yata] Starting to download playlist"
  youtube-dl \
  ${ISQUIET} \
  --format 'bestaudio[asr = 48000]' \
  --ignore-errors \
  --extract-audio \
  --audio-format ${AUDIO_EXT} \
  --audio-quality ${BITRATE} \
  --embed-thumbnail \
  --metadata-from-title "%(title)s" \
  --output "${PLAYLIST_DIR}/%(playlist)s/%(title)s.%(ext)s'" \
  --exec 'echo "[yata]: {} is downloaded"'
  echo "[yata] All is done"
  exit 0
}

err_msg() { echo -e "${RED}$1${NC}"; }

__main__() {
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -h | --help | help) _help && exit 1;;
      -v | --version | version) printf "$__version\n" && exit 1;;
      -p | --playlist | playlist) download_playlist ;;
      -a | --audio | audio) AUDIO_EXT="$2" ;;
      -b | --bitrate  | bitrate) BITRATE="$2"
      -d | --download | download) download "$2" ;;
      # *) err_msg "No such option: $1" ; exit 1 ;;
    esac
    # case $* 
    #   err_msg "Input error, too many arguments.\nType yata [-h|--help|help] to see a list of all options." ; exit 1 ;;
    # esac
  shift
  done
}

if [[ ${#} -eq 0 ]]; then
  _help ; exit 1
fi
__main__ "$@" ; exit 0
