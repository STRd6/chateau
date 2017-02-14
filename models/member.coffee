Base = require "./base"
Drawable = require "./drawable"
Positionable = require "./positionable"

module.exports = Base "members", (I={}, self=Model(I)) ->
  defaults I,
    name: ""
    roomId: null
    text: ""
    x: 480
    y: 270

  self.include Drawable, Positionable

  self.attrSync "text", "name", "roomId"

  wordElement = document.createElement "words"

  self.extend
    dataFolder: ->
      firebase.storage().ref("users/#{self.key()}/data")

    wordElement: ->
      wordElement

    updatePresence: (status) ->
      presenceRef = db.ref("presence/#{self.key()}")

      presenceRef.child("online").onDisconnect().set false
      presenceRef.child("lastSeen").onDisconnect().set db.TIMESTAMP
      presenceRef.update
        online: true
        lastSeen: db.TIMESTAMP
        status: status

    updateProfilePhoto: (url) ->
      presenceRef = db.ref("presence/#{self.key()}")

      presenceRef.child("profilePhotoURL").set url

  updateTextPosition = ->
    if self.text()
      wordElement.style.left = "#{self.x()}px"
      wordElement.style.top = "#{self.y() - self.height()/2 - 30}px"
    else
      wordElement.style.left = "-100%"

  self.text.observe (text) ->
    wordElement.textContent = text
    updateTextPosition()

  self.x.observe updateTextPosition
  self.y.observe updateTextPosition
  self.imageURL.observe updateTextPosition

  return self
