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
    {key} = memberData
    console.log "Sub", key

    member = Member.find key
    member.connect()

    self.members.push member

  unsubscribeFromMember = ({key}) ->
    console.log "Unsub", key

    member = self.memberByKey(key)

    if member
      self.members.remove member
      member.disconnect()

  updateBackgroundURL = V self.backgroundURL

  self.extend
    backgroundImage: ->
      backgroundImage

    connect: (accountId) ->
      key = self.key()

      ref.child("memberships").on "child_added", subscribeToMember
      ref.child("memberships").on "child_removed", unsubscribeFromMember
      
      ref.child("backgroundURL").on "value", updateBackgroundURL

      # Add member to current room
      ref.child("memberships/#{accountId}").set true

      return self

    disconnect: (accountId) ->
      key = self.key()

      # Remove self from previous room
      ref.child("memberships/#{accountId}").set null

      ref.child("backgroundURL").off "value", updateBackgroundURL

      ref.child("memberships").off "child_added", subscribeToMember
      ref.child("memberships").off "child_removed", unsubscribeFromMember

    memberByKey: (key) ->
      [member] = self.members.filter (member) ->
        member.key() is key

      return member

    sync: ->
      ref.update
        backgroundURL: self.backgroundURL()

  self.backgroundURL.observe (url) ->
    if url
      backgroundImage.src = url

  return self

identityMap = {}
Room.find = (id) ->
  identityMap[id] ?= Room
    key: id

V = (fn) ->
  (data) -> fn data.val()
