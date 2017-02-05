{Bindable} = require "ui"
Model = require "model"

Drawable = require "./drawable"
Member = require "./member"
Prop = require "./prop"
RoomEvent = require "./room-event"

module.exports = Room = (I={}, self=Model(I)) ->
  stats.increment "room.initialize"

  defaults I,
    members: []
    events: []
    props: []

  self.attrReader "key"
  self.include Bindable, Drawable

  self.attrObservable "name"
  self.attrModels "members", Member
  self.attrModels "props", Prop
  self.attrModels "events",  RoomEvent

  table = db.ref("rooms")
  ref = table.child(self.key())

  dataRef = db.ref("room-data/#{self.key()}")

  eventsRef = dataRef.child("events")
  membershipsRef = dataRef.child("memberships")
  propsRef = dataRef.child("props")

  subscribeToProp = (snap) ->
    stats.increment "room.subscribe-prop"

    {key} = snap
    value = snap.val()

    prop = Prop.find key
    prop.update(value)

    unless self.propByKey(key)
      self.props.push prop

  unsubscribeFromProp = ({key}) ->
    stats.increment "room.unsubscribe-prop"

    prop = self.propByKey(key)

    if prop
      self.props.remove prop
      # prop.disconnect()

  subscribeToMember = ({key}) ->
    stats.increment "room.subscribe-member"

    member = Member.find key
    member.connect()

    unless self.memberByKey(key)
      self.members.push member

  unsubscribeFromMember = ({key}) ->
    stats.increment "room.unsubscribe-member"

    member = self.memberByKey(key)

    if member
      self.members.remove member
      # member.disconnect()

  self.extend
    addProp: ({imageURL}) ->
      propsRef.push
        x: (Math.random() * 960)|0
        y: (Math.random() * 540)|0
        imageURL: imageURL

    join: (accountId) ->
      # Auto-leave on disconnect
      membershipsRef.child(accountId).onDisconnect().remove()
      # Join
      membershipsRef.child(accountId).set true

    leave: (accountId) ->
      membershipsRef.child(accountId).remove()

    clearAllProps: ->
      ref.child("props").remove()

    update: (data) ->
      return unless data
      stats.increment "room.update"

      Object.keys(data).forEach (key) ->
        self[key]? data[key]

      return self

    addRoomEvent: (data) ->
      eventsRef.push data

    memberByKey: (key) ->
      [member] = self.members.filter (member) ->
        member.key() is key

      return member

    propByKey: (key) ->
      [prop] = self.props.filter (prop) ->
        prop.key() is key

      return prop

    numberOfCurrentOccupants: ->
      self.members.length

    sync: ->
      ref.update
        imageURL: self.imageURL()
        name: self.name()

  update = (snap) ->
    data = snap.val()

    # Temporary: Remove legacy data
    delete data.props
    delete data.memberships

    # Rename obsolete background
    data.imageURL = data.backgroundURL

    self.update data

  # Keep room data up to date
  ref.on "value", update

  # Listen for all members, props, events
  membershipsRef.on "child_added", subscribeToMember
  membershipsRef.on "child_removed", unsubscribeFromMember

  propsRef.on "child_added", subscribeToProp
  propsRef.on "child_removed", unsubscribeFromProp

  eventsRef.on "child_added", (snap) ->
    roomEvent = RoomEvent.createFromSnap(snap)
    self.events.push roomEvent

    self.trigger "eventAdded", roomEvent

  return self

identityMap = {}
Room.find = (id) ->
  return unless id

  stats.increment "room.find"

  identityMap[id] ?= Room
    key: id

V = (fn) ->
  (data) -> fn data.val()
