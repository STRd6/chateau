# Chat Based MUD

ChateauTemplate = require "../templates/chateau"
Observable = require "observable"
Drop = require "./lib/drop"

sortBy = (attribute) ->
  (a, b) ->
    a[attribute] - b[attribute]

rand = (n) ->
  Math.floor(Math.random() * n)

accountId = null
currentRoom = null

roomData =
  backgroundImage: null
  avatars: []
  objects: []

# Connect to room
# Listen to ref
# Download BG

drawRoom = (context, room) ->
  {backgroundImage, avatars, objects} = room

  if backgroundImage
    context.drawImage(backgroundImage, 0, 0, context.width, context.height)

  # Draw Avatars/Objects
  Object.values(avatars)
  .concat(objects).sort(sortBy("z")).forEach ({img, x, y}) ->
    {width, height} = img
    context.drawImage(img, x - width / 2, y - height / 2)

# TODO: If we call this too early it may needlessly swap anon accounts
# firebase.auth().signInAnonymously()

initialize = (self) ->
  {firebase} = self
  db = firebase.database()

  firebase.auth().onAuthStateChanged (user) ->
    console.log "User:", user
    if user
      # User is signed in.
      accountId = user.uid
      # TODO: Load avatar data
      db.ref("accounts/#{accountId}").on "value", (account) ->
        console.log "Account:", account.val()
        currentRoom = account.val().room
    else
      # No user is signed in.

  firebase.database().ref("rooms/googol").set
    backgroundURL: "https://www.gstatic.com/images/branding/googlelogo/2x/googlelogo_color_284x96dp.png"

  firebase.database().ref("rooms").on "value", (rooms) ->
    rooms = rooms.val()

    results = Object.keys(rooms).map (id) ->
      data = rooms[id]
      data.name = id

      data

    self.rooms results
    console.log "Rooms:", results

module.exports = (firebase) ->
  db = firebase.database()

  canvas = document.createElement 'canvas'
  canvas.width = 960
  canvas.height = 540

  context = canvas.getContext('2d')
  context.width = canvas.width
  context.height = canvas.height

  repaint = ->
    context.fillStyle = 'white'
    context.fillRect(0, 0, canvas.width, canvas.height)

    drawRoom(context, roomData)

    return

  animate = ->
    requestAnimationFrame animate
    repaint()

  animate()

  self =
    canvas: canvas
    firebase: firebase
    rooms: Observable []
    joinRoom: (room) ->
      previousRoom = currentRoom
      currentRoom = room.name

      updates = {}
      # Remove self from previous room
      updates["rooms/#{previousRoom}/members/#{accountId}"] = null
      # Add to current room
      updates["rooms/#{currentRoom}/members/#{accountId}"] = true
      # Update accout room ref
      updates["accounts/#{accountId}/room"] = room.name

      console.log updates

      db.ref().update updates

      bg = new Image
      bg.src = room.backgroundURL

      roomData =
        backgroundImage: bg
        avatars: []
        objects: []

    saySubmit: (e) ->
      e.preventDefault()

      input = e.currentTarget.querySelector('input')
      words = input.value
      if words
        input.value = ""

        console.log words

  initialize(self)

  RoomTemplate = require "./templates/room"

  presenter = Object.assign {}, self,
    rooms: ->
      self.rooms.map (room) ->
        RoomTemplate Object.assign {}, room,
          click: (e) ->
            e.preventDefault()
            self.joinRoom room

  self.element = ChateauTemplate presenter

  return self
