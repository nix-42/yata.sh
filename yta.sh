#!/bin/sh
# Author : Stanley <git.io/monesonn>

# Script version
__version="0.3.0"

# GENERAL

## Default directories
dir="$HOME/Music"
playlist_dir="${dir}/playlists"
uploader_dir="${dir}/uploader"

## Output Template
output='%(uploader)s - %(title)s [%(id)s].%(ext)s'

## Default variables
quiet=''
audio_ext='mp3'
bitrate='128K'
sample_rate='48000'

# Flags
playlist=false
sox=false
beets=false
play=false
fzf=false

## Some variables to initialize colors for colorfull echo output
dbc='\033[34m' #dark blue color
rc='\033[31m' # red color
bc='\033[1;34m' # blue color
nc='\033[0m' # no color

no_ops() {
cat << "EOF"
             __             __ 
  __ _____ _/ /____ _  ___ / / 
 / // / _ `/ __/ _ `/ (_-</ _ \
 \_, /\_,_/\__/\_,_(_)___/_//_/
/___/ Audio downloader script

EOF
}

_help() {
cat << EOF
Description: CLI-wrapper for youtube-dl written on Shell
Usage: $(basename $0) [OPTIONS] -d [URL]

Options:
-d  --download  download   Download and convert single video 
-p  --playlist  playlist   Download and convert playlist     
-a  --audio     audio      Set audio extension               
                           [default: mp3; aac, flac...]      
-b  --bitrate   bitrate    Set audio bitrate                 
                           [default: 128K; 256K, 320K]       
-s  --asr       asr        Set audio samplerate              
                           [default: 48000; 44000, 41000]    
-p  --path      path       Set path [default: ~/Music/yata]  
-q  --quiet     quiet      Turn off quiet mode               
-x  --sox       sox        Merge audio files from playlist   
-t  --beets     beets      Add to library and add tags   
-f  --find      find       Find music in youtube-dl using ytfzf    
-v  --version   version    Show script version               
-h  --help      help       Show this message                 

Example: yta https://youtu.be/[url]
         yta -p https://www.youtube.com/playlist?list=[url]
         yta -a=aac -s=44000 -b=256 https://youtu.be/[url]
         yta -f "Title in Youtube"
EOF
}

err_msg() { echo -e "${rc}$1${nc}"; }

download() {
  [[ ${audio_ext} = mp3 ]] && local EMBED="--embed-thumbnail" || local EMBED="" 
  echo "[yata] Starting..."
  if [ $playlist = true ] ; then
    local playlist_TITLE=`youtube-dl --no-warnings --dump-single-json $1 | jq -r '.title'`
    echo "[yata] playlist \"${playlist_TITLE}\" is downloading."
    youtube-dl \
    ${quiet} \
    --format "bestaudio[asr = ${sample_rate}]" \
    --ignore-errors \
    --no-continue \
    --no-overwrites \
    --add-metadata \
    --yes-playlist \
    --extract-audio \
    --audio-format ${audio_ext} \
    --audio-quality ${bitrate} \
    ${EMBED} \
    --metadata-from-title "(?P<title>.+)" \
    --output "${playlist_dir}/%(playlist)s/%(playlist_index)s %(title)s.%(ext)s" \
    --exec 'echo [yata] {} is downloaded.' \
    $1 `# URL` 2>/dev/null

    # lmao, idk, but it's works 
    [[ $sox = true ]] && echo "[sox]  Starting to merge ${playlist_TITLE}." \
    sox "${playlist_dir}/${playlist_TITLE}/*.${audio_ext}" "${dir}/${audio_ext}/${playlist_TITLE}.${audio_ext}" \
    echo "[sox]  ${dir}/${audio_ext}/${playlist_TITLE}.${audio_ext} is merged."

    [[ $beets = true ]] && echo "[beets] Adding to library." \
    beet import ${playlist_dir}/${playlist_TITLE} \
    echo "[beet] Import is done."
  else
    youtube-dl \
    ${quiet} \
    --format "bestaudio[asr = ${sample_rate}]" \
    --ignore-errors \
    --no-continue \
    --no-overwrites \
    --add-metadata \
    --extract-audio \
    --audio-format ${audio_ext} \
    --audio-quality ${bitrate} \
    ${EMBED} \
    --metadata-from-title "(?P<artist>.+?) - (?P<title>.+)" \
    --output "${dir}/${audio_ext}/%(title)s.%(ext)s" \
    --exec 'echo [yata] {} is downloaded.' \
    $1 `# URL` 2>/dev/null
  fi
  echo "[yata] All is done."
  # [[ $play = true ]] && echo "[yata] Start to play." \
  # mpv ${playlist_dir}/${playlist_TITLE} \
}

__main__() {
  while [[ "$#" -gt 0 ]]; do
    argument="$1"
    case $argument in
      -a=* | --audio=* | audio=*) audio_ext="${argument#*=}" ; shift ;;
      -b=* | --bitrate=* | bitrate=*) bitrate="${argument#*=}" ; shift ;;
      -p=* | --path=* | path=*) dir="${argument#*=}" ; shift ;;
      -q | --quiet | quiet) quiet='--quiet --console-title' ; shift ;;
      -x | --sox | sox) sox=true ; shift ;; 
      -f | --find | find) fzf=true; shift ;;
      -p | --playlist | playlist) playlist=true ; shift ;;
      -t | --beets | beets) beets=true ; shift ;;
      -v | --version | version) printf "$__version\n" ; exit ;;
      -h | --help | help) _help ; exit ;;
      -* | --*) err_msg "No such option: $argument.\nType yta [-h|--help|help] to see a list of all options." && exit ;;
      *) [[ $fzf = true ]] && ytfzf -m $argument || download $argument ; exit ;;
    esac
  done
  err_msg "Something went wrong..." && exit;
}

[[ ${#} -eq 0 ]] && no_ops || __main__ "$@" 
