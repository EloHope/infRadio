#!/bin/bash

# infRadio

# developed for Linux bash shell.

# Please make sure that you have installed the following packages:
# - vlc (includes cvlc)
# - wget
# - mpg123
# - ffmpeg (version 4.4 or higher includes speechnorm filter, but infRadio runs OK even without that particular filter)
# - youtube-dl
# - curl
# - shuf
# - bc (for calculations)


# Install ffmpeg 4.4 on Ubuntu with ppa:
# https://ubuntuhandbook.org/index.php/2021/05/install-ffmpeg-4-4-ppa-ubuntu-20-04-21-04/
# Install ffmpeg 4.4 on Debian, Ubuntu and other distributions:
# https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu


# =================================
 
# FUNCTIONS: DOWNLOADING NEWS BROADCASTS AND NORMALIZING BROADCAST SOUND VOLUME IN SOME CASES

# First we present functions that will be used in the main part of the script.
# The bits of code for making music playlists, downloading news broadcasts 
# and listening to infRadio will follow later.

# =================================

speech_norm_test () {
# Testing if speechnorm filter is available. It is available in ffmpeg version 4.4. and higher.
speechtest="$(ffmpeg -v quiet -filters | grep -i speechnorm)" > /dev/null 2>&1
if [[ "$speechtest" == *"speechnorm"* ]]
then 
	speechresult="Yes"
else 
	speechresult="No" 
fi
}


abcradnatnews () {
trap '' 2  # Disable Ctrl + C for this function.
# ABC Radio National seems not to provide news podcasts. 
# That is why we record their next news broadcast for 6 minutes. 
# (On the hour + estimated Internet delay).
# echo "Timer set for recording ABC news. Select additional broadcasts or listen to infRadio."
( now_is=$(date +%H); next_hour=$(date -d "$now_is + 1 hour" +'%H:%M:%S'); now_in_seconds=$(date +'%H:%M:%S'); SEC1=$(date +%s -d "${now_in_seconds}"); SEC2=$(date +%s -d "${next_hour}"); DIFFSEC=$(( SEC2 - SEC1 + 15 )); sleep "$DIFFSEC" ) &
# find ~/funkRadio/Talk/ -type f -iname "*ABCradnat*" -exec mv {} ~/funkRadio/Archive/ \;
until wait;do :;done # Because of trapping Ctrl + C; see https://superuser.com/questions/1719758/bash-script-to-catch-ctrlc-at-higher-level-without-interrupting-the-foreground

cvlc -q http://live-radio01.mediahubaustralia.com/2RNW/mp3/ --sout file/mp3:/home/$USER/funkRadio/Talk/ABCradnatnews1 --run-time=360 vlc://quit > /dev/null 2>&1
if [[ $speechresult = "Yes" ]]
then
	# ffmpeg speechnorm normalization: default value is speechnorm=p=0.95.
	ffmpeg -i /home/$USER/funkRadio/Talk/ABCradnatnews1 -filter:a speechnorm=p=0.95 /home/$USER/funkRadio/Talk/ABCradnatnews.mp3 > /dev/null 2>&1
	# timeis=$(date +"%d_%H%M%S"); echo "speechnorm=p=0.95 ABCradnatnews.mp3 ${timeis}" >> ~/funkRadio/Archive/speechnormlog.txt
else
	ffmpeg -i /home/$USER/funkRadio/Talk/ABCradnatnews1 -af 'volume=1.4' /home/$USER/funkRadio/Talk/ABCradnatnews.mp3 > /dev/null 2>&1
	# timeis=$(date +"%d_%H%M%S"); echo "NO_speechnorm ABCradnatnews.mp3 ${timeis}" >> ~/funkRadio/Archive/speechnormlog.txt
fi
rm /home/$USER/funkRadio/Talk/ABCradnatnews1
echo "ABCradnatnews".mp3 >> ~/funkRadio/Archive/infRadiolog.txt
}

abcpm () {
version_of_old_podcast="$(cat ~/funkRadio/Archive/infRadiolog.txt | grep ABC_pm.mp3 | tail -1)"
version_of_new_podcast="$(wget -q -O - https://www.abc.net.au/radio/programs/pm/feed/8863592/podcast.xml | grep -oP '(?<=url=").*(?=" length)' | head -1)" > /dev/null 2>&1
version_number_of_new_podcast="$(echo "${version_of_new_podcast}" | rev | cut -d'/' -f 1 | rev)"
if [ "$version_of_old_podcast" = "" ]
then
  echo "ABC_pm.mp3 ${version_number_of_new_podcast}" >> ~/funkRadio/Archive/infRadiolog.txt
  wget -q -O ~/funkRadio/Talk/ABCpm.mp3 "$version_of_new_podcast" > /dev/null 2>&1
else
  version_number_of_old_podcast="${version_of_old_podcast/ABC_pm.mp3 /}"
  if [[ "$version_number_of_new_podcast" != "$version_number_of_old_podcast" ]]
  then
    # find ~/funkRadio/Talk/ -type f -iname "*ABC_pm*" -exec mv {} ~/funkRadio/Archive/ \;
    # sed -i '/ABC_pm/d' ~/funkRadio/Archive/infRadiolog.txt
    wget -q -O ~/funkRadio/Talk/ABCpm.mp3 "$version_of_new_podcast" > /dev/null 2>&1
    echo "ABC_pm.mp3 ${version_number_of_new_podcast}" >> ~/funkRadio/Archive/infRadiolog.txt
  fi
fi
# sed -i '/^[[:space:]]*$/d' ~/funkRadio/Archive/infRadiolog.txt
}

bbc4news_briefing () {
version_of_old_podcast="$(cat ~/funkRadio/Archive/infRadiolog.txt | grep BBC_4news_briefing.mp3 | tail -1)"
version_of_new_podcast=$(wget -q -O - https://www.bbc.co.uk/programmes/b007rhyn/episodes/player | grep https://www.bbc.co.uk/sounds/play | grep -o -P '(?<=href=").*(?=")' | head -1) > /dev/null 2>&1
version_number_of_new_podcast="$(echo "${version_of_new_podcast}" | rev | cut -d'/' -f 1 | rev)"
if [ "$version_of_old_podcast" = "" ]
then
  addr=$(wget -q -O - https://www.bbc.co.uk/programmes/b007rhyn/episodes/player | grep https://www.bbc.co.uk/sounds/play | grep -o -P '(?<=href=").*(?=")' | head -1) > /dev/null 2>&1
  youtube-dl -q --no-warnings -o ~/funkRadio/Talk/BBC_4news_briefing1.mp3 "${addr}" > /dev/null 2>&1
  ffmpeg -nostats -loglevel 0 -i ~/funkRadio/Talk/BBC_4news_briefing1.mp3 -acodec libmp3lame -ac 2 -ab 128k -ar 48000 ~/funkRadio/Talk/BBC_4news_briefing.mp3 > /dev/null 2>&1
  echo "BBC_4news_briefing.mp3 ${version_number_of_new_podcast}" >> ~/funkRadio/Archive/infRadiolog.txt
  touch ~/funkRadio/Talk/BBC_4news_briefing.mp3 # Correcting timestamp.
else
  version_number_of_old_podcast="${version_of_old_podcast/BBC_4news_briefing.mp3 /}"
  if [ "$version_number_of_new_podcast" != "$version_number_of_old_podcast" ]
  then
    # find ~/funkRadio/Talk/ -type f -iname "*4news_briefing*" -exec mv {} ~/funkRadio/Archive/ \;
    # sed -i '/4news_briefing/d' ~/funkRadio/Archive/infRadiolog.txt
    addr=$(wget -q -O - https://www.bbc.co.uk/programmes/b007rhyn/episodes/player | grep https://www.bbc.co.uk/sounds/play | grep -o -P '(?<=href=").*(?=")' | head -1) > /dev/null 2>&1
    youtube-dl -q --no-warnings -o ~/funkRadio/Talk/BBC_4news_briefing1.mp3 "${addr}" > /dev/null 2>&1
    ffmpeg -nostats -loglevel 0 -i ~/funkRadio/Talk/BBC_4news_briefing1.mp3 -acodec libmp3lame -ac 2 -ab 128k -ar 48000 ~/funkRadio/Talk/BBC_4news_briefing.mp3 > /dev/null 2>&1
    # if [ -f ~/funkRadio/Talk/BBC_4news_briefing1.mp3 ]; then mv ~/funkRadio/Talk/BBC_4news_briefing1.mp3 ~/funkRadio/Archive/; fi
    touch ~/funkRadio/Talk/BBC_4news_briefing.mp3 # Correcting timestamp.
    echo "BBC_4news_briefing.mp3 ${version_number_of_new_podcast}" >> ~/funkRadio/Archive/infRadiolog.txt
  fi
fi
if [ -f ~/funkRadio/Talk/BBC_4news_briefing1.mp3 ]; then rm  ~/funkRadio/Talk/BBC_4news_briefing1.mp3; fi
# sed -i '/^[[:space:]]*$/d' ~/funkRadio/Archive/infRadiolog.txt
}

bbcworldnews () {
version_of_old_podcast="$(cat ~/funkRadio/Archive/infRadiolog.txt | grep BBC_worldnews.mp3 | tail -1)"
version_of_new_podcast=$(wget -q -O - https://www.bbc.co.uk/programmes/p002vsmz/episodes/player | grep https://www.bbc.co.uk/sounds/play | grep -o -P '(?<=href=").*(?=")' | head -1) > /dev/null 2>&1
version_number_of_new_podcast="$(echo "${version_of_new_podcast}" | rev | cut -d'/' -f 1 | rev)"
if [ "$version_of_old_podcast" = "" ]
then
  addr=$(wget -q -O - https://www.bbc.co.uk/programmes/p002vsmz/episodes/player | grep https://www.bbc.co.uk/sounds/play | grep -o -P '(?<=href=").*(?=")' | head -1) > /dev/null 2>&1
  youtube-dl -q --no-warnings -o ~/funkRadio/Talk/BBC_worldnews1.mp3 "${addr}" > /dev/null 2>&1
  echo "BBC_worldnews.mp3 ${version_number_of_new_podcast}" >> ~/funkRadio/Archive/infRadiolog.txt
else
  version_number_of_old_podcast="${version_of_old_podcast/BBC_worldnews.mp3 /}"
  if [ "$version_number_of_new_podcast" != "$version_number_of_old_podcast" ]
  then
    # find ~/funkRadio/Talk/ -type f -iname "*BBC_worldnews*" -exec mv {} ~/funkRadio/Archive/ \;
    # sed -i '/worldnews/d' ~/funkRadio/Archive/infRadiolog.txt
    addr=$(wget -q -O - https://www.bbc.co.uk/programmes/p002vsmz/episodes/player | grep https://www.bbc.co.uk/sounds/play | grep -o -P '(?<=href=").*(?=")' | head -1) > /dev/null 2>&1
    youtube-dl -q --no-warnings -o ~/funkRadio/Talk/BBC_worldnews1.mp3 "${addr}" > /dev/null 2>&1
  echo "BBC_worldnews.mp3 ${version_number_of_new_podcast}" >> ~/funkRadio/Archive/infRadiolog.txt
  fi
fi
if [ -f ~/funkRadio/Talk/BBC_worldnews1.mp3 ]
then
ffmpeg -nostats -loglevel 0 -i ~/funkRadio/Talk/BBC_worldnews1.mp3 -acodec libmp3lame -ac 2 -ab 128k -ar 48000 ~/funkRadio/Talk/BBC_worldnews2.mp3 > /dev/null 2>&1
  if [[ $speechresult == "Yes" ]]
  then
	  # ffmpeg speechnorm normalization: default value is speechnorm=p=0.95.
	  ffmpeg -i ~/funkRadio/Talk/BBC_worldnews2.mp3 -filter:a speechnorm=p=0.93 ~/funkRadio/Talk/BBC_worldnews.mp3 > /dev/null 2>&1
	  # timeis=$(date +"%d_%H%M%S"); echo "speechnorm=p=0.93 BBC_worldnews.mp3 ${timeis}" >> ~/funkRadio/Archive/speechnormlog.txt
  else
	  ffmpeg -i ~/funkRadio/Talk/BBC_worldnews2.mp3 -af 'volume=1.4' ~/funkRadio/Talk/BBC_worldnews.mp3 > /dev/null 2>&1
	  # timeis=$(date +"%d_%H%M%S"); echo "NO_speechnorm BBC_worldnews.mp3 ${timeis}" >> ~/funkRadio/Archive/speechnormlog.txt
  fi
fi
if [ -f ~/funkRadio/Talk/BBC_worldnews1.mp3 ]; then rm ~/funkRadio/Talk/BBC_worldnews1.mp3; fi
if [ -f ~/funkRadio/Talk/BBC_worldnews2.mp3 ]; then rm ~/funkRadio/Talk/BBC_worldnews2.mp3; fi
# sed -i '/^[[:space:]]*$/d' ~/funkRadio/Archive/infRadiolog.txt
}


dlf () {

# News from the German public radio Deutschlandfunk.
modtime_of_old_podcast="$(cat ~/funkRadio/Archive/infRadiolog.txt | grep Dlf_nachrichten.mp3 | tail -1 | cut -d' ' -f2-)"
# echo "1modtime_of_old_podcast= ${modtime_of_old_podcast}"
has_modtime_of_new_podcast="$(curl -sI "http://ondemand-mp3.dradio.de/file/dradio/nachrichten/nachrichten.mp3" | grep -i Last-Modified | cut -d',' -f 2)"
# modtime_of_new_podcast="$(echo "${has_modtime_of_new_podcast}" | cut -d',' -f 2)"
modtime_of_new_podcast="$(echo -e "${has_modtime_of_new_podcast}" | tr -d '[:space:]' | tr -d ':')"
# modtime_of_new_podcast="${modtime_of_new_podcast:1}"
# echo "1modtime_of_new_podcast= ${modtime_of_new_podcast}"
if [ "$modtime_of_old_podcast" = "" ]
then
  wget -q -O ~/funkRadio/Talk/Dlf_nachrichten1.mp3 "http://ondemand-mp3.dradio.de/file/dradio/nachrichten/nachrichten.mp3" > /dev/null 2>&1
  echo "Dlf_nachrichten.mp3 ${modtime_of_new_podcast}" >> ~/funkRadio/Archive/infRadiolog.txt
else
  if [ "$modtime_of_old_podcast" != "$modtime_of_new_podcast" ]
  then 
    # find ~/funkRadio/Talk/ -type f -iname "*Dlf_nachrichten*" -exec mv {} ~/funkRadio/Archive/ \;
    # Modify the infRadiolog file:
    # sed -i '/Dlf_nachrichten.mp3/d' ~/funkRadio/Archive/infRadiolog.txt
    wget -q -O ~/funkRadio/Talk/Dlf_nachrichten1.mp3 "http://ondemand-mp3.dradio.de/file/dradio/nachrichten/nachrichten.mp3" > /dev/null 2>&1
    echo "Dlf_nachrichten.mp3 ${modtime_of_new_podcast}" >> ~/funkRadio/Archive/infRadiolog.txt
  fi
fi

if [ -f ~/funkRadio/Talk/Dlf_nachrichten1.mp3 ]; then
  # Removing loud station identifications from the beginning and the end of the file.
  news_de_duration_original=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 ~/funkRadio/Talk/Dlf_nachrichten1.mp3) 
  # news_de_duration_trimmed=$(echo "$news_de_duration_original - 9.0 - 3.9" | bc -l | awk '{ printf("%.1f\n",$1) '})
  news_de_duration_trimmed=$(echo "$news_de_duration_original - 9.0 - 3.9" | bc -l | awk '{ printf("%.1f\n",$1) }')
  news_de_duration_trimmed=${news_de_duration_trimmed//,/.} # Replace comma with dot. Debian-based systems may need this.
  ffmpeg -ss 3.9 -i ~/funkRadio/Talk/Dlf_nachrichten1.mp3 -t ${news_de_duration_trimmed} ~/funkRadio/Talk/Dlf_nachrichten2.mp3  > /dev/null 2>&1
  if [[ $speechresult == "Yes" ]]
  then
    # ffmpeg speechnorm normalization: default value is speechnorm=p=0.95.
    ffmpeg -i ~/funkRadio/Talk/Dlf_nachrichten2.mp3 -filter:a speechnorm=p=0.90 ~/funkRadio/Talk/Dlf_nachrichten.mp3 > /dev/null 2>&1
    # timeis=$(date +"%d_%H%M%S"); echo "speechnorm=p=0.90 Dlf_nachrichten.mp3 ${timeis}" >> ~/funkRadio/Archive/speechnormlog.txt
  else
    ffmpeg -i ~/funkRadio/Talk/Dlf_nachrichten2.mp3 -af 'volume=1.4' ~/funkRadio/Talk/Dlf_nachrichten.mp3 > /dev/null 2>&1
    # timeis=$(date +"%d_%H%M%S"); echo "NO_speechnorm Dlf_nachrichten.mp3 ${timeis}" >> ~/funkRadio/Archive/speechnormlog.txt

  fi
fi
if [ -f ~/funkRadio/Talk/Dlf_nachrichten1.mp3 ]; then rm ~/funkRadio/Talk/Dlf_nachrichten1.mp3; fi
if [ -f ~/funkRadio/Talk/Dlf_nachrichten2.mp3 ]; then rm ~/funkRadio/Talk/Dlf_nachrichten2.mp3; fi
# sed -i '/^[[:space:]]*$/d' ~/funkRadio/Archive/infRadiolog.txt
}

npr () {

# News from the U.S. public radio NPR.
old_in_seconds="$(cat ~/funkRadio/Archive/infRadiolog.txt | grep Npr_newscast.mp3 | tail -1 | cut -d' ' -f2-)"
# echo "old_in_seconds= $old_in_seconds"
if [ "$modtime_of_old_podcast" = "" ]
then
  modtime_of_new_podcast="$(curl --head http://pd.npr.org/anon.npr-mp3/npr/news/newscast.mp3  2>&1 | grep -i Last-Modified)"
  just_modtime_of_new_podcast=${modtime_of_new_podcast/Last-Modified: /}
  new_in_seconds="$(date -d "${just_modtime_of_new_podcast}" +%s)"
  # echo "1new_in_seconds= ${new_in_seconds}"
  # exit
  wget -q -O ~/funkRadio/Talk/Npr_newscast.mp3 "http://pd.npr.org/anon.npr-mp3/npr/news/newscast.mp3"
  echo "Npr_newscast.mp3 ${new_in_seconds}" >> ~/funkRadio/Archive/infRadiolog.txt
else
  # old_in_seconds="${modtime_of_old_podcast/Npr_newscast.mp3 /}"
  echo "old_in_seconds= ${old_in_seconds}"
  modtime_of_new_podcast="$(curl --head http://pd.npr.org/anon.npr-mp3/npr/news/newscast.mp3  2>&1 | grep -i Last-Modified)"
  just_modtime_of_new_podcast=${modtime_of_new_podcast/Last-Modified: /}
  new_in_seconds="$(date -d "${just_modtime_of_new_podcast}" "+%s")"
  # echo "2new_in_seconds= ${new_in_seconds}"
  #exit

  if (( new_in_seconds > old_in_seconds ))
  then
    if [ -f ~/funkRadio/Talk/Npr_newscast.mp3 ]; then rm ~/funkRadio/Talk/Npr_newscast.mp3; fi
    # Modify the infRadiolog file:
    # sed -i '/Npr_newscast.mp3/d' ~/funkRadio/Archive/infRadiolog.txt
    wget -q -O ~/funkRadio/Talk/Npr_newscast.mp3 "http://pd.npr.org/anon.npr-mp3/npr/news/newscast.mp3"
    echo "Npr_newscast.mp3 ${new_in_seconds}" >> ~/funkRadio/Archive/infRadiolog.txt
  fi
fi
# sed -i '/^[[:space:]]*$/d' ~/funkRadio/Archive/infRadiolog.txt
}

sverigesradio () {

# News from Swedish public radio.
version_number_of_old_podcast="$(cat ~/funkRadio/Archive/infRadiolog.txt | grep Sr_nyheter.mp3 | tail -1 | cut -d' ' -f2-)"
# echo "version_number_of_old_podcast= ${version_number_of_old_podcast}"
pod_enclosure="$(wget -q -O - https://api.sr.se/api/rss/pod/3795 | grep enclosure | head -1)" > /dev/null 2>&1
pod_file="$(echo "$pod_enclosure" | grep -oP '(?<=url=").*(?=" length)')" > /dev/null 2>&1
version_indicator="$(echo "${pod_file=}" | rev | cut -d'/' -f 1 | rev)"
version_number_of_new_podcast="$(echo "${version_indicator::-4}")"
rimpsu="$(wget -q -O - https://api.sr.se/api/rss/pod/3795 | grep enclosure | head -1)" > /dev/null 2>&1
osoite="$(echo "$rimpsu" | grep -oP '(?<=url=").*(?=" length)')" > /dev/null 2>&1
if [ "$version_of_old_podcast" = "" ]
then
  echo "Sr_nyheter.mp3 ${version_number_of_new_podcast}" >> ~/funkRadio/Archive/infRadiolog.txt
  # echo "version_number_of_new_podcast= ${version_number_of_new_podcast}"
	wget -q -O ~/funkRadio/Talk/Sverigesradio.mp3 "${osoite}" > /dev/null 2>&1
  # wget -q -O ~/funkRadio/Talk/Sr_nyheter.mp3 "${pod_file}" > /dev/null 2>&1
else
  if (( version_number_of_new_podcast > version_number_of_old_podcast ))
  then
		# echo "2 -- version_number_of_new_podcast= ${version_number_of_new_podcast}"
    mv ~/funkRadio/Talk/Sr_nyheter.mp3 ~/funkRadio/Archive/
    # Modify the infRadiolog file:
    # sed -i '/Sr_nyheter.mp3/d' ~/funkRadio/Archive/infRadiolog.txt
    wget -q -O ~/funkRadio/Talk/Sverigesradio.mp3 "${osoite}" > /dev/null 2>&1
    # wget -q -O ~/funkRadio/Talk/Sr_nyheter.mp3 "${pod_file}" > /dev/null 2>&1
    echo "Sr_nyheter.mp3 ${version_number_of_new_podcast}" >> ~/funkRadio/Archive/infRadiolog.txt
  fi
fi
# sed -i '/^[[:space:]]*$/d' ~/funkRadio/Archive/infRadiolog.txt
}


yle_downloads () {
addr_in_haystack="$(curl -s -r 2000-3000 $yle_region_rss)" > /dev/null 2>&1
addr2="$(echo "${addr_in_haystack}" | grep -o 'url=.*" type' | head -1)" > /dev/null 2>&1
addr2="${addr2//\" type}"
addr2="${addr2//\url=\"}"
version_of_old_podcast="$(cat ~/funkRadio/Archive/infRadiolog.txt | grep "$yle_region".mp3 | tail -1)"
file_id_of_old_podcast="${version_of_old_podcast/$yle_region.mp3 /}"
# file_id_of_old_podcast="$(echo "$file_id_of_old_podcast2" | rev | cut -d' ' -f 1 | rev)"
# echo "$file_id_of_old_podcast"

file_id_of_new_podcast2="$(echo "$addr2" | rev | cut -d'/' -f 1 | rev)"
file_id_of_new_podcast="$(echo "$file_id_of_new_podcast2" | rev | cut -d'-' -f 1 | rev)"
# echo "$file_id_of_new_podcast"

if [ "$file_id_of_old_podcast" = "" ]
then
  wget -q -O ~/funkRadio/Talk/"$yle_region"1.mp3 "$addr2" > /dev/null 2>&1
  echo "$yle_region.mp3 ${file_id_of_new_podcast}" >> ~/funkRadio/Archive/infRadiolog.txt
  # Removing a loud station identification from the beginning of the file.
  ffmpeg -ss 3.5 -i ~/funkRadio/Talk/"$yle_region"1.mp3 ~/funkRadio/Talk/"$yle_region".mp3 > /dev/null 2>&1
	echo "$yle_region.mp3 ${file_id_of_new_podcast}" >> ~/funkRadio/Archive/infRadiolog.txt
  mv ~/funkRadio/Talk/"$yle_region".mp3 ~/funkRadio/Talk/"$yle_region".mp3
	rm ~/funkRadio/Talk/"$yle_region"1.mp3
else
  if [[ "$file_id_of_new_podcast" == "$file_id_of_old_podcast" ]]
  then
    echo "$yle_region - no update available."
  else
    find ~/funkRadio/Talk/ -type f -iname "*$yle_region*" -exec rm {} \;
    wget -q -O ~/funkRadio/Talk/"$yle_region"1.mp3 "$addr2" > /dev/null 2>&1
    # Removing a loud station identification from the beginning of the file:
    ffmpeg -ss 3.5 -i ~/funkRadio/Talk/"$yle_region"1.mp3 ~/funkRadio/Talk/"$yle_region".mp3 > /dev/null 2>&1
    echo "$yle_region.mp3 ${file_id_of_new_podcast}" >> ~/funkRadio/Archive/infRadiolog.txt
    mv ~/funkRadio/Talk/"$yle_region".mp3 ~/funkRadio/Talk/"$yle_region".mp3
		rm ~/funkRadio/Talk/"$yle_region"1.mp3
  fi
fi
# mv ~/funkRadio/Talk/"$yle_region"1.mp3 ~/funkRadio/Archive
# sed -i '/^[[:space:]]*$/d' ~/funkRadio/Archive/infRadiolog.txt
}

yleppohjanmaa () {

yle_region="YLEppohjanmaa"
yle_region_rss="https://feeds.yle.fi/areena/v1/series/1-4479456.rss?"
yle_downloads
}

ylepsavo () {

yle_region="YLEpsavo"
yle_region_rss="https://feeds.yle.fi/areena/v1/series/1-4479312.rss?"
yle_downloads
}

yleradiosuomi () {

yle_region="YLEfinland"
yle_region_rss="https://feeds.yle.fi/areena/v1/series/1-1440981.rss?"
yle_downloads
}

play_random_song () {
random_song="$(shuf -n 1 "${Playlist}")"
random_song_basename=$(basename "${random_song}")
echo "Now playing ${random_song}"
echo "${random_song}" >> ~/funkRadio/Archive/musicRadiolog.txt
mpg123 -C "${random_song}" # With the option '-vC' mpg123 controls might work, but with some screen clutter
sleep 1
}

download_news () {
( abcradnatnews > /dev/null 2>&1 ) &
( bbcworldnews > /dev/null 2>&1 ) &
( dlf > /dev/null 2>&1 ) &
( npr > /dev/null 2>&1 ) &
( bbc4news_briefing > /dev/null 2>&1 ) &
( abcpm > /dev/null 2>&1 ) &
( sverigesradio > /dev/null 2>&1 ) &
# ( yleppohjanmaa > /dev/null 2>&1 ) &
# ( ylepsavo > /dev/null 2>&1 ) &
( yleradiosuomi > /dev/null 2>&1 ) &
play_random_song
listen_to_the_radio
}

# =================================
# MORE FUNCTIONS: LISTENING TO NEWS BROADCASTS & MUSIC

# =================================


# The function 'listen_to_the_radio' plays first a random piece of music from the playlist
# and then a news broadcast in the ~/funkRadio/Talk/ directory.
# With Ctrl+C you can toggle between music and news.

listen_to_the_radio () {
cd $(dirname "$0") || exit # Go to the directory containing this script.
if [ "$timer_on" = "Yes" ]
then 
  val1=$(date --date=$timer_limit +%s)
  val2=$(date +%s)
  if [ $val1 -gt $val2 ]
  then 
    :
  else
    echo "Stopped after time limit $timer_limit_readable was exceeded."
    exit 0
  fi
fi

declare -a array_of_news_broadcasts
IFS=$'\n' read -r -d '' -a array_of_news_broadcasts < <( find /home/$USER/funkRadio/Talk/ -maxdepth 1 -name "*.mp3" && printf '\0' )
if [ ${#array_of_news_broadcasts[@]} -eq 0 ]
then
  download_news
else
  # Earliest_news_broadcast="$(find /home/$USER/funkRadio/Talk/ -type f -printf '%T+ %f\n' | sort | head -n 1 | cut -d" " -f2)"
  a_news_broadcast="${array_of_news_broadcasts[0]}"
  echo "Now playing ${a_news_broadcast}."
  mpg123 -C "${a_news_broadcast}" # With '-vC' mpg123 controls might actually work, but with additional screen output
  # If you want to archive news broadcasts for later inspection:
  # mv "${a_news_broadcast}" /home/"$USER"/funkRadio/Archive/
  # Comment the following out if you want to keep news broadcasts in the archive.
  rm "${a_news_broadcast}"
  # mv "${a_news_broadcast}" ~/funkRadio/Archive/
  sleep 1
  if [[ "$skip_music" = "No" ]]
  then
    play_random_song
  else
    if [ -e "$HOME/funkRadio/ocean_wave.mp3" ]
    then
      mpg123 -C "$HOME/funkRadio/ocean_wave.mp3"
    else
      sleep 2
    fi
  fi
  listen_to_the_radio
fi

# clear

# if [ ${#array_of_news_broadcasts[@]} -eq 0 ]
# then
#   if [[ "$skip_music" = "Yes" ]]
#   then
#     echo "No downloaded broadcasts are available and no music playlist was selected."
#     exit 0
#   else
#   download_news
#   # Tidying up in various places:
#   sed -i '/^[[:space:]]*$/d' ~/funkRadio/Archive/musicRadiolog.txt
#   sed -i '/^[[:space:]]*$/d' ~/funkRadio/Archive/infRadiolog.txt
#   sed -i -e 's/\r$//' ~/funkRadio/Archive/infRadiolog.txt # Remove dos-style carriage returns.
#   listen_to_the_radio
#   fi
# else
# sleep 1


}

# =================================
# THE CONTROL PANEL OF FUNKRADIO: SELECT BROADCASTS TO BE DOWNLOADED
# AND PLAY FUNKRADIO OR TURN IT OFF
# =================================

control_panel () {
while true
do
clear
if [ -s "${Playlist}" ]
then
  echo "Music playlist is ${Playlist} - it has $Playlist_lines songs."
else
  echo "Music playlist ${Playlist} is empty. No music will be played."
fi
if [ "$timer_on" = "Yes" ]; then echo "Time limit is set at $timer_limit_readable."; fi
cat <<- end
1 Set timer to switch infRadio off.
2 Play infRadio - your favorite songs alternating with news.
3 Play music only while downloading news.
4 Turn off infRadio - quit the script.
end

  echo "Type one of the listed numbers to do what you want."
  read -r selected_number
  case "$selected_number" in
  "1")
        echo "This option sets the timer. Give a time limit in minutes, please."
        read -r timer
        if [ "$timer" -eq "$timer" ] 2>/dev/null # Testing if "$timer" is a number.
        then
          timer_now=$(date --iso-8601=seconds)
          timer_limit=$(date -d "$timer_now + ${timer} minutes" --iso-8601=seconds)
          timer_limit_readable="$(date -d "$timer_limit" +'%T')"
          timer_on="Yes"
      else
          echo "You did not give a number. No time limit set!"
          timer_on="No"
      fi
      ;;
  "2")
      echo "Listen to the infRadio."
      skip_music="No"
      listen_to_the_radio
      ;;
  "3")
      echo "You will hear music only while news are being downloaded."
      skip_music="Yes"
      listen_to_the_radio
      exit
      ;;
  "4")
      echo "infRadio was turned off."
      exit
      ;;
  *) echo "Invalid option."
      ;;
  esac
done
}


# =================================
# THE MAIN PART OF THE SCRIPT - USER INTERACTIONS START HERE
# =================================

clear
# cd $(dirname "$0") # Go to the directory containing this script.
# echo "Press 'Enter' to launch infRadio. Press other keys to quit."
# read launch_decision
# if [ "$launch_decision" != "" ]
# then
#     exit
# else
# skip_music="No"
# fav=""
number_of_broadcasts=$(find ~/funkRadio/Talk/ -type f -name "*.mp3" | wc -l)
if [ "$number_of_broadcasts" -gt 0 ]
then
    echo "$number_of_broadcasts broadcasts available; press 'Enter' to remove them. Press other keys + 'Enter' to keep them for listening."
    read -r remove_decision
    if [ "$remove_decision" = "" ]
    then
        find ~/funkRadio/Talk/ -type f -name "*.mp3" -exec rm {} \;
        # Taking this opportunity to delete blank lines from musicRadiolog.txt:
        # sed -i '/^[[:space:]]*$/d' ~/funkRadio/Archive/musicRadiolog.txt
    else
        echo "$number_of_broadcasts broadcasts available."
    fi
fi

# ( speech_norm_test ) &
speech_norm_test

clear
cd $(dirname "$0") || exit # Go to the directory containing this script.
echo "$PWD"
# if [[ "$skip_music" = "No" ]]
# then
declare -a array_of_playlists
IFS=$'\n' read -r -d '' -a array_of_playlists < <( find ~/funkRadio/ -maxdepth 1 -name "*.m3u" && printf '\0' )

if [ ${#array_of_playlists[@]} -eq 0 ]
then
  echo "No music playlist available,"
else
  clear
  echo "${#array_of_playlists[@]} playlists are available."
  PS3='Type a number to select playlist. Type 0 to make a new playlist.'
  select Playlist in "${array_of_playlists[@]}"
  do
    if [[ $REPLY == "0" ]]
    then
        make_playlist
    else
        break
    fi
  done
  echo "The chosen playlist was" "$REPLY" "${Playlist}"
  Playlist_lines=$(wc -l "${Playlist}" | awk '{ print $1 }')
  echo "Music playlist is ${Playlist} - it has $Playlist_lines songs."
  control_panel
fi
# fi
control_panel

# ~/funkRadio/infRadio.sh

# sh -x ~/funkRadio/infRadio.sh 2> /$HOME/Desktop/infradio_error_file2.txt; nano /$HOME/Desktop/infradio_error_file2.txt
