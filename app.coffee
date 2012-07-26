express = require 'express'
crypto = require 'crypto'
Log = require('log')
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
  url = normalizeUrl req.query.url

  return next() unless url

  code = hashUrl(url)

  client.set "url:#{code}", url, (err, reply)->
    log.info "generate code #{code}"
    req.session.code = code
    req.session.url = url
    res.redirect '/create'

app.get '/create', (req, res)->
  res.render 'create'
    code: req.session.code
    host: host

app.get /^\/([a-zA-Z0-9]{4,6})$/, (req, res, next)->
  code = req.params[0]
  client.get "url:#{code}", (err, reply)->
    return next(err) if err
    log.info "redirect user to #{reply}"
    client.hincrby 'hits', reply, 1
    res.redirect reply

log.info "start #{process.env.NODE_ENV} server with #{port}"
app.listen port

hashUrl = (url)->
  symbals = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
  length = symbals.length
  digits = 5
  code = ""

  hash = crypto.createHash('md5')
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
