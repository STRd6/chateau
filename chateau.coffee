# Chat Based MUD

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

initialize = (firebase) ->
  firebase.auth().onAuthStateChanged (user) ->
    console.log "User:", user
    if user
      # User is signed in.
    else
      # No user is signed in.

module.exports = (firebase) ->
  canvas = document.createElement 'canvas'
  canvas.width = 960
  canvas.height = 540

  context = canvas.getContext('2d')
  
  initialize(firebase)

  repaint = ->
    context.fillStyle = 'blue'
    context.fillRect(0, 0, canvas.width, canvas.height)

    drawRoom(context, roomData)

    return

  animate = ->
    requestAnimationFrame animate
    repaint()

  animate()

  return canvas
