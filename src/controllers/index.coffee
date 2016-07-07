# Just renders index.jade
Datastore = require 'nedb'
serversDB = new Datastore { filename: './DB/servers.db', autoload: true }
jobsDB = new Datastore { filename: './DB/jobs.db', autoload: true }

exports.index = (req, res) ->
  serversDB.find {}, (err, servers) ->
    if err?
      res.send err
      res.statusCode = 500
    else
      jobsDB.find {}, (err, jobs) ->
        if err?
          res.send err
          res.statusCode = 500
        else
          List = {
            ServerList: servers,
            JobsList: jobs
          }
          res.render 'index', {List}
		

