nconf = require 'nconf'
cson = require 'cson'
moment = require 'moment'
fs = require 'fs'
readline = require 'readline'
request = require 'request'
momentParser = require('moment-parser').parseMoment

google = require 'googleapis'
googleAuth = require 'google-auth-library'
drive = google.drive 'v2'
calendar = google.calendar 'v3'

nconf.argv().env()
nconf.use 'file',
  file: "#{process.env.HOME}/.hangouts_meeting_bot.cson"
  format:
    stringify : (s) -> cson.createCSONString s, indent: '  '
    parse : (s) -> cson.parse s

oauth2Client = ({clientId, clientSecret, redirectUri}) ->
  auth = new googleAuth
  new auth.OAuth2 clientId, clientSecret, redirectUri

# Create an OAuth2 client with the given credentials, and then execute the given callback function.
authorize = ({credentials, token, scopes}, callback) ->
  client = oauth2Client credentials

  getTokenIfNecessary client, scopes, token, (err, token) ->
    client.credentials = token
    callback null, client

# Get and store new token after prompting for user authorization, and then
# execute the given callback with the authorized OAuth2 client.
getTokenIfNecessary = (client, scopes, token, callback) ->
  return callback null, token if token

  authUrl = client.generateAuthUrl
    access_type: 'offline'
    scope: scopes

  console.log "Authorize this app by visiting this url: \n#{authUrl}"

  rl = readline.createInterface
    input: process.stdin,
    output: process.stdout

  rl.question 'Enter the code from that page here: ', (code) ->
    rl.close()

    client.getToken code, (err, token) ->

      # save the token back to the config file before passing it on
      nconf.set 'google:token', token
      nconf.save (err) ->
        callback err, token 

# Lists the next 10 events on the user's primary calendar.
listEvents = (auth, callback) ->
  calendar.events.list 
    auth: auth
    calendarId: 'primary'
    timeMin: moment().toISOString()
    timeMax: computeEndDate().toISOString()
    maxResults: 25
    singleEvents: true
    orderBy: 'startTime'
  , (err, response) ->
    return callback err if err
    callback null, response.items

computeEndDate = () ->
  endString = nconf.stores.argv.store._?[0]
  if endString then momentParser endString else moment().endOf 'day'

# Authorize a client with the loaded credentials, then call the Google Calendar API.
authorize nconf.get('google'), (err, auth) ->
  return console.log err if err

  listEvents auth, (err, events) ->
    return console.log err if err
    return console.log 'No upcoming events found.' if !events.length

    # for event in events 
    #   start = moment(event.start.dateTime || event.start.date).format 'h:mm A' 
    #   console.log "Hangout - #{event.summary} - #{start}"

    slackMessage = 
      text: 'Here\'s your daily hangout meeting list'
      attachments: for event in events 
        start = moment(event.start.dateTime || event.start.date).format 'h:mm A' 

        title: "Hangout - #{event.summary}"
        title_link: event.hangoutLink
        text: start

    request 
      method: 'POST'
      url: nconf.get('slack:webhook')
      json: true
      body: slackMessage
    , (err, resp, body) ->
      console.log err if err
      console.log 'Done!'
