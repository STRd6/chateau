Model = require "model"

module.exports = Member = (I={}, self=Model(I)) ->
  console.log "memb", I

  I.text ?= ""

  self.attrReader "key"
  self.attrObservable "avatarURL", "x", "y", "text", "key"

  img = new Image
  wordElement = document.createElement "words"

  update = (memberData) ->
    self.update memberData.val()

  table = db.ref("members")
  ref = table.child(self.key())

  connected = false

  self.extend
    img: ->
      img

    connect: ->
      return self if connected
      connected = true

      ref.on "value", update

      return self

    disconnect: ->
      return self unless connected
      connected = false

      ref.off "value", update

      return self

    updatePosition: ({x, y}) ->
      self.x x
      self.y y

    update: (data) ->
      Object.keys(data).forEach (key) ->
        self[key]? data[key]

      return self

    wordElement: ->
      wordElement

    sync: ->
      ref.update
        avatarURL: self.avatarURL()
        x: self.x()
        y: self.y()
        text: self.text()

      # TODO: Return promise for status?

  updateTextPosition = ->
    wordElement.style.left = "#{self.x()}px"
    wordElement.style.top = "#{self.y() - 50}px"

  self.avatarURL.observe (url) ->
    if url
      img.src = url

  self.text.observe (text) ->
    wordElement.textContent = text
    updateTextPosition()

  self.x.observe updateTextPosition
  self.y.observe updateTextPosition

  return self

identityMap = {}

Member.find = (id) ->
  # Identity map account ids
  identityMap[id] ?= Member
    key: id
