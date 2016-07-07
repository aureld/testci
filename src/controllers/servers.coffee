
# Server model's CRUD controller.
os = require 'os'
request = require 'request-lite'
mathjs = require 'mathjs'
Datastore = require 'nedb'
serversDB = new Datastore { filename: './DB/servers.db', autoload: true }
math = mathjs()



module.exports =


#-------------------------------------------------------
#           CREATE ROUTES
#-------------------------------------------------------
#displays the form for creating a server
  add: (req, res) ->
    res.render 'servers/addsrv'

# Creates new server with data from `req.body`
  create: (req, res) ->
   
    if not (req.body.name or req.body.address)
      res.send 'no data'
    else
      doc = {
        name: req.body.name,
        address: req.body.address,
        status: 'Ok'
      }
      serversDB.insert doc, (err, server) ->
        if err?
          res.send err
          res.statusCode = 500
        else
          res.statusCode = 201
          if(/application\/json/.test(req.get('accept')))
            #if the client accepts JSON, we give it JSON
            res.send(server)
          else
            #otherwise it's a human, and we give html
            res.redirect '/servers'

#-------------------------------------------------------
#           READ ROUTES
#-------------------------------------------------------

# Lists all servers
  index: (req, res) ->
    serversDB.find {}, (err, servers) ->
      if err?
        res.send err
        res.statusCode = 500
      else
        if(/application\/json/.test(req.get('accept')))
          #if the client accepts JSON, we give it JSON
          res.send(servers)
        else
          #otherwise it's a human, and we give html
          res.render 'servers/index', {ServersList: servers}


     
  # Gets server by id
  get: (req, res) ->
    serversDB.findOne { _id: req.params.id },  (err, server) ->
      if err?
        res.send err
        res.statusCode = 500
      else
        #get some information first
        request 'http://' + server.address + ':3000' + '/servers/ping',
            (error, response, body) ->
              if(/application\/json/.test(req.get('accept')))
                if error?
                  res.statusCode = 500
                  res.send error
                else
                  srvinfo = {
                    dbinfo: server,
                    srvinfo: body
                  }
                  res.send srvinfo
              else #human
                if error?
                  res.statusCode = 500
                  res.render '500', {error: error}
                else
                  srvinfo = {
                    dbinfo: server,
                    srvinfo: JSON.parse body
                  }
                  res.render 'servers/srvinfo', {server: srvinfo}



  #Gets server status and health information
  ping: (req, res) ->
    #collects server through OS calls
    srvinfo = {
      hostname: os.hostname(),
      type: os.type(),
      release: os.release(),
      memtotal: math.floor(os.totalmem() / 1048576), #to get results in MB
      loadavg: os.loadavg(),
      cpus: os.cpus()
    }
    res.send(srvinfo)


#-------------------------------------------------------
#           UPDATE ROUTES
#-------------------------------------------------------

  #renders the update form
  modify: (req,res) ->
    serversDB.findOne { _id: req.params.id },  (err, server) ->
      if err?
        res.send err
        res.statusCode = 500
      else
        res.render 'servers/updatesrv', {server: server}

  # Updates server with data from `req.body`
  update: (req, res) ->
    if not (req.body.name or req.body.address)
      res.send 'no data'
    else
      doc = {
        name: req.body.name,
        address: req.body.address
      }
      serversDB.update {_id: req.params.id}, {$set: doc}, {},
        (err, NumReplaced) ->
          if err?
            res.send err
            res.statusCode = 500
          else
            if(/application\/json/.test(req.get('accept')))
              #if the client accepts JSON, we give it JSON
              res.send({NumReplaced})
              res.statusCode = 200
            else
              #otherwise it's a human, and we give html
              res.redirect '/servers'

  

#-------------------------------------------------------
#           DELETE ROUTES
#-------------------------------------------------------
  
  # Deletes server by id
  delete: (req, res) ->
    serversDB.remove { _id: req.params.id }, {}, (err, numRemoved) ->
      if err?
        res.send err
        res.statusCode = 500
      else
        res.redirect '/servers'

  # Deletes all servers
  deleteall: (req, res) ->
    serversDB.remove { }, {multi: true}, (err, numRemoved) ->
      if err?
        res.send err
        res.statusCode = 500
      else
        res.send numRemoved + " server(s) removed"

      
  