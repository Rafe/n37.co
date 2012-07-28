# N37 Url Shortener

### What is this?

This is a sample url shortener build on expressjs, redis, bootstrap and coffeescript. Can be easily deployed on heroku with Redistogo addon.

### Why n37?

Because all other meaningful 3 letter domain name is registered.

### Run local

First, clone the app, have [node.js](http://nodejs.org/) installed.

Install the dependency:

	npm install

Then, install and start the [Redis](http://redis.io/) instance

	redis-server
	
And run server

	make
	
### Deploy to heroku

For deploy to heroku, first you need to have the [heroku cli](https://devcenter.heroku.com/articles/heroku-command) installed.

Then create the app with cedar stack:

	heroku apps:create [NAME] -s cedar
	
Enable the [redistogo addon](https://addons.heroku.com/redistogo) with nano instance on heroku

	heroku addons:add redistogo:nano
	
Set the environment varibles on heroku:

	heroku config:set NODE_ENV=production HOST=[YOUR HOSTNAME]
	
deploy the app to heroku:

	git push heroku master
	
start or scale the server:

	heroku ps:scale web=1
	
### MORE

More details on implmentation and algorithm is on [this post](http://neethack.com/2012/07/announcing-n37-url-shortener/)

#### Copyright: MIT Licence
	
