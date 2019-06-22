# vodlink
Get the VODs of your favorite streamers!
You work or go to school and don't got time to watch —
use vodlink to watch the streams when you have the time on your hands.
Not even a copyright claim will hurt you – as the data is on your drive.
POSIX compliant shell script - which should be run as an hourly cronjob!
Uncomment the features you want to use after filling in the necessary variables.
*(e.g.: `sudo ln -s /home/rick/Projects/vodlink.sh /etc/cron.hourly/vodlink` –
also check that your crontab has its PATH set `PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin`) so you don't have to enter absolute pathnames for every program you run)*
Also you could add the file to your crontab (needs sudo) or systems crontab.
At the moment aimed at Debian based distros, but should also run on Mac OS X and Cygwin. (=


### Dependencies
- `lwp-request (libwww-perl)` *(for the `GET` utility)*
- `streamlink 1.1.1` *(can be installed with `pip3` or `apt`)*
- `FFmpeg`
- `Google API key for YouTube Data API v3`

### Getting your own API key
https://support.google.com/googleapi/answer/6158862?hl=en

#### If you want auto upload to OpenLoad
- `OpenLoad account`
- `cURL`
- functions: `uploadToOL` and `checkSize` *(because OpenLoad has a 10GB filesize cap)*
#### If you want the discord auto update bot to work
- `a discord server/guild with a channel where that user has write permission`
- `Python 3.6+`
- `discord.py >= 1.0` *(can be installed with `pip3`)*
- functions: `updateVODChannel`


To get your token instead of logging in the bot with email and username *(which is deprecated)* press `Ctrl+Shift+I` in Discord
which brings up the `Inspector` – in the Network tab filter for `/api` and under `Request Headers` there is a field called `authorization:` – the following string is your discord token. *(not the one in `Request Payload`)* It will change over time **but a token stays valid except the API version of Discord changes (I am still using my first token** so if you want to make sure and not have to change the code **ever** you can use the deprecated method and call `client.run(email, password)` with your Discord login credentials.
To get the `ID` of the channel you want to update *(funny to me – the server/guild ID is not necessary in any of these calls)* enable **developer mode** in the Discord settings under **Appearance** – right-click on the channel and select **Copy ID** 
***OR*** *you don't self bot your account but [create a legit discord bot](https://discordapp.com/developers/applications/) then you will also get a token to connect – you would call `client.run(token, bot=True)` tho.*

#### Donations
If you want to motivate me **or** got a special request ***(regarding this project or in general)*** – consider [**donating**](https://www.streamlabs.com/omen235)!
Should there be enough donations to move away from OpenLoad I will 100% reinvest part of the money to host the files **ad-free** and without a **transcode (lowering the bitrate)** happening after the files have been on the OpenLoad servers for some time. Should your request have something to do with this project open a new [**issue**](https://github.com/omen23/vodlink/issues) — if it is about *another project* or you *need help* somewhere just send me an [**email**](mailto:david.schuster@kdemail.net).
##### List of Donators: *(every Donator will get an entry in this list)*
- Bolton 
- Jakari
- BASED_B3TA
- Alex M
- VideoJunkie
- Sherwin
- Halfsharkalligatorhalfman
- Soupnastie

*Should you be a streamer and want me to set this up for your streams/VODs send me an email and I am sure we can work something out!*

#### changelog:
**22.06.2019:**
- tweaked polling interval

**17.06.2019:**
- removed `logger` as dependency because it is a sys-util on Mac OS X
- changed to `LOGGER=/dev/null` on Mac OS X – `logger` will take care of logging `stdout` and `stderr` to the syslog in "real-time"

**16.06.2019:**
- did not update to the latest `streamlink-dev` version, because `1.1.1` is stable and provides what we need
- tweaked streamlink parameterizing for longer DCs (up to 10 minutes) 
- increased number of threads in the threadpool

**02.06.2019:**
- logging interface rewrite for macosx and linux compatibility - ask prismane (=

**29.05.2019:**
- added check if the `OUTFILE.mp4` exists and is larger than 0 bytes, if not we keep the `RIP.m2ts` file intact

**18.05.2019:**
- had to delete entire GitHub repo because a commit exposed sensitive data
- v.0.5.2
- updated to `Python 3.7.3`
- updated `discord.py` bindings to `1.1.1`
- rewrote Discord notification code

**01.05.2019:**
- v.0.5.1
- added `dliveStreamLink` function with support to sideload the dlive.tv plugin
- I have yet to figure out how to change the control flow to support dlive streams as dlive.tv has no API like YouTube

**14.04.2019:**
- v.0.5
- updated to `streamlink v.1.1.1`

**13.04.2019:**
- made some tweaks in `checkSize()` so the streamlink process really gets killed instantly
- updated to `streamlink v.1.1.0`

**08.04.2019:**
- v.0.4.6 
- exchange `-f` with `-e` in `if` clauses
- optimize `streamlink` paramaterization – so no more short, intermediate VODs get lost

**29.03.2019:**
- v.0.4.5 
- check for flags optimized

**26.03.2019:**
- v.0.4.4
- send shorter URLs to the discord update bot (without the filename)

**25.03.2019:**
- v.0.4.3.1 
- timestamps in ISO-8601 with dot as delimiter

**23.03.2019:**
- found a trick that prevents OpenLoad's file deletion algorithm (=

**17.03.2019:**
- tweaked streamlink parameterization
- hoping for more donos as OpenLoad starts deleting VODs

**04.03.2019:**
- v.0.4.3 STABLE
- put normal and recovery streamlink invocation in one function – reduced code duplication alot

**14.02.2019:**
- add unique upload log name

**09.02.2019:**
- stopped the script from trying to recover/recurse when the YouTube API still reports live but nothing gets written to disk   (the stream is already offline) 

**06.02.2019:**
- fixed recovery streamlink invocation offset time parameterizing
- tweaked streamlink parameterizing (max. timeout and rewind)
- added `builtin` command to `kill ...`

**04.02.2019:**
- v.0.4.2 STABLE
- rename repository to `vodlink` because it is a software framework now basically and not only a bash script and will         probably grow even more.
- use `/bin/bash` as interpreter — everything is still POSIX compliant and done with `sed` and friends instead of `bashisms`
- `streamlink` updated to version 1.0.0 which improved overall stability
- implemented everything via PIDs `kill` and `wait ...` – everything is now contained and IPC works without `pgrep` etc.
- wrapper script gone since a few minor versions bumps – everything implemented as (async) functions now
- it is now possible to run `streamlink` and not interfere with a running instance and I just updated the lockfile code so     it is possible to run `vodlink` for multiple streamers.
- you will need multiple installations tho

##### © 2018-2019 oMeN23

