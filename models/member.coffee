Model = require "model"

module.exports = Member = (I={}, self=Model(I)) ->
  defaults I,
    text: ""
    x: 480
    y: 270

  self.attrReader "key"
  self.attrObservable "avatarURL", "x", "y", "text", "key", "roomId"

  img = new Image
  wordElement = document.createElement "words"

  update = (memberData) ->
    stats.increment "member.update"

    self.update memberData.val()

  table = db.ref("members")
  ref = table.child(self.key())

  connected = false
  connectingPromise = null

  self.extend
    img: ->
      img

    connect: ->
      return connectingPromise if connected
      connected = true

      return connectingPromise = new Promise (resolve, reject) ->
        ref.once "value", (snap) ->
          ref.on "value", update

          stats.increment "member.connect"
          console.log snap.val()
          update snap
          resolve self
        , reject

    disconnect: ->
      return self unless connected
      connected = false

      ref.off "value", update

      return self

    updatePosition: ({x, y}) ->
      self.x x
      self.y y

    update: (data) ->
      return unless data
      stats.increment "member.update"

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
        roomId: self.roomId()

      # TODO: Return promise for status?

    height: ->
      img.height | 0

  updateTextPosition = ->
    wordElement.style.left = "#{self.x()}px"
    wordElement.style.top = "#{self.y() - self.height()/2 - 30}px"

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
