Model = require "model"

module.exports = Prop = (I={}, self=Model(I)) ->
  defaults I,
    x: 480
    y: 270

  self.attrReader "key", "roomId"
  self.attrObservable "imageURL", "x", "y"

  img = new Image

  update = (snap) ->
    stats.increment "prop.update"

    self.update snap.val()

  table = db.ref("rooms/#{self.roomId()}/props")
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
      return unless data
      stats.increment "prop.update"

      Object.keys(data).forEach (key) ->
        self[key]? data[key]

      return self

    sync: ->
      ref.update
        x: self.x()
        y: self.y()

    height: ->
      img.height | 0

  self.imageURL.observe (url) ->
    if url
      img.src = url

  return self

identityMap = {}

Prop.find = (key) ->
  # Identity map by keys
  identityMap[key] ?= Prop
    key: key
