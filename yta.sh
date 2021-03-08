#!/bin/sh
# Author : Stanley <git.io/monesonn>

# Script version
__version="0.4.0"

# GENERAL

## Default directories
dir="$HOME/Music"
playlist_dir="${dir}/playlists"
uploader_dir="${dir}/uploader"

## Output Template
output='%(uploader)s - %(title)s [%(id)s].%(ext)s'

## Default variables
quiet='--quiet --console-title'
audio_ext='mp3'
bitrate='128K'
sample_rate='48000'

# Flags
playlist=false
sox=false
beets=false
play=false
ytfzf=false
play=false
ytfzf_ops=''
dep_status=0
# default_jobs=5 wip

# Color codes
gr="\033[0;32m"   # green
yl="\033[1;33m"   # yellow
pr="\033[0;35m"   # purple
bl="\033[34m"     # blue
dbl="\033[1;34m"  # dark blue
cy="\033[36m"     # cyan
rd="\033[0;31m"   # red
nc="\033[0;m"     # no color
dim="\033[2m"     # dim

banner() {
echo -e \
"${bl}             __             __   __ 
  __ _____ _/ /____ _  ___ / /  / / 
 / // / _ \`/ __/ _ \`/ (_-</ _ \/_/
 \_, /\_,_/\__/\_,_(_)___/_//_(_)   
/___/ ${dim}Audio download Posix script${nc}
"
}

_help() {
cat << EOF
Description: CLI-wrapper for youtube-dl written on Shell
Usage: $(basename $0) [options] -d [URL]

Options:
-p  --playlist  playlist   Download and convert playlist     
-a  --audio     audio      Set audio extension               
                           [default: mp3; aac, flac...]      
-b  --bitrate   bitrate    Set audio bitrate                 
                           [default: 128K; 256K, 320K]       
-s  --asr       asr        Set audio samplerate              
                           [default: 48000; 44000, 41000]    
-P  --path      path       Set path [default: ~/Music/yata]  
-V  --verbose   verbose    Turn off quiet mode               
-x  --sox       sox        Merge audio files from playlist   
-B  --beets     beets      Add to library and add tags   
-f  --find      find       Find music in Youtube using ytfzf    
-v  --version   version    Show script version               
-h  --help      help       Show this message                 

Example: yta https://youtu.be/[url]
         yta -p https://www.youtube.com/playlist?list=[url]
         yta -a=aac -s=44000 -b=256 https://youtu.be/[url]
         yta -f "Title in Youtube"
EOF
}

dependencies_check()
{
  local dep_status=0
	if [[ ! $(which youtube-dl) ]] 2>/dev/null ; then dep_status=1; err_msg "youtube-dl isn't installed."; fi
  if [[ ! $(which ffmpeg) ]] 2>/dev/null ; then dep_status=1; err_msg "ffmpeg isn't installed."; fi
  # if [[ ! $(which sox) ]] 2>/dev/null ; then dep_status=1; err_msg "sox isn't installed."; fi
	if [[ $dep_status -eq 1 ]]; then err_msg "Dependencies are not installed."; exit; fi
}

err_msg() { echo -e "${rd}[!] ${yl}$1${nc}"; }
 
download() {
  # local done=false
  [[ ${audio_ext} = mp3 ]] && local embed="--embed-thumbnail" || local embed="" 
  echo -e "${bl}[yata]${nc} Starting..."
  if [ $playlist = true ] ; then
    # local playlist_title=`youtube-dl --no-warnings --dump-single-json $1 | jq -r '.title'`
    local playlist_title=`youtube-dl --no-warnings --flat-playlist --dump-single-json $1 | jq -r ".title"`
    echo -e "${bl}[yata]${nc} Playlist ${gr}\"${playlist_title}\"${nc} is downloading."
    # parallel downloading
    # youtube-dl --get-id $1 | xargs -I '{}' -P $default_jobs 
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
    ${embed} \
    --metadata-from-title "(?P<title>.+)" \
    --output "${playlist_dir}/${playlist_title}/%(track)s.%(ext)s" \
    --exec "echo -ne \"${gr}[yata]${nc} \" && echo -n {} | tr -d \'\\"'"'" | awk -F \"/\" '"'{printf $NF}'"' && echo \" is downloaded.\"" \
    $1 `# URL` 2>/dev/null
    echo -e "${bl}[yata]${nc} Playlist ${gr}\"${playlist_title}\"${nc} is downloaded."
    # lmao, idk, but it's works 
    if [ $sox = true ] ;  then
      echo -e "${yl}[sox]${nc} Starting to merge ${gr}${playlist_title}${nc}."
      sox "${playlist_dir}/${playlist_title}/*.${audio_ext}" "${dir}/${audio_ext}/${playlist_title}.${audio_ext}"
      echo -e "${yl}[sox]${nc} ${dir}/${audio_ext}/${playlist_title}.${audio_ext} is merged."
    fi
    if [ $beets = true ] ; then
      echo -e "${yl}[beets]${nc} Adding to library."
      beet import "${playlist_dir}/${playlist_title}"
      echo -e "${yl}[beet]${nc} Import is done."
    fi
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
    ${embed} \
    --metadata-from-title "(?P<artist>.+?) - (?P<title>.+)" \
    --output "${dir}/${audio_ext}/%(title)s.%(ext)s" \
    --exec "echo -ne \"${gr}[yata]${nc} \" && echo -n {} | tr -d \'\\"'"'" | awk -F \"/\" '"'{printf $NF}'"' && echo \" is downloaded.\"" \
    $1 `# URL` 2>/dev/null
  fi
  echo -e "${bl}[yata]${nc} All is done."
}

find() {
  echo -e "${bl}[yata]${nc} Start to play."
  url=`ytfzf -L "$@"`
  ytfzf -am $url
  echo -e "${bl}[yata]${nc} Do you want to download it?"
  read -n 1 -s -e -p '[y/N]> ' answer
  [[ "$answer" != "${answer#[Yy]}" ]] && download $url || echo -e "${bl}[yata]${nc} All is done."
  exit
}

__main__() {
  while [[ "$#" -gt 0 ]]; do
    argument="$1"
    case $argument in
      -a=* | --audio=* | audio=*) audio_ext="${argument#*=}" ; shift ;;
      -b=* | --bitrate=* | bitrate=*) bitrate="${argument#*=}" ; shift ;;
      -p=* | --path=* | path=*) dir="${argument#*=}" ; shift ;;
      -f=* | --fzf=* | fzf=*) ytfzf_ops="${argument#*=}"; ytfzf=true; shift ;;
      -V | --verbose | verbose) quiet='' ; shift ;;
      -x | --sox | sox) sox=true ; shift ;; 
      -f | --find | find) ytfzf=true; shift ;;
      -p | --playlist | playlist) playlist=true ; shift ;;
      -B | --beets | beets) beets=true ; shift ;;
      -v | --version | version) printf "$__version\n" ; exit ;;
      -h | --help | help) _help ; exit ;;
      -* | --*) err_msg "No such option: $argument.\nType yta [-h|--help|help] to see a list of all options." && exit ;;
      *) dependencies_check; [[ $ytfzf = true ]] && find $argument || download $argument ; exit ;;
    esac
  done
  err_msg "Something went wrong..." && exit;
}

[[ ${#} -eq 0 ]] && banner || __main__ "$@" 
