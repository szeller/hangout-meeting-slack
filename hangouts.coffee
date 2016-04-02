nconf = require 'nconf'
cson = require 'cson'
_ = require 'underscore'
moment = require 'moment'
fs = require 'fs'
readline = require 'readline'

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
      console.log "please save this token: "
      console.dir token

      callback err, token 

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
authorize nconf.get('google'), (err, auth) ->
  return console.log err if err

  listEvents auth, (err, events) ->
    return console.log err if err
    return console.log 'No upcoming events found.' if !events.length

    console.log 'Upcoming 10 events:'

    for event in events 
      start = moment(event.start.dateTime || event.start.date).format 'MMMM Do YYYY, h:mm A' 
      console.log "title: #{event.summary}\nstart: #{start}\nhangout: #{event.hangoutLink}"
