Model = require "model"

module.exports = RoomEvent = (I={}, self=Model(I)) ->
  defaults I,
    x: 480
    y: 270

  self.attrReader "key", "creatorKey", "roomKey"
  self.attrObservable "type", "content"

  img = new Image

  update = (snap) ->
    self.update snap.val()

  table = db.ref("room-events/#{self.roomKey()}")
  ref = table.child(self.key())

  self.extend
    update: (data) ->
      return unless data
      stats.increment "room-event.update"

      Object.keys(data).forEach (key) ->
        self[key]? data[key]

      return self

  return self

identityMap = {}

RoomEvent.find = (roomKey, key) ->
  # Identity map by keys
  identityMap[key] ?= RoomEvent
    key: key
    roomKey: roomKey
