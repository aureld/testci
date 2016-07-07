# Jobs model's CRUD controller.
#request = require 'request-lite'

#jobsModel = require '../models/jobsModel'

#general configuration
config = require "../config"

#Database
Datastore = require 'nedb'
jobsDB = new Datastore { filename: './DB/jobs.db', autoload: true }

#execution of system commands
fs = require 'fs'
exec = require('child_process').exec
http = require 'http'

#events engine
EventEmitter = new require('events').EventEmitter
ev = new EventEmitter()

#run a simulation on the rank 1 scheduled job
ev.on 'Simulate', () ->
  jobsDB.findOne { rank: 1, status: 'scheduled' },  (err, job) ->
    if err?
      console.log 'Simulation file not found'
    else 
      console.log('Simulation started!')
      jobsDB.update {_id: job._id}, {$set: {status: 'running'}}, {}, (err, NumReplaced) ->
        if err?
          console.log 'status update error'
        else
          strPath = config.FDTDCTLPATH + ' -f ' + process.cwd() + '\\public\\uploads\\' + job.filename
          console.log strPath
          exec strPath


#poll the DB for empty running queue and trigger a simulation
ev.on 'PollDB', () ->
  jobsDB.count {status: 'running'}, (err, count) ->
    if err?
      console.log err
      return
    else
      if count != 0
        console.log 'Simulation is running...'
        return
      else
        console.log 'Running a new simulation...'
        ev.emit('Simulate')


module.exports =

#-------------------------------------------------------
#           CREATE ROUTES
#-------------------------------------------------------
#displays the form for creating a job
add: (req, res) ->
  res.render 'jobs/addjob'

  # Creates new job with data from `req.body`
create: (req, res) ->
  if not (req.body.filename)
    res.send 'no data'
  else
    #first we count the number of scheduled jobs
    jobsDB.count {status: 'scheduled'}, (err, count) ->
      if err?
        res.send err
        res.statusCode = 500
      else
        #we create a new document and increment the rank counter
        doc = {
          filename: 	req.body.filename,
          rank:		count+1,
          fda_link:	'',
          status:		'scheduled',
          ETA:		0
        }
        jobsDB.insert doc, (err, job) ->
          if err?
            res.send err
            res.statusCode = 500
          else
            res.statusCode = 201
            #emit event for polling the DB for empty running queue
            ev.emit('PollDB')

            if(/application\/json/.test(req.get('accept')))
              res.send(job)
            else
              res.redirect '/jobs'
          
#-------------------------------------------------------
#           READ ROUTES
#-------------------------------------------------------


# Gets job by id
get: (req, res) ->
  jobsDB.findOne { _id: req.params.id },  (err, job) ->
    if err?
      res.send err
      res.statusCode = 500
    else
      res.send job
        

# Lists all jobs
index: (req, res) ->
  jobsDB.find {}, (err, jobs) ->
    if err?
      res.send err
      res.statusCode = 500
    else
      if(/application\/json/.test(req.get('accept')))
        #if the client accepts JSON, we give it JSON
        res.send(jobs)
      else
        #otherwise it's a human, and we give html
        res.render 'jobs/index', {JobsList: jobs}


#-------------------------------------------------------
#           UPDATE ROUTES
#-------------------------------------------------------


# Updates server with data from `req.body`
update: (req, res) ->
  if not (req.body.filename or req.body.fdt_link)
    res.send 'no data'
  else
    doc = {
      filename:			req.body.filename,
      rank:					req.body.rank,
      fdt_link:			req.body.fdt_link,
      fda_link:			req.body.fda_link,
      status:				req.body.status,
      ETA:					req.body.ETA
      }
    jobsDB.update {_id: req.params.id}, {$set: doc}, {}, (err, NumReplaced) ->
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
          res.redirect '/jobs'


#-------------------------------------------------------
#           DELETE ROUTES
#-------------------------------------------------------


# Deletes server by id
delete: (req, res) ->
  jobsDB.remove { _id: req.params.id }, {}, (err, NumRemoved) ->
    if err?
      res.send err
      res.statusCode = 500
    else
      if(/application\/json/.test(req.get('accept')))
        res.send {NumRemoved}
      else
        res.redirect '/jobs'

# Deletes all jobs
deleteall: (req, res) ->
  jobsDB.remove { }, {multi: true}, (err, numRemoved) ->
    if err?
      res.send err
      res.statusCode = 500
    else
      res.send numRemoved + " jobs(s) removed"