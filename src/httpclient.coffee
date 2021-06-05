# Description:
#   Send a HTTP request to a pre-defined target
#
# Dependencies:
#   scoped-http-client
#   url
#   moment-timezone
#
# Configuration:
#   HUBOT_HTTPS_URLS - json configuration of urls; refer to sample httpclient.json
#
# Commands:
#   hubot httpsget <alias> - get a HTTP request
#   hubot httpspost <alias> <unix date> <num of minutes> - post a HTTP request with given date and amount of time
#
HttpClient = require('scoped-http-client')
url = require('url')
moment = require('moment-timezone')
nconf = require('nconf')

nconf.argv()
   .env()
   .file({ file: 'httpsclient.json' })

urls = nconf.get('HUBOT_HTTPS_URLS')

get = (url, query, cb) ->
  if typeof(query) is 'function'
    cb = query
    query = {}

  if query?
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
  else
    HttpClient.create(url)
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
    .put(data) (err, res, body) ->
      if err?
        cb(err)
        return

      json = {}
      json.result = res
      json.body = body
      cb null, json

post = (url, headers, data, cb) ->
  HttpClient.create(url)
    .headers(headers)
    .post(data) (err, res, body) ->
      if err?
        return cb(err)

      json = {}
      json.result = res
      json.body = body
      cb null, json


module.exports = (robot) ->

  robot.respond /httpsget (\w+)/i, (res) ->
    alias = res.match[1]
    url = urls[alias]

    get url.href, url.query, (err, json) ->
      if err?
        robot.emit 'error', err
        return

      if json?
        res.send "Status code: #{json.result.statusCode}"

  robot.respond /httpspost (\w+)$/i, (res) ->
    alias = res.match[1]

    url = urls[alias]

    post url.href, url.headers, url.data, (err, json) ->
      if err?
        robot.emit 'error', err
        return

      if json?
        res.send "Status code: #{json.result.statusCode}"

      if json.body?
        res.send "#{json.body}"
        
  robot.respond /httpspostwithdate (\w+) (\w{3}) (\w{3})\s+(\d+) ([\d\:]+) (\w{3}) (\d{4}) (\d+)$/i, (res) ->
    alias = res.match[1]
    dayofweek = res.match[2]
    month = res.match[3]
    day = res.match[4]
    time = res.match[5]
    timezone = res.match[6]
    year = res.match[7]
    minutes = res.match[8]

    # parse the unix date and calc start and end times
    epoch = Date.parse month + " " + day + " " + time + " " + timezone + " " + year
    dateTime = new Date epoch
    startTime = moment(dateTime).format()
    endTime = moment(dateTime).add(minutes, 'minutes').format()

    url = urls[alias]
    # replace variables with calcuated values
    data = JSON.stringify(url.data)
    data = data.replace /#{startTime}/, startTime
    data = data.replace /#{endTime}/, endTime
    data = data.replace /#{timezone}/, timezone

    post url.href, url.headers, data, (err, json) ->
      if err?
        robot.emit 'error', err
        return

      if json?
        res.send "Status code: #{json.result.statusCode}"

      if json.body?
        res.send "#{json.body}"
