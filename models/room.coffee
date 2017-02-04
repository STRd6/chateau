Model = require "model"

Member = require "./member"
Prop = Member

module.exports = Room = (I={}, self=Model(I)) ->
  defaults I,
    members: []
    props: []

  self.attrReader "key"
  self.attrObservable "backgroundURL", "name"
  self.attrModels "members", Member
  self.attrModels "props", Prop

  table = db.ref("rooms")
  ref = table.child(self.key())

  backgroundImage = new Image
  backgroundImage.src = I.backgroundURL

  subscribeToMember = (memberData) ->
    stats.increment "subscribeToMember"

    {key} = memberData

    member = Member.find key
    member.connect()

    self.members.push member

  unsubscribeFromMember = ({key}) ->
    stats.increment "unsubscribeFromMember"

    member = self.memberByKey(key)

    if member
      self.members.remove member
      member.disconnect()

  updateBackgroundURL = V self.backgroundURL

  self.extend
    backgroundImage: ->
      backgroundImage

    connect: (accountId) ->
      stats.increment("room-connect")

      key = self.key()

      ref.child("memberships").on "child_added", subscribeToMember
      ref.child("memberships").on "child_removed", unsubscribeFromMember

      ref.child("backgroundURL").on "value", updateBackgroundURL

      # Add member to current room
      ref.child("memberships/#{accountId}").set true
      ref.child("memberships/#{accountId}").onDisconnect().remove()

      return self

    disconnect: (accountId) ->
      stats.increment("room-disconnect")

      key = self.key()

      # Remove self from previous room
      ref.child("memberships/#{accountId}").set null
      ref.child("memberships/#{accountId}").onDisconnect().cancel()

      ref.child("backgroundURL").off "value", updateBackgroundURL

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

    numberOfCurrentOccupants: ->
      self.members.length

    sync: ->
      ref.update
        backgroundURL: self.backgroundURL()

  self.backgroundURL.observe (url) ->
    if url
      backgroundImage.src = url

  return self

identityMap = {}
Room.find = (id) ->
  return unless id

  identityMap[id] ?= Room
    key: id

V = (fn) ->
  (data) -> fn data.val()
