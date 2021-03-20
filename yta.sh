#!/usr/bin/env sh
# Author : Stanley <git.io/monesonn>
# Description: .sh wrapper around youtube-dl for easier audio downloading.

# Script version
__version="0.5.0"

# GENERAL

## Default directories
dir="$HOME/Music"

## Output Template
output='%(uploader)s - %(title)s [%(id)s].%(ext)s'

## Default variables
quiet='--quiet --console-title'
audio_ext='mp3'
bitrate='128K'
sample_rate='48000'

## Variables
playlist=false
sox=false
ytfzf=false
beets=false 
parallel=false 
ytfzf_ops=''
default_jobs=5

## Color codes
gc="\033[0;32m"   # green
yc="\033[1;33m"   # yellow
pc="\033[0;35m"   # purple
bc="\033[34m"     # blue
dbc="\033[1;34m"  # dark blue
cc="\033[36m"     # cyan
rc="\033[0;31m"   # red
nc="\033[0;m"     # no color
dim="\033[2m"     # dim

banner() {
printf %b\\n \
"${bc}             __             __   __ 
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
-v  --version   version    -v for yta's version
                           --version for yta's and youtube-dl version
-h  --help      help       Show this help text

Example: yta https://youtu.be/[url]
         yta -p https://www.youtube.com/playlist?list=[url]
         yta -a=aac -s=44000 -b=256 https://youtu.be/[url]
         yta -f "Title in Youtube"
EOF
}

dep_check() {
  local dep_status=false
  for dep in "$@"; do command -v "$dep" 1>/dev/null || { err_msg "$dep not found."; [ $dep_status = false ] && dep_status=true; } done; 
  [ $dep_status = true ] && err_msg "Install all of the above packages to make script work properly." && exit;
}

err_msg() { printf %b\\n "${rc}[!] ${yc}$@${nc}"; }

download() {
  local url=$1
  [ $audio_ext = mp3 ] && local embed="--embed-thumbnail" || local embed="" 
  if [ $playlist = true ] ; then
    local playlist_title="$(youtube-dl --no-warnings --flat-playlist --dump-single-json $url | jq -r ".title")"
    printf %b\\n "[yata] Playlist ${gc}\"${playlist_title}\"${nc}"
    printf %b\\n "${bc}[yata]${nc} Downloading to ${playlist_dir}"
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
    --output "${dir}/playlists/${playlist_title}/%(playlist_index)s %(title)s.%(ext)s" \
    --exec "printf %b \"${gc}[yata]${nc} \" && printf %s {} | tr -d \'\\"'"'" | awk -F \"/\" '"'{printf $NF}'"' && printf '%s\n' \" is downloaded.\"" \
    $url 2>/dev/null
    printf %b\\n "${bc}[yata]${nc} Playlist ${gc}\"${playlist_title}\"${nc} is downloaded."
    if [ $sox = true ] ;  then
      dep_check "sox"
      printf %b\\n "${yc}[sox]${nc} Starting to merge ${gc}${playlist_title}${nc}."
      sox "${dir}/playlists/${playlist_title}/*.${audio_ext}" "${dir}/${audio_ext}/${playlist_title}.${audio_ext}"
      printf %b\\n "${yc}[sox]${nc} ${dir}/${audio_ext}/${playlist_title}.${audio_ext} is merged."
    fi
    if [ $beets = true ] ; then
      dep_check "beets"
      printf %b\\n "${yc}[beets]${nc} Adding to library."
      beet import "${dir}/playlists/${playlist_title}"
      printf %b\\n "${yc}[beet]${nc} Import is done."
    fi
  else
    local title="$(youtube-dl --get-title $url)"
    printf %b\\n "[yata] Title ${gc}\"${title}\"${nc}"
    printf %b\\n "${bc}[yata]${nc} Downloading to ${dir}"
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
    --exec "printf %b \"${gc}[yata]${nc} \" && printf %s {} | tr -d \'\\"'"'" | awk -F \"/\" '"'{printf $NF}'"' && printf '%s\n' \" is downloaded.\"" \
    $url 2>/dev/null
  fi
  printf %b\\n "${bc}[yata]${nc} All is done."
}

parallel_download() {
  local url=$1
  [ $audio_ext = mp3 ] && local embed="--embed-thumbnail" || local embed="" 
  local playlist_title="$(youtube-dl --no-warnings --flat-playlist --dump-single-json $url | jq -r ".title")"
  printf %b\\n "[yata] Playlist ${gc}\"${playlist_title}\"${nc}"
  printf %b\\n "${bc}[yata]${nc} Downloading to ${playlist_dir}"
  youtube-dl --get-id $url \
  | xargs -I '{}' -P 5 \
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
  --output "${dir}/${playlist_title}/%(title)s.%(ext)s" \
  --exec "printf %b \"${gc}[yata]${nc} \" && youtube-dl -e 'https://youtube.com/watch?v={}' is downloaded." \
  'https://youtube.com/watch?v={}' 2>/dev/null
  printf %b\\n "${bc}[yata]${nc} Playlist ${gc}\"${playlist_title}\"${nc} is downloaded."
  printf %b\\n "${bc}[yata]${nc} All is done."
}

find() {
  dep_check "ytfzf"
  printf %b\\n "${bc}[ytfzf]${nc} Searching for \"$1\""
  local url="$(ytfzf -L "$@")"
  [[ $url = '' ]] && exit
  local title="$(youtube-dl --get-title $url)"
  printf %b\\n "${bc}[yata]${nc} ${title} is playing."
  ytfzf -am $url
  printf %b\\n "${bc}[yata]${nc} Do you want to download it?"
  read -n 1 -s -e -p '[y/N]> ' answer
  [ $answer != "${answer#[Yy]}" ] && download $url || printf %b\\n "${bc}[yata]${nc} All is done."
  exit
}

__main__() {
  dep_check "youtube-dl" "awk" "jq"
  while [ "$#" -gt 0 ]; do
    argument="$1"
    case $argument in
      -a=* | --audio=* | audio=*) audio_ext="${argument#*=}" ; shift ;;
      -b=* | --bitrate=* | bitrate=*) bitrate="${argument#*=}" ; shift ;;
      -p=* | --path=* | path=*) dir="${argument#*=}" ; shift ;;
      -f=* | --fzf=* | fzf=*) ytfzf_ops="${argument#*=}" ; ytfzf=true; shift ;;
      -V | --verbose | verbose) quiet='' ; shift ;;
      -d | --path | path) dir="$PWD"; playlist_dir=$dir; shift ;;
      -x | --sox | sox) sox=true ; shift ;; 
      -f | --find | find) ytfzf=true; shift ;;
      -p | --playlist | playlist) playlist=true ; shift ;;
      -P | --parallel | parallel) parallel=true; shift ;;
      -B | --beets | beets) beets=true ; shift ;;
      -v | v) printf %s\\n "yata: $__version"; exit ;;
      --version | version) printf %s\\n%s\\n "yata: $__version" "youtube-dl: $(youtube-dl --version)" ; exit ;;
      -h | --help | help) _help ; exit ;;
      -* | --*) err_msg "No such option: $argument.\nType yta [-h|--help|help] to see a list of all options." ;;
      *) [ $ytfzf = true ] && find $argument; 
      [ $parallel = true ] \
      && parallel_download $argument \
      || download $argument ; \
      exit ;;
    esac
  done
  err_msg "Something went wrong...";
}

[ ${#} -eq 0 ] && banner || __main__ "$@" 
