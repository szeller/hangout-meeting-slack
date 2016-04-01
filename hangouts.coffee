nconf = require 'nconf'
fs = require 'fs'
readline = require 'readline'

# S = require 'string' 
_ = require 'underscore'
cson = require 'cson'

google = require 'googleapis'
googleAuth = require 'google-auth-library'
drive = google.drive 'v2'
calendar = google.calendar 'v3'

nconf.argv().env()
nconf.use 'file',
  file: 'config.cson'
  format:
    stringify : (s) -> cson.stringify s
    parse : (s) -> cson.parse s

googleConf = nconf.get 'google'
SCOPES = googleConf.scopes

# Create an OAuth2 client with the given credentials, and then execute the given callback function.
authorize = ({clientId, clientSecret, redirectUri}, token, callback) ->
  auth = new googleAuth
  oauth2Client = new auth.OAuth2 clientId, clientSecret, redirectUri

  return getNewToken oauth2Client, callback if !token

  oauth2Client.credentials = token
  callback null, oauth2Client


# Get and store new token after prompting for user authorization, and then
# execute the given callback with the authorized OAuth2 client.
getNewToken = (oauth2Client, callback) ->
  authUrl = oauth2Client.generateAuthUrl
    access_type: 'offline'
    scope: SCOPES

  console.log "Authorize this app by visiting this url: #{authUrl}"

  rl = readline.createInterface
    input: process.stdin,
    output: process.stdout

  rl.question 'Enter the code from that page here: ', (code) ->
    rl.close()

    oauth2Client.getToken code, (err, token) ->
      oauth2Client.credentials = token
      console.log "token is :"
      console.dir token

      callback err, oauth2Client 

# Lists the next 10 events on the user's primary calendar.
listEvents = (auth, callback) ->
  calendar.events.list 
    auth: auth
    calendarId: 'primary'
    timeMin: (new Date()).toISOString()
    maxResults: 10
    singleEvents: true
    orderBy: 'startTime'
  , (err, response) ->
    return callback err if err
    callback null, response.items


# Authorize a client with the loaded credentials, then call the Google Calendar API.
authorize googleConf.credentials, googleConf.token, (err, auth) ->
  return console.log err if err

  listEvents auth, (err, events) ->
    return console.log err if err
    return console.log 'No upcoming events found.' if !events.length

    console.log 'Upcoming 10 events:'

    for event in events 
      console.dir event
      # start = event.start.dateTime || event.start.date
      # console.log "#{start} - #{event.summary}"

