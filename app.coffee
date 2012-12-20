express = require 'express'
crypto = require 'crypto'
Log = require 'log'
log = new Log('debug')
Url = require 'url'

TRACKER_KEY = process.env.TRACKER_KEY
EXPIRE_TIME = 60 * 60 * 24 * 30 * 12 # 1 year

if process.env.REDISTOGO_URL
  redisToGo = Url.parse(process.env.REDISTOGO_URL)
  client = require('redis').createClient(redisToGo.port, redisToGo.hostname)
  client.auth(redisToGo.auth.split(":")[1])
else
  client = require('redis').createClient()

if process.env.NODE_ENV is 'production'
  port = process.env.PORT || 80
  host = process.env.HOST || "http://n37.co"
else
  port = 3000
  host = "http://localhost:#{port}"

app = express.createServer()

app.set 'view engine', 'jade'

app.use express.bodyParser()
app.use express.cookieParser()
app.use express.cookieSession
  secret: process.env.SECRET || "lASDWsjldcjxl8o3jfhsjdfksdjfhksasd@asd293"
app.use express.static('public/')

app.locals.host = host
app.locals.TRACKER_KEY = TRACKER_KEY

app.get '/', (req, res)->
  res.render 'index'

app.get '/register', (req, res, next)->
  algorithms = getAlgorithms()
  digits = 5
  url = normalizeUrl req.query.url

  if not url
    return next(new Error('No url'))

  if url.indexOf(host) isnt -1
    return next(new Error('Url is already shortened'))

  #http://mathiasbynens.be/demo/url-regex from @stephenhay
  unless /^(https?):\/\/[^\s\/$.?#]+\.[^\s]*$/gi.test(url)
    return next(new Error('This is not a valid url'))

  generateCode url, algorithms, digits, (err, code)->
    return next(err) if err
    client.expire "url:#{code}", EXPIRE_TIME
    log.info "generate code #{code} for #{req.connection.remoteAddress}"
    req.session.code = code
    res.redirect '/create'

app.get '/create', (req, res)->
  res.render 'create'
    code: req.session.code

app.get /^\/([a-zA-Z0-9]{1,5})$/, (req, res, next)->
  code = req.params[0]
  client.get "url:#{code}", (err, reply)->
    return next(err) if err or not reply
    client.expire "url:#{code}", EXPIRE_TIME
    client.hincrby 'hits', reply, 1
    log.info "redirect user to #{reply}"
    res.redirect reply

app.use (err, req, res, next)->
  if process.env.NODE_ENV is 'production'
    res.render '404', { error: err }
  else
    next(err)

log.info "start #{process.env.NODE_ENV} server with #{port}"
app.listen port

getAlgorithms = -> ['md5', 'sha1', 'sha256', 'sha512']

generateCode = (url, algorithms, digits, callback)->
  #increase code digits if all codes are registered
  if algorithms.length is 0
    algorithms = getAlgorithms()
    digits += 1

  algorithm = algorithms.shift()

  code = hashUrl(url, digits, algorithm)

  client.get "url:#{code}", (err, reply)->
    if not reply or reply == url
      client.set "url:#{code}", url, (err, reply)->
        callback(null, code)
    else generateCode(url, algorithms, digits, callback)

exports.hashUrl = hashUrl = (url, digits = 5, algorithm = 'md5')->
  symbols = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
  length = symbols.length
  code = ""

  hash = crypto.createHash(algorithm)
    .update(url)
    .digest('hex')

  hash_number = parseInt(hash, 16) % Math.pow(length, digits + 1)

  while hash_number >= length
    n = hash_number % length
    code += symbols[n]
    hash_number = parseInt(hash_number / length)

  code

normalizeUrl = (url)->
  urlObject = Url.parse url
  if not urlObject.protocol?
    'http://' + urlObject.href
  else
    urlObject.href
