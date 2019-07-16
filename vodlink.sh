#
# © oMeN23
# 
#!/bin/bash

# IMPORTANT: THIS IS MENT TO RUN AS AN HOURLY CRON.JOB
# RIP LIVESTREAMS USING YOUTUBE'S v3 API AND STREAMLINK
# AND POST UPDATES TO DISCORD CHANNELS (DISCORD BOT TAKES LINK AS argv[2])
# © 2018–2019 oMeN23 
# NOT GPL - NOT LGPL - this is my IP.
# POSIX COMPLIANT
# uncomment the certain functions like uploadToOL() and updateVODChannel() if you want to use them (and provide the necessary variables)
# also uncomment checkSize & call to use the 10GB limit function on line 118 etc.
# thanks to Bolton, Jakari and all future donators!
# 
# NOTES:
# &> /dev/kmsg would be so much easier or
# let counter++
# using bash builtins to edit text streams instead of long pipes with sed expressions  
# but I ran this on a very small shell and so this is coded POSIX compliant even it is now interpreted by bash
# you could also use (d)ash or any other POSIX compliant shell...
trap 'echo "$PROG[$$][$(date +%R)]: Caught signal…" > $LOGGER;
      echo "$PROG[$$][$(date +%R)]: \"$RIP\" is probably still around!" > $LOGGER;
      echo "$PROG[$$][$(date +%R)]: Exiting…" > $LOGGER;
      rm -f $LOCK;      
      exit 130' TSTP INT TERM HUP
## OS X check - sends output to syslog - TODO need prismane to check
OSXCheck() {
  if [ `uname` = "Linux" ]; then
    LOGGER=/dev/kmsg 2>&1
  elif [ `uname` = "Darwin" ]; then
    LOGGER=/dev/null
    exec 1> >(logger -s -t $(basename $0))
    exec 2> >(logger -s -t $(basename $0))
  fi
}
  

init() {  
  PROG="vodlink v.0.5.4"
  GOOGLE_API_KEY="your_api_key" # we run in a container of cron which has no knowledge of our env
  # ---- configure these four variables and you are set to go ----
  USERNAME=rick
  CHANNELNAME="pewdiepie"
  DLIVENAME="pewdiepie"
  CHANNELID=UC-lHJZR3Gqxm24_Vd_AJ5Yw
  # --------------------------------------------------------------
  OSXCheck # ok function call in place
  mkdir -p /home/$USERNAME/Streamrips
  LOCK=/home/$USERNAME/Streamrips/"$CHANNELNAME"_vodlink.lock
  RIP=/home/$USERNAME/Streamrips/"$CHANNELNAME"_$(date +%d-%m-%Y_%H%M).m2ts
}

checkSize() {
  sleep 30 # so we dont check an empty/nonexistant file the first time we are called
  local limit=10171187200 # exactly 9700MB
  local checkfile=$RIP
  while :
  do
    local size=$(ls -al $checkfile | cut -d ' ' -f5)
    if [ $size -ge $limit ]; then
      echo "$PROG[$$][$(date +%R)]: checkSize() – writing to a new file…" > $LOGGER
      echo "$PROG[$$][$(date +%R)]: Filesize is: $size bytes" > $LOGGER
      # TERM (15) takes 15 mins to work, lets try INT (2), if that doesn't work KILL (9)
      builtin kill -n 9 $streamlinkpid
      echo "$PROG[$$][$(date +%R)]: trying with signal 9 (TERM)" > $LOGGER

      $0 -maxreached &      
      break
    fi
    sleep 900
  done
  return
}

getTitle() {
  local counter=1
  PUBDATE=$(GET "https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$CHANNELID&type=video&eventType=live&key=$GOOGLE_API_KEY" | grep published | sed 's/.\{10\}$//' | sed 's/^.\{31\}//g')
  JSONTITLE=$(GET "https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$CHANNELID&type=video&eventType=live&key=$GOOGLE_API_KEY" | grep title )
  REALTITLE=$(echo $JSONTITLE | sed 's/\ /./g' | tr -cd '[[:alnum:]] =.:_-' | sed 's/^.\{6\}//g')
  #OUT=/home/$USERNAME/Streamrips/$(echo $CHANNELNAME | sed 's/.*/\u&/').Livestream.$(TZ='America/New_York' date +%d.%m.%Y).$REALTITLE.mp4 # use this sed command if you want the first letter of the channelname uppercase
  # its like toUpper(string[0])  
  if [ -z $REALTITLE ]; then
    OUT=/home/$USERNAME/Streamrips/$CHANNELNAME.Livestream.$(TZ='America/Los_Angeles' date +%Y.%m.%d).mp4
  else
    OUT=/home/$USERNAME/Streamrips/$CHANNELNAME.Livestream.$(TZ='America/Los_Angeles' date +%Y.%m.%d).$REALTITLE.mp4
  fi  
  OUT=$(echo $OUT |  sed 's/\ /./g' | sed 's/\.\./\./g') #remove 2 points and make 1 out of them
  while [ -e $OUT ]; do
    counter=$((counter+1))
    OUT=/home/$USERNAME/Streamrips/$CHANNELNAME.Livestream.$(TZ='America/Los_Angeles' date +%Y.%m.%d).$REALTITLE.part$counter.mp4    
  done
  # if you have no problems with unicode titles you also can remove all of my stream editing code
  # and just strip the field identifier from the JSON object returned with only sed 's/^.\{6\}//g' 
  OUT=$(echo $OUT |  sed 's/\ /./g' | sed 's/\.\./\./g') # equivalent of ${OUT//\.\./\.} - better safe than sorry
}

updateVODChannel() {
  echo "$PROG[$$][$(date +%R)]: Sending update to the Discord channel…" > $LOGGER
  PYBOT=/home/$USERNAME/Streamrips/discordbot.py # change to your path
  chmod +x $PYBOT
  DLURL=$(cat $OLOG | cut -d  '"' -f32 | sed 's/\\//g') 
  case $DLURL in # using case for pattern matching
  http*) # URL IS CORRECT
    su $USERNAME -c "$PYBOT \"$PROG\" ${DLURL%/*}"  # python doesnt wanna launch as root...
    ;;
  *) # fallback - if the server returned a 429 unknown error - we fetch the upload list reverse it to get the last ul and get the URL - yep that is a pretty complicated line (=
    DLURL=$(GET "https://api.openload.co/1/file/listfolder?login=$OLOGIN&key=$OKEY&folder=$OFOLDER" |  sed 's/.\{30\}$//' | rev | cut -d '"' -f2 | rev | sed 's/\\//g')
    su $USERNAME -c "$PYBOT \"$PROG\" ${DLURL%/*}" 
    ;;
  esac
}

uploadToOL() {
  echo "$PROG[$$][$(date +%R)]: Starting the upload to OpenLoad…" > $LOGGER
  OLOG=/home/$USERNAME/Streamrips/"$CHANNELNAME"_openload.log
  OLOGIN=""
  OKEY=""
  OFOLDER=""
  OULURL=$(GET "https://api.openload.co/1/file/ul?login=$OLOGIN&key=$OKEY&folder=$OFOLDER" | cut -d '"' -f12 | sed 's/\\//g')
  curl -F file1=@"$OUT" $OULURL > $OLOG
  if [ $? -eq 0 ]; then
    echo "$PROG[$$][$(date +%R)]: Successfully uploaded file to OpenLoad!" > $LOGGER
    #updateVODChannel
  else
    echo "$PROG[$$][$(date +%R)]: Failed to upload the file…" > $LOGGER
  fi
}

isLive() {
  GET "https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$CHANNELID&type=video&eventType=live&key=$GOOGLE_API_KEY" | grep live > /dev/null 
  local liveState=$? 
  if   [ $liveState -eq 0 ] && [ ! -e $LOCK ]; then echo 0
  elif [ $liveState -eq 0 ] && [   -e $LOCK ]; then echo 1
  elif [ $liveState -eq 1 ] && [ ! -e $LOCK ]; then echo 2
  elif [ $liveState -eq 1 ] && [   -e $LOCK ]; then echo 3 
  fi
}

streamLink() {
  touch $LOCK
  if [ -z "$1" ]; then
    echo "$PROG[$$][$(date +%R)]: starting streamlink…" > $LOGGER
    nice -n -5 su $USERNAME -c "streamlink --retry-open 3 --retry-streams 5 --retry-max 10 --hls-live-edge 25 --hls-live-restart --hls-segment-threads 8 --hls-segment-attempts 5 --hls-segment-timeout 30 --hls-playlist-reload-attempts 10 --hls-timeout 280 -o $RIP https://www.youtube.com/channel/$CHANNELID best" > $LOGGER &
  elif [ -n "$1" ]; then
    echo "$PROG[$$][$(date +%R)]: starting streamlink… Flags: $1" > $LOGGER
    nice -n -5 su $USERNAME -c "streamlink --retry-open 15 --retry-streams 30 --retry-max 20 --hls-live-edge 25 --hls-segment-threads 8 --hls-segment-attempts 5 --hls-segment-timeout 30 --hls-start-offset=-05:00 --hls-playlist-reload-attempts 20 --hls-timeout 280 -o $RIP https://www.youtube.com/channel/$CHANNELID best" > $LOGGER &
  fi  
  streamlinkpid=$!
  wait $streamlinkpid
  streamlinkret=$?
  rm -f $LOCK
}

# you have to adjust the path for where you put dlive.py
dliveStreamLink() {
  touch $LOCK
  echo "$PROG[$$][$(date +%R)]: starting streamlink with sideloaded dlive plugin…" > $LOGGER
  nice -n -5 su dave -c "streamlink --plugin-dirs /home/$USER/dlive-plugin --retry-open 3 --retry-streams 5 --retry-max 10 --hls-live-edge 25 --hls-live-restart --hls-segment-threads 5 --hls-segment-attempts 5 --hls-segment-timeout 30 --hls-playlist-reload-attempts 10 --hls-timeout 280 -o $RIP https://dlive.tv/$DLIVENAME best" > /dev/kmsg 2>&1 &
  dlivepid=$!
  wait $dlivepid
  dliveret=$?
  rm -f LOCK
}

main() 
{
  init  
  case `isLive` in
  0)
    echo "$PROG[$$][$(date +%R)]: Channel $CHANNELNAME is live! Streamlink is ripping to \"${RIP##/*/}\"" > $LOGGER    
    getTitle
    #checkSize &
    #checksizepid=$! 
    streamLink $1
    # stream ending is a read error for streamlink will return 1, wrong parameters 2, killed process (128+n)
    # SIGINT n=2 exit 130 -> usually triggered thru ^C (C-c) which is not possible in a script w/o stdin
    # still sometimes this does not behave standard compliant (the script tries to catch signals to itself and return 130)
    # SIGTERM n=15 exit 143 -> standard signal of the kill builtin
    # TODO: check why desktop streams always return 1 and on the phone encoder streamlink returns 0 
    # 0 (sometimes w phone encoder) most of the time 1 (OBS) for normal exit
    echo "$PROG[$$][$(date +%R)]: streamlink (su) exited with code $streamlinkret." > $LOGGER    
    # if there was nothing written don't process an empty file (as there was no error checking this surely led to some confusion)
    # we have nothing to put in a proper container nor to upload – also don't try again – stream must be offline
    if [ ! -e $RIP ]; then
      echo "$PROG[$$][$(date +%R)]: Nothing was written to disk, exiting…" > $LOGGER
      exit 1
    fi
    ffmpeg -hide_banner -nostdin -i $RIP -metadata comment="ripped by $USERNAME with $PROG" -c copy $OUT &
    ffmpegpid=$!
    # rescue attempt - sometimes the YouTube API is funny thats why here is an OR i know that isLive checks for a lock
    # or if the streamer ends in OBS but doesn't instantly end the encoder on the youtube website we might get a wrong response
    if [ ! -e $LOCK ]; then # [ `isLive` -eq 0 ] || 
      echo "$PROG[$$][$(date +%R)]: Trying again in case we might miss the last bit of the stream…" > $LOGGER
      $0 -recover &
    fi
    wait $ffmpegpid # wait for FFmpeg to finish otherwise depending on the system we might lose data etc... 
    if [ $? -ne 0 ]; then
      echo "FFmpeg failed…"
      exit 1
    fi
    #if ps -p $checksizepid > /dev/null 2>&1; then  
      #builtin kill $checksizepid
    #fi
    if [ ! -s $OUT ]; then # FILE exists and has a size greater than zero
      echo "$PROG[$$][$(date +%R)]: Outfile: \"${OUT##/*/}\" does not exist – keeping \"$RIP\" intact and exiting!" > $LOGGER
      exit 1
    fi
    #uploadToOL    
    rm -f $RIP $OLOG    
    echo "$PROG[$$][$(date +%R)]: Clean-up is done and file \"${OUT##/*/}\" is ready." > $LOGGER     
    wait
    ;;
  1)
    local mins=$(date +%M)
    
    if [ $mins -eq 00 ]; then
      echo "$PROG[$$][$(date +%R)]: Ripping the stream is in progress…" > $LOGGER
    exit 0
    ;;
  2)
    local hrs=$(date +%H)
    local mins=$(date +%M)
    if [ $hrs -lt 10 -o $hrs -gt 20 ] && [ $mins -eq 00 ]; then # adjust output to your cron settings
      echo "$PROG[$(date +%R)]: Channel $CHANNELNAME is not live!" > $LOGGER
    fi
    exit 1
    ;;
  3)
    echo "$PROG[$$][$(date +%R)]: Channel $CHANNELNAME is not live but the lockfile exists – removing…" > $LOGGER
    rm -f $LOCK
    exit 1
    ;;
  esac  
}
main "$@"
