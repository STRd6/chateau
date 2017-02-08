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

audioBlip = new Audio
audioBlip.src = "https://firebasestorage.googleapis.com/v0/b/chateau-f2799.appspot.com/o/users%2F6T9b9MMW1qMCToWpfvl3Uutzi4p2%2Fdata%2F50494d2f9edb8ae2a9cdaf51d6b348e93f15da40b3326ae35832fecb6173f7ea?alt=media&token=c2e9fedd-20cc-4fc7-9d39-77d24e7c64f9"

module.exports = (self) ->
  previousRoom = null
  logsElement = document.createElement 'logs'

  playSound = true

  addLog = (event) ->
    if playSound
      audioBlip.pause()
      audioBlip.currentTime = 0
      audioBlip.play()

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

    playSound = false
    room.events.forEach addLog
    playSound = true
    room.on "eventAdded", addLog

  return element
