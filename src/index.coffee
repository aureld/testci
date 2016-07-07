express = require 'express'
assets = require 'connect-assets'
bodyParser = require 'body-parser'
multer = require 'multer'


#### Basic application initialization
# Create app instance.
app = express()

# Define Port
app.port = process.env.PORT or process.env.VMC_APP_PORT or 3000


#Config module exports has `setEnvironment` function that sets app
#settings depending on environment.
config = require "./config"
#app.configure 'production', 'development', 'testing', ->
config.setEnvironment app.settings.env


#### View initialization
# Add Connect Assets.
app.use assets()

# Set View Engine.
app.set 'view engine', 'jade'

# MiddleWare
app.use bodyParser()
app.use multer { dest: './public/uploads', rename:
  (fieldname, filename) -> return filename.replace(/\W+/g, '-').toLowerCase() }

# Set the public folder as static assets.
app.use express.static(process.cwd() + '/public')


#### Finalization
# Initialize routes
routes = require './routes'
routes(app)


# Export application object
module.exports = app

