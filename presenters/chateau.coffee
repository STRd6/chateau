AvatarTemplate = require "../templates/avatar"
ChateauTemplate = require "../templates/chateau"
RoomTemplate = require "../templates/room"

AvatarPresenter = (avatar, self) ->
  AvatarTemplate Object.assign {}, avatar,
    click: (e) ->
      e.preventDefault()
      self.setAvatar avatar

RoomPresenter = (room, self) ->
  RoomTemplate Object.assign {}, room,
    click: (e) ->
      e.preventDefault()
      self.joinRoom room

module.exports = (self) ->
  element = ChateauTemplate Object.assign {}, self,
    toggleOpen: (e) ->
      # TODO: Close any other open tabs
      e.currentTarget.parentElement.classList.toggle "show"

    avatars: ->
      self.avatars.map (avatar) ->
        AvatarPresenter avatar, self

    rooms: ->
      self.rooms.map (room) ->
        RoomPresenter room, self

  return element
