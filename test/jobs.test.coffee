request = require 'supertest'

job = require process.cwd() + '/.app/controllers/jobs'
app = require process.cwd() + '/.app'


INITIAL_DATA = {
  filename: 'test.fdt',
  fdt_link: '/tmp/test.fdt',
  rank: 1,
  fda_link: ''
}

UPDATED_DATA = {
  filename: 'test.fdt',
  rank: 1,
  ETA: 0,
  status: 'done',
  fda_link: '/tmp/test.fda'
}

cleanJobsDB = (done) ->
  request(app)
  .get "/jobs/deleteall"
  .expect 200, (err, res) ->
    done()

describe 'job', ->
  before cleanJobsDB

  job_id = null
      
  it "should be created", (done) ->
    request(app)
      .post("/jobs/create")
      .set('Accept', 'application/json')
      .send(INITIAL_DATA)
      .expect 201, (err, res) ->
        res.body.should.include(INITIAL_DATA)
        res.body.should.have.property "_id"
        res.body["_id"].should.be.ok
        job_id = res.body["_id"]
        res.body["ETA"].should.equal 0
        res.body["status"].should.equal "scheduled"
        res.body["fdt_link"].should.equal INITIAL_DATA.fdt_link
        done()

  it "should be accessible by id", (done) ->
    request(app)
      .get("/jobs/get/#{job_id}")
      .set('Accept', 'application/json')
      .expect 200, (err, res) ->
        res.body.should.include(INITIAL_DATA)
        res.body.should.have.property "_id"
        res.body["_id"].should.be.eql job_id
        res.body["ETA"].should.equal 0
        res.body["status"].should.equal "scheduled"
        res.body["fdt_link"].should.equal INITIAL_DATA.fdt_link
        done()

  it "should be listed in list", (done) ->
    request(app)
      .get("/jobs")
      .set('Accept', 'application/json')
      .expect 200, (err, res) ->
        res.body.should.be.an.instanceof Array
        res.body.should.have.length 1
        res.body[0].should.include(INITIAL_DATA)
        done()

  it "should be updated", (done) ->
    request(app)
      .post("/jobs/update/#{job_id}")
      .set('Accept', 'application/json')
      .send(UPDATED_DATA)
      .expect 200, (err, res) ->
        res.body.should.include({"NumReplaced": 1})
        done()

  it "should be persisted after update", (done) ->
    request(app)
      .get("/jobs/get/#{job_id}")
      .set('Accept', 'application/json')
      .expect 200, (err, res) ->
        res.body.should.include(UPDATED_DATA)
        res.body.should.have.property "_id"
        res.body["_id"].should.be.eql job_id
        done()

  it "should be removed", (done) ->
    request(app)
      .del("/jobs/delete/#{job_id}")
      .set('Accept', 'application/json')
      .expect 200, (err, res) ->
        res.body.should.include({"NumRemoved": 1})
        done()

  it "should not be listed after remove", (done) ->
    request(app)
      .get("/jobs")
      .set('Accept', 'application/json')
      .expect 200, (err, res) ->
        res.body.should.be.an.instanceof Array
        res.body.should.have.length 0
        done()
        

  after cleanJobsDB