#!/bin/sh
# Author : Stanley <git.io/monesonn>

# Script version
__version="0.1.0-rc4"

# General variables

# quiet mode is the default mode
ISQUIET="--quiet --console-title"
# VERBOSE=0

DEFAULT_DIR="$HOME/Music/yata"
PLAYLIST_DIR="${DEFAULT_DIR}/playlists"
UPLOADER_DIR="${DEFAULT_DIR}/uploader"

OUTPUT='%(uploader)s - %(title)s [%(id)s].%(ext)s'

AUDIO_EXT='mp3'
BITRATE='128K'
SAMPLE_RATE='48000'

# Some variables to initialize colors for colorfull echo output
DARK_BLUE='\033[34m'
RED='\033[31m'
BLUE='\033[1;34m'
NC='\033[0m'

_help() {

echo -ne \
"${DARK_BLUE}
 ▀▄▀ ▄▀▄ ▀█▀ ▄▀▄     
  █  █▀█  █  █▀█.sh 
${NC}"
echo -e "${BLUE}  Audio download script${NC}"

cat << EOF

  Description: CLI-wrapper for youtube-dl written on Shell
  Usage: $(basename $0) [OPTIONS] -d [URL]                                          
                                                                                   |OPTIONS|
 +----+------------+-----------+-----------------------------------------------------------+
 | -d | --download | download  | Download and convert single video                         |
 | -p | --playlist | playlist  | Download and convert playlist                             |
 | -a | --audio    | audio     | Set audio extension [default: mp3; best, aac, flac, etc]  |
 | -b | --bitrate  | bitrate   | Set audio bitrate [default: 128K; 256K, 320K, best]       |
 | -s | --asr      | asr       | Set audio samplerate [default: 48000; 44000, 41000]       |
 | -p | --path     | path      | Set path [default: ~/Music/yata]                          |
 | -v | --verbose  | verbose   | Turn off quiet mode                                       |
 | -v | --version  | version   | Show script version                                       |
 | -h | --help     | help      | Show this message                                         |
 +----+------------+-----------+-----------------------------------------------------------+

  Example: yta download url or yta playlist url...

EOF
}

download() {
  echo "[yata]: Starting..."
  youtube-dl \
  ${ISQUIET} \
  --format "bestaudio[asr = ${SAMPLE_RATE}]" \
  --ignore-errors \
  --no-continue \
  --no-overwrites \
  --add-metadata \
  --extract-audio \
  --audio-format ${AUDIO_EXT} \
  --audio-quality ${BITRATE} \
  --embed-thumbnail \
  --metadata-from-title "(?P<artist>.+?) - (?P<title>.+)" \
  --output "${DEFAULT_DIR}/${AUDIO_EXT}/%(title)s.%(ext)s'" \
  --exec 'echo "[yata]: {} is downloaded"' \
  $1 `# URL`
  echo "[yata]: All is done."
  exit 0
}

download_playlist() {
  echo "[yata]: Starting to download playlist..."
  youtube-dl \
  ${ISQUIET} \
  --format "bestaudio[asr = ${SAMPLE_RATE}]" \
  --ignore-errors \
  --no-continue \
  --no-overwrites \
  --add-metadata \
  --yes-playlist \
  --extract-audio \
  --audio-format ${AUDIO_EXT} \
  --audio-quality ${BITRATE} \
  --embed-thumbnail \
  --metadata-from-title "(?P<title>.+)" \
  --output "${PLAYLIST_DIR}/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s'" \
  --exec 'echo "[yata]: {} is downloaded"' \
  $1 `# URL`
  echo "[yata]: All is done."
  exit 0
}

err_msg() { echo -e "${RED}$1${NC}"; }

__main__() {
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -h | --help | help) _help && exit 1;;
      -v | --version | version) printf "$__version\n" && exit 1;;
      -a | --audio | audio) AUDIO_EXT="$2" ;;
      -b | --bitrate  | bitrate) BITRATE="$2" ;;
      -d | --download | download) download "$2" ;;
      -p | --playlist | playlist) download_playlist "$2";;
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
