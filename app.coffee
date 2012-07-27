express = require 'express'
crypto = require 'crypto'
Log = require 'log'
log = new Log('debug')
Url = require 'url'

if process.env.REDISTOGO_URL
  rtg = Url.parse(process.env.REDISTOGO_URL)
  client = require('redis').createClient(rtg.port, rtg.hostname)
  client.auth(rtg.auth.split(":")[1])
else
  client = require('redis').createClient()

if process.env.NODE_ENV is 'production'
  port = process.env.PORT || 80
  host = "http://n37.co"
else
  port = 3000
  host = "http://localhost:#{port}"

app = express.createServer()

app.set 'view engine', 'jade'

app.use express.bodyParser()
app.use express.cookieParser()
app.use express.cookieSession secret: "alsaksjdl3i29jllfjaf"
app.use express.static('public/')

app.get '/', (req, res)->
  res.render 'index'

app.get '/register', (req, res, next)->
  algorithms = ['md5', 'sha1', 'sha256', 'sha512']
  url = normalizeUrl req.query.url

  if not url
    return next(new Error('No url'))

  if url.indexOf(host) isnt -1
    return next(new Error('Url is already shortened'))

  generate_code url, algorithms, (err, code)->
    return next(err) if err

    log.info "generate code #{code} for #{req.connection.remoteAddress}"
    req.session.code = code
    req.session.url = url
    res.redirect '/create'

app.get '/create', (req, res)->
  res.render 'create'
    code: req.session.code
    host: host

app.get /^\/([a-zA-Z0-9]{1,5})$/, (req, res, next)->
  code = req.params[0]
  client.get "url:#{code}", (err, reply)->
    return next(err) if err or not reply
    log.info "redirect user to #{reply}"
    client.hincrby 'hits', reply, 1
    res.redirect reply

app.use (err, req, res, next)->
  if process.env.NODE_ENV is 'production'
    res.render '404'
  else
    next(err)

log.info "start #{process.env.NODE_ENV} server with #{port}"
app.listen port

generate_code = (url, algorithms, callback)->
  alg = algorithms.shift()
  if not alg
    callback(new Error('all code is registered'))
  else
    code = hashUrl(url, alg)

    client.get "url:#{code}", (err, reply)->
      if not reply or reply == url
        client.set "url:#{code}", url, (err, reply)->
          client.expire "url:#{code}", 60 * 60 * 24 * 30
          callback(null, code)
      else generate_code(url, algorithms, callback)

hashUrl = (url, algorithm = 'md5')->
  symbals = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
  length = symbals.length
  digits = 5
  code = ""

  hash = crypto.createHash(algorithm)
    .update(url)
    .digest('hex')

  hash_number = parseInt(hash, 16) % Math.pow(length, digits + 1)

  while hash_number >= length
    n = hash_number % length
    code += symbals[n]
    hash_number = parseInt(hash_number / length)

  code

normalizeUrl = (url)->
  urlObject = Url.parse url
  if not urlObject.protocol?
    'http://' + urlObject.href
  else
    urlObject.href
