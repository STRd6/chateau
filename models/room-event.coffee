Model = require "model"

# These events are immutable so their values never change
# We use them to construct the chat log
# who said what when
# actions, sounds, emotes
# can be used as commands in room based games too

module.exports = RoomEvent = (I={}, self=Model(I)) ->
  self.attrReader "key", "source", "type", "content"

  return self

identityMap = {}

RoomEvent.createFromSnap = (snap) ->
  {key} = snap

  return identityMap[key] if identityMap[key]

  data = snap.val()
  data.key = key

  identityMap[key] = RoomEvent data
