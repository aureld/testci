Datastore = require 'nedb'

Module.exports =
    jobsDB: () ->
      new Datastore { filename: './DB/jobs.db', autoload: true }