Model = require "model"

Drawable = require "./drawable"
Member = require "./member"
Prop = require "./prop"

module.exports = Room = (I={}, self=Model(I)) ->
  defaults I,
    members: []
    props: []

  self.attrReader "key"
  self.include Drawable

  self.attrObservable "name"
  self.attrModels "members", Member
  self.attrModels "props", Prop

  table = db.ref("rooms")
  ref = table.child(self.key())

  subscribeToProp = (snap) ->
    stats.increment "room.subscribe-prop"

    {key} = snap
    value = snap.val()

    prop = Prop.find key
    prop.update(value)
    prop.connect()

    unless self.propByKey(key)
      self.props.push prop

  unsubscribeFromProp = ({key}) ->
    stats.increment "room.unsubscribe-prop"

    prop = self.propByKey(key)

    if prop
      self.props.remove prop
      prop.disconnect()

  subscribeToMember = (memberData) ->
    stats.increment "room.subscribe-member"

    {key} = memberData

    member = Member.find key
    member.connect()

    unless self.memberByKey(key)
      self.members.push member

  unsubscribeFromMember = ({key}) ->
    stats.increment "room.unsubscribe-member"

    member = self.memberByKey(key)

    if member
      self.members.remove member
      member.disconnect()

  updateBackgroundURL = V self.imageURL

  self.extend
    addProp: ({imageURL}) ->
      ref.child("props").push
        x: (Math.random() * 960)|0
        y: (Math.random() * 540)|0
        imageURL: imageURL

    clearAllProps: ->
      ref.child("props").remove()

    connect: (accountId) ->
      stats.increment("room-connect")

      key = self.key()

      ref.child("memberships").on "child_added", subscribeToMember
      ref.child("memberships").on "child_removed", unsubscribeFromMember

      ref.child("props").on "child_added", subscribeToProp
      ref.child("props").on "child_removed", unsubscribeFromProp

      ref.child("backgroundURL").on "value", updateBackgroundURL

      # Add member to current room
      ref.child("memberships/#{accountId}").set true

      return self

    disconnect: (accountId) ->
      stats.increment("room-disconnect")

      key = self.key()

      # Remove self from previous room
      ref.child("memberships/#{accountId}").set null

      ref.child("backgroundURL").off "value", updateBackgroundURL

      ref.child("props").off "child_removed", unsubscribeFromProp
      ref.child("props").off "child_added", subscribeToProp

      ref.child("memberships").off "child_added", subscribeToMember
      ref.child("memberships").off "child_removed", unsubscribeFromMember

    update: (data) ->
      return unless data
      stats.increment "room.update"

      Object.keys(data).forEach (key) ->
        self[key]? data[key]

      return self

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

  return self

identityMap = {}
Room.find = (id) ->
  return unless id

  identityMap[id] ?= Room
    key: id

V = (fn) ->
  (data) -> fn data.val()
