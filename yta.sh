#!/bin/sh
# Author : Stanley <git.io/monesonn>

# Script version
__version="0.2.2"

# GENERAL

## Default directories
DEFAULT_DIR="$HOME/Music"
PLAYLIST_DIR="${DEFAULT_DIR}/playlists"
UPLOADER_DIR="${DEFAULT_DIR}/uploader"
## Output Template
OUTPUT='%(uploader)s - %(title)s [%(id)s].%(ext)s'
## Default variables
QUIET=''
AUDIO_EXT='mp3'
BITRATE='128K'
SAMPLE_RATE='48000'
PLAYLIST=false
SOX=false
## Some variables to initialize colors for colorfull echo output
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
 +----+------------+-----------+-----------------------------------+
 | -d | --download | download  | Download and convert single video |
 | -p | --playlist | playlist  | Download and convert playlist     |
 | -a | --audio    | audio     | Set audio extension               |
 |    |            |           | [default: mp3; aac, flac...]      |
 | -b | --bitrate  | bitrate   | Set audio bitrate                 |
 |    |            |           | [default: 128K; 256K, 320K]       |
 | -s | --asr      | asr       | Set audio samplerate              |
 |    |            |           | [default: 48000; 44000, 41000]    |
 | -p | --path     | path      | Set path [default: ~/Music/yata]  |
 | -q | --quiet    | quiet     | Turn off quiet mode               |
 | -1 | --sox      | sox       | Merge audio files from playlist   |
 | -v | --version  | version   | Show script version               |
 | -h | --help     | help      | Show this message                 |
 +----+------------+-----------+-----------------------------------+

  Example: yta https://youtu.be/[url]
           yta -p https://www.youtube.com/playlist?list=[url]
           yta -a=aac -s=44000 -b=256 https://youtu.be/[url]

EOF
}

err_msg() { echo -e "${RED}$1${NC}"; }

download() {
  [[ ${AUDIO_EXT} = mp3 ]] && local EMBED="--embed-thumbnail" || local EMBED="" 
  echo "[yata] Starting..."
  if [ $PLAYLIST = true ] ; then
    local PLAYLIST_TITLE=`youtube-dl --no-warnings --dump-single-json $1 | jq -r '.title'`
    echo "[yata] Playlist \"${PLAYLIST_TITLE}\" is downloading."
    youtube-dl \
    ${QUIET} \
    --format "bestaudio[asr = ${SAMPLE_RATE}]" \
    --ignore-errors \
    --no-continue \
    --no-overwrites \
    --add-metadata \
    --yes-playlist \
    --extract-audio \
    --audio-format ${AUDIO_EXT} \
    --audio-quality ${BITRATE} \
    ${EMBED} \
    --metadata-from-title "(?P<title>.+)" \
    --output "${PLAYLIST_DIR}/%(playlist)s/%(playlist_index)s %(title)s.%(ext)s" \
    --exec 'echo [yata] {} is downloaded.' \
    $1 `# URL` 2>/dev/null
    # lmao, idk, but it's works 
    [[ $SOX = true ]] && echo "[sox]  Starting to merge ${PLAYLIST_TITLE}." \
    sox "${PLAYLIST_DIR}/${PLAYLIST_TITLE}/*.${AUDIO_EXT}" "${DEFAULT_DIR}/${AUDIO_EXT}/${PLAYLIST_TITLE}.${AUDIO_EXT}" \
    echo "[sox]  ${DEFAULT_DIR}/${AUDIO_EXT}/${PLAYLIST_TITLE}.${AUDIO_EXT} is merged." 
    exit 0
  else
    youtube-dl \
    ${QUIET} \
    --format "bestaudio[asr = ${SAMPLE_RATE}]" \
    --ignore-errors \
    --no-continue \
    --no-overwrites \
    --add-metadata \
    --extract-audio \
    --audio-format ${AUDIO_EXT} \
    --audio-quality ${BITRATE} \
    ${EMBED} \
    --metadata-from-title "(?P<artist>.+?) - (?P<title>.+)" \
    --output "${DEFAULT_DIR}/${AUDIO_EXT}/%(title)s.%(ext)s" \
    --exec 'echo [yata] {} is downloaded.' \
    $1 `# URL` 2>/dev/null
    exit 0
  fi
  echo "[yata] All is done."
}

__main__() {
  while [[ "$#" -gt 0 ]]; do
    argument="$1"
    case $argument in
      -a=* | --audio=* | audio=*) AUDIO_EXT="${argument#*=}" ; shift ;;
      -b=* | --bitrate=* | bitrate=*) BITRATE="${argument#*=}" ; shift ;;
      -q | --quiet | quiet) QUIET='--quiet --console-title' ; shift ;;
      -1 | --sox | sox) SOX=true ; shift ;; 
      -p | --playlist | playlist) PLAYLIST=true ; shift ;;
      -v | --version | version) printf "$__version\n" ; exit 0 ;;
      -h | --help | help) _help ; exit 0 ;;
      -* | --*) err_msg "No such option: $argument.\nType yta [-h|--help|help] to see a list of all options." ; exit 1 ;;
      *) download $argument ;;
    esac
  done
  err_msg "Something went wrong..." ; exit 1
}

[[ ${#} -eq 0 ]] && _help || __main__ "$@" 
