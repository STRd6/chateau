Base = require "./base"
Drawable = require "./drawable"

module.exports = Base "members", (I={}, self=Model(I)) ->
  defaults I,
    text: ""
    x: 480
    y: 270

  self.include Drawable

  self.attrSync "x", "y", "text", "name", "roomId"

  wordElement = document.createElement "words"

  self.extend
    updatePosition: ({x, y}) ->
      self.x x
      self.y y

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

  updateTextPosition = ->
    if self.text()
      wordElement.style.left = "#{self.x()}px"
      wordElement.style.top = "#{self.y() - self.height()/2 - 30}px"
    else
      wordElement.style.left = "-100px"

  self.text.observe (text) ->
    wordElement.textContent = text
    updateTextPosition()

  self.x.observe updateTextPosition
  self.y.observe updateTextPosition
  self.imageURL.observe updateTextPosition

  return self
