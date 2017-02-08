AvatarTemplate = require "../templates/avatar"
ChateauTemplate = require "../templates/chateau"
PropTemplate = require "../templates/prop"
RoomTemplate = require "../templates/room"

FriendsPresenter = require "./friends"

AvatarPresenter = (avatar, self) ->
  stats.increment "presenter.avatar"

  AvatarTemplate Object.assign {}, avatar,
    click: (e) ->
      e.preventDefault()
      self.setAvatar avatar.avatarURL

RoomPresenter = (room, self) ->
  stats.increment "presenter.room"

  RoomTemplate Object.assign {}, room,
    click: (e) ->
      e.preventDefault()
      self.joinRoom room

PropPresenter = (prop, self) ->
  stats.increment "presenter.prop"

  PropTemplate Object.assign {}, prop,
    click: (e) ->
      e.preventDefault()
      self.addProp prop

LogPresenter = (event) ->
  stats.increment "presenter.log"

  switch event.type()
    when "chat"
      log = document.createElement "log"

      {sender, message} = event.content()

      log.textContent = "#{sender}: #{message}"

      return log

module.exports = (self) ->
  previousRoom = null
  logsElement = document.createElement 'logs'

  addLog = (event) ->
    logsElement.appendChild LogPresenter event

  element = ChateauTemplate Object.assign {}, self,
    toggleOpen: (e) ->
      # TODO: Close any other open tabs
      e.currentTarget.parentElement.classList.toggle "show"

    avatars: ->
      self.avatars.map (avatar) ->
        AvatarPresenter avatar, self

    props: ->
      self.props.map (prop) ->
        PropPresenter prop, self

    rooms: ->
      self.rooms.map (room) ->
        RoomPresenter room, self

    logsElement: logsElement

    friends: ->
      FriendsPresenter(self)

  # Update logs when switching rooms
  self.currentRoom.observe (room) ->
    return unless room

    key = room.key()

    stats.increment "present.room-change"

    previousRoom?.off "eventAdded", addLog
    previousRoom = room

    logsElement.empty()

    room.events.forEach addLog
    room.on "eventAdded", addLog

  return element
