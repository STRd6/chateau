# Chat Based MUD

ChateauTemplate = require "../templates/chateau"
Observable = require "observable"
Drop = require "./lib/drop"

sortBy = (attribute) ->
  (a, b) ->
    a[attribute] - b[attribute]

rand = (n) ->
  Math.floor(Math.random() * n)

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
    context.drawImage(backgroundImage, 0, 0, canvas.width, canvas.height)

  # Draw Avatars/Objects
  Object.values(avatars)
  .concat(objects).sort(sortBy("z")).forEach ({img, x, y}) ->
    {width, height} = img
    context.drawImage(img, x - width / 2, y - height / 2)

# TODO: If we call this too early it may needlessly swap anon accounts
# firebase.auth().signInAnonymously()

initialize = (self) ->
  {firebase} = self

  firebase.auth().onAuthStateChanged (user) ->
    console.log "User:", user
    if user
      # User is signed in.
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
  canvas = document.createElement 'canvas'
  canvas.width = 960
  canvas.height = 540

  context = canvas.getContext('2d')

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
            console.log room.name

  self.element = ChateauTemplate presenter

  return self
