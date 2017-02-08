FriendTemplate = require "../templates/friend"

Presence = require "../models/presence"
Member = require "../models/member"

{timeAgoInWords} = require "../util"

FriendPresenter = (presence) ->
  member = Member.find presence.key()

  FriendTemplate Object.assign {}, presence,
    name: member.name
    onlineStatus: ->
      "online" if presence.online()
    lastSeen: ->
      timeAgoInWords presence.lastSeen()

module.exports = (self) ->
  element = document.createElement "friends"

  # Listen to all presence changes
  # TODO: Scope to only friends list
  db.ref('presence').on "child_added", (snap) ->
    console.log snap.val()
    presence = Presence.fromSnap(snap)
    element.appendChild FriendPresenter presence

  return element
