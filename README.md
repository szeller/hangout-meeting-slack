# hangout-meeting-slack

This is a little script that I wrote to solve the problem that I wanted to easily get the hangout url
for my next meeting on my phone.  The default google calendar slack integration mostly works great but
for some reason doesn't directly expose the hangout url.  

## Setup

The first thing you need to do is create a new webhook in slack by going here https://my.slack.com/services/new/incoming-webhook/ 
You want to tie it to a channel where the noise will be appropriate like the Slackbot channel.

After that, you'll need to create an OAuth 2.0 google app to use to grab your google calendar data.  The
one gotcha is that you need to configure the app to not be a web app or similar configuration that
will require a valid redirect url.  

Once you've got those configuration parameters, you'll want to copy `example_config.cson` to `~/.hangouts_meeting_bot.cson` and
edit the appropriate values in the file.  

After you've done an `npm install`, you should be able to run `bin/hangout_meeting_bot` which will run you through the
setup steps to get a token for your account.  After you have finished all of the steps requested by the script, it will write the 
token information back to `~/.hangouts_meeting_bot.cson`

## Crontab

For the script to be useful, you'll want to run it at some interval via some tool like cron.  My crontab entries look like the following

```
0 7 * * * hangout_meeting_bot
*/5 * * * * hangout_meeting_bot +5m
```

This will send a summary of the day's events to slack at 7AM every morning.  Additionally, every 5 minutes it will send a slack message for
any meeting starting in the next 5 minutes.

