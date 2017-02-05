Model = require "model"

Drawable = require "./drawable"

module.exports = Prop = (I={}, self=Model(I)) ->
  defaults I,
    x: 480
    y: 270

  self.include Drawable

  self.attrReader "key", "roomId"
  self.attrObservable "x", "y"

  update = (snap) ->
    self.update snap.val()

  table = db.ref("rooms/#{self.roomId()}/props")
  ref = table.child(self.key())

  self.extend
    connect: ->

    disconnect: ->
      ref.off "value", update

      return self

    updatePosition: ({x, y}) ->
      self.x x
      self.y y

    update: (data) ->
      return unless data
      stats.increment "props.update"

      Object.keys(data).forEach (key) ->
        self[key]? data[key]

      return self

    sync: ->
      ref.update
        x: self.x()
        y: self.y()

  ref.on "value", update

  return self

identityMap = {}

Prop.find = (key) ->
  # Identity map by keys
  identityMap[key] ?= Prop
    key: key
