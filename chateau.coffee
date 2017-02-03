# Chat Based MUD

ChateauTemplate = require "../templates/chateau"
{Modal, Observable} = UI = require "ui"
Drop = require "./lib/drop"

shaUpload = require "./sha-upload"

sortBy = (attribute) ->
  (a, b) ->
    a[attribute] - b[attribute]

rand = (n) ->
  Math.floor(Math.random() * n)

# Connect to room
# Listen to ref
# Download BG


Member = require "./models/member"
Room = require "./models/room"

Prop = Member


drawRoom = (context, room) ->
  backgroundImage = room.backgroundImage()
  members = room.members()
  props = room.props()

  if backgroundImage?.width
    context.drawImage(backgroundImage, 0, 0, context.width, context.height)

  # Draw Avatars/Objects
  Object.values(members)
  .concat(props).sort(sortBy("z")).forEach (object) ->
    img = object.img()
    x = object.x() | 0
    y = object.y() | 0

    {width, height} = img

    if width and height
      context.drawImage(img, x - width / 2, y - height / 2)

accountId = null
initialize = (self) ->
  {firebase} = self
  db = firebase.database()

  # Populate Rooms list
  db.ref("rooms").on "child_added", (room) ->
    key = room.key
    room = room.val()

    console.log "Room:", room
    self.rooms.push Room Object.assign {}, room,
      key: key

module.exports = (firebase) ->
  db = firebase.database()

  canvas = document.createElement 'canvas'
  canvas.width = 960
  canvas.height = 540

  context = canvas.getContext('2d')
  context.width = canvas.width
  context.height = canvas.height

  # TODO: Drag and move props
  canvas.onclick = (e) ->
    {pageX, pageY, currentTarget} = e
    {top, left} = currentTarget.getBoundingClientRect()

    x = pageX - left
    y = pageY - top

    self.currentUser()
    .update
      x: x
      y: y
    .sync(db)

  repaint = ->
    context.fillStyle = 'white'
    context.fillRect(0, 0, canvas.width, canvas.height)

    if room = self.currentRoom()
      drawRoom(context, room)

    return

  self =
    status: Observable "Connecting..."
    canvas: canvas
    firebase: firebase
    currentRoom: Observable null
    currentUser: Observable null
    rooms: Observable []

    anonLogin: (e) ->
      e.preventDefault()

      firebase.auth().signInAnonymously()

    googleLogin: (e) ->
      e.preventDefault()

      provider = new firebase.auth.GoogleAuthProvider()
      provider.addScope('profile')
      provider.addScope('email')
      firebase.auth().signInWithPopup(provider)

    createRoom: ->
      Modal.prompt("Room name", "cool guys")
      .then (name) ->
        if name
          db.ref("rooms").push
            name: name

    joinRoom: (room) ->
      return if room is self.currentRoom()

      accountId = self.currentUser()?.key()
      return unless accountId

      self.currentRoom()?.disconnect(accountId)

      room.connect(accountId)

      self.currentRoom room

    saySubmit: (e) ->
      e.preventDefault()

      input = e.currentTarget.querySelector('input')
      words = input.value
      if words
        input.value = ""

        self.currentUser().update
          text: words
        .sync(db)

    words: ->
      self.currentRoom()?.members.map (member) ->
        member.wordElement()

  initialize(self)

  RoomTemplate = require "./templates/room"

  presenter = Object.assign {}, self,
    rooms: ->
      self.rooms.map (room) ->
        RoomTemplate Object.assign {}, room,
          click: (e) ->
            e.preventDefault()
            self.joinRoom room

  self.element = element = ChateauTemplate presenter

  Drop element, (e) ->
    files = e.dataTransfer.files

    if files.length
      file = files[0]

      console.log(file)
      shaUpload(firebase, file)
      .then (downloadURL) ->
        console.log downloadURL
        Modal.form require("./templates/asset-form")()
        .then (result) ->
          switch result?.selection
            when "avatar"
              self.currentUser()
              .update
                avatarURL: downloadURL
              .sync()

            when "background"
              room = self.currentRoom()
              room.backgroundURL(downloadURL)
              room.sync()

  animate = ->
    requestAnimationFrame animate
    repaint()

  animate()

  db.ref(".info/connected").on "value", (snap) ->
    if snap.val()
      self.status "Connected"
    else
      self.status "Connecting..."

  progressView = UI.Progress
    message: "Initializing..."
  Modal.show progressView.element,
    cancellable: false

  # Initialize auth state
  removeListener = firebase.auth().onAuthStateChanged (user) ->
    console.log "Start", user
    if user
      # User is signed in.
      accountId = user.uid
  
      Modal.hide()
      removeListener()
  
      # TODO: Auto-connect to last room
      self.currentUser Member.find(accountId).connect()
    else
      # No user is signed in.
      loginTemplate = require("./templates/login")(self)
      Modal.show loginTemplate,
        cancellable: false

  return self
