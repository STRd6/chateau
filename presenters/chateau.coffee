AvatarTemplate = require "../templates/avatar"
ChateauTemplate = require "../templates/chateau"
PropTemplate = require "../templates/prop"
RoomTemplate = require "../templates/room"

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
  roomsLogElements = {}

  findOrInitRoomLogs = (room) ->
    key = room.key()

    return roomsLogElements[key] if roomsLogElements[key]

    logsElement = document.createElement 'logs'

    # Use this trick to escape auto-binding room events observable
    setTimeout ->
      room.events.forEach (event) ->
        logsElement.appendChild LogPresenter event
      room.on "eventAdded", (event) ->
        logsElement.appendChild LogPresenter event
    , 0

    roomsLogElements[key] = logsElement

    return logsElement
  
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

    logs: ->
      room = self.currentRoom()

      if room
        findOrInitRoomLogs(room)

  return element
