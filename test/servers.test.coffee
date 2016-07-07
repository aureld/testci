request = require 'supertest'

server = require process.cwd() + '/.app/controllers/servers'
app = require process.cwd() + '/.app'


INITIAL_DATA = {
  name: 'test server',
  address: '127.0.0.1'
}

UPDATED_DATA = {
  name: 'other server',
  address: '127.0.0.1'
}

cleanServersDB = (done) ->
  request(app)
    .get "/servers/deleteall"
    done()

describe 'server', ->
  before cleanServersDB
  
  server_id = null
      
  it "should be created", (done) ->
    request(app)
      .post("/servers/create")
      .set('Accept', 'application/json')
      .send(INITIAL_DATA)
      .expect 201, (err, res) ->
        res.body.should.include(INITIAL_DATA)
        res.body.should.have.property "_id"
        res.body["_id"].should.be.ok
        server_id = res.body["_id"]
        done()
        
  it "should be accessible by id", (done) ->
    request(app)
      .get("/servers/get/#{server_id}")
      .set('Accept', 'application/json')
      .expect 200, (err, res) ->
        res.body.dbinfo.should.include(INITIAL_DATA)
        res.body.dbinfo.should.have.property "_id"
        res.body.dbinfo["_id"].should.be.eql server_id
        done()
        
  it "should be listed in list", (done) ->
    request(app)
      .get("/servers")
      .set('Accept', 'application/json')
      .expect 200, (err, res) ->
        res.body.should.be.an.instanceof Array
        res.body.should.have.length 1
        res.body[0].should.include(INITIAL_DATA)
        done()
    
  it "should be updated", (done) ->
    request(app)
      .post("/servers/update/#{server_id}")
      .set('Accept', 'application/json')
      .send(UPDATED_DATA)
      .expect 200, (err, res) ->
        res.body.should.include({"NumReplaced": 1})
        done()
        
  it "should be persisted after update", (done) ->
    request(app)
      .get("/servers/get/#{server_id}")
      .set('Accept', 'application/json')
      .expect 200, (err, res) ->
        res.body.dbinfo.should.include(UPDATED_DATA)
        res.body.dbinfo.should.have.property "_id"
        res.body.dbinfo["_id"].should.be.eql server_id
        done()

  it "should display health information", (done) ->
    request(app)
      .get("/servers/get/#{server_id}")
      .set('Accept', 'application/json')
      .expect 200, (err, res) ->
        res.body.should.have.property 'srvinfo'
        done()

  it "should be removed", (done) ->
    request(app)
      .del("/servers/delete/#{server_id}")
      .expect 200, (err, res) ->
        done()
    
  it "should not be listed after remove", (done) ->
    request(app)
      .get("/servers")
      .set('Accept', 'application/json')
      .expect 200, (err, res) ->
        res.body.should.be.an.instanceof Array
        res.body.should.have.length 0
        done()
        

  after cleanServersDB
      