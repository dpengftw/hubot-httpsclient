# Description:
#   Send a HTTP request to a pre-defined target
#
# Dependencies:
#   scoped-http-client
#   url
#   moment-timezone
#
# Configuration:
#   HUBOT_HTTPS_HREF - url of the endpoint to connect to
#   HUBOT_HTTPS_DATA - data payload
#   HUBOT_HTTPS_QUERY - query of the request
#   HUBOT_HTTPS_HEADERS - headers to add
#
# Commands:
#   hubot httpsget - get a HTTP request
#   hubot httpspost <unix date> <num of minutes> - post a HTTP request with given date and amount of time
#
HttpClient = require('scoped-http-client')
url = require('url')
moment = require('moment-timezone')

# gather environment variables
if process.env.HUBOT_HTTPS_HREF?
  url.href = process.env.HUBOT_HTTPS_HREF
if url.href?
  console.log "hubot-httpsclient href is defined as #{url.href}"
else
  console.log "hubot-httpsclient href is not defined"

if process.env.HUBOT_HTTPS_DATA?
  url.data = process.env.HUBOT_HTTPS_DATA
else
  url.data = {}

if process.env.HUBOT_HTTPS_QUERY?
  url.query = process.env.HUBOT_HTTPS_QUERY
else
  url.query = {}
  
if process.env.HUBOT_HTTPS_HEADERS?
  url.headers = process.env.HUBOT_HTTPS_HEADERS
else
  url.headers = '{"Content-Type": "application/json"}'
  


get = (url, query, cb) ->
  if typeof(query) is 'function'
    cb = query
    query = {}

  HttpClient.create(url)
    .query(query)
    .get() (err, res, body) ->
      if err?
        cb(err)
        return
      json = {}
      json.result = res
      json.body = body
      cb null, json

put = (url, headers, data, cb) ->

  HttpClient.create(url)
    .headers(JSON.parse(headers))
    .put(json) (err, res, body) ->
      if err?
        cb(err)
        return

      json = {}
      json.result = res
      json.body = body
      cb null, json

post = (url, headers, data, cb) ->

  HttpClient.create(url)
    .headers(JSON.parse(headers))
    .post(json) (err, res, body) ->
      if err?
        return cb(err)

      json = {}
      json.result = res
      json.body = body
      cb null, json


module.exports = (robot) ->

  robot.respond /httpsget/i, (res) ->
    get url.href, url.query, (err, json) ->
      if err?
        robot.emit 'error', err
        return

      if json?
        res.send "Status code: #{json.result.statusCode}"


  robot.respond /httpspost (\w{3}) (\w{3})\s+(\d+) ([\d\:]+) (\w{3}) (\d{4}) (\d+)$/i, (res) ->
    dayofweek = res.match[1]
    month = res.match[2]
    day = res.match[3]
    time = res.match[4]
    timezone = res.match[5]
    year = res.match[6]
    minutes = res.match[7]

    # parse the unix date and calc start and end times
    epoch = Date.parse month + " " + day + " " + time + " " + timezone + " " + year
    dateTime = new Date epoch
    startTime = moment(dateTime).format()
    endTime = moment(dateTime).add(minutes, 'minutes').format()

    # replace variables with calcuated values
    data = url.data.replace /#{startTime}/, startTime
    data = data.replace /#{endTime}/, endTime
    data = data.replace /#{timezone}/, timezone
  
    post url.href, url.headers, data, (err, json) ->
      if err?
        robot.emit 'error', err
        return

      if json?
        res.send "Status code: #{json.result.statusCode}"
        res.send "${res.body}"