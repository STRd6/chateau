# Chat Based MUD

ChateauPresenter = require "./presenters/chateau"
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
    {width, height} = img
    x = (object.x() - width / 2) | 0
    y = (object.y() - height / 2) | 0

    if width and height
      context.drawImage(img, x, y)

initialize = (self) ->

  # Populate Rooms list
  db.ref("rooms").on "child_added", (room) ->
    key = room.key
    value = room.val()

    stats.increment "room.added"
    room = Room.find(key).update value

    self.rooms.push room

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
    currentRoom: ->
      Room.find self.currentUser()?.roomId()
    currentUser: Observable null
    currentFirebaseUser: Observable null
    avatars: Observable [
      "https://1.pixiecdn.com/sprites/148517/original.png"
      "https://0.pixiecdn.com/sprites/148468/original.png"
      "https://1.pixiecdn.com/sprites/147597/original.png"
      "https://1.pixiecdn.com/sprites/151181/original.png"
      "https://1.pixiecdn.com/sprites/150973/original.png"
      "https://3.pixiecdn.com/sprites/151199/original.png"
      "https://3.pixiecdn.com/sprites/151187/original.png"
      "https://0.pixiecdn.com/sprites/151140/original.png"
      "https://3.pixiecdn.com/sprites/150719/original.png"
      "https://1.pixiecdn.com/sprites/151149/original.png"
      "https://2.pixiecdn.com/sprites/151046/original.png"
    ].map (url) -> avatarURL: url
    rooms: Observable []

    displayModalLoader: (message) ->
      progressView = UI.Progress
        message: message
      Modal.show progressView.element,
        cancellable: false

    accountConnected: (firebaseUser) ->
      self.currentFirebaseUser firebaseUser
      user = Member.find(firebaseUser.uid)
      self.currentUser user

      self.displayModalLoader "Loading..."
      user.connect().then ->
        # TODO: Display Avatar Drawer unless user has avatar

        # Connect to previously connected room
        previousRoom = Room.find(user.roomId())
        if previousRoom
          # Need to force join because currentRoom will be equal to previousRoom
          self.joinRoom previousRoom, true
        else
          # Display Rooms drawer
          self.element.querySelectorAll("tab-drawer > *").forEach (element) ->
            element.classList.remove("show")
          self.element.querySelector("room-control").classList.add("show")
      .catch (e) ->
        console.log "errrr", e
      .finally ->
        Modal.hide()

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

    setBackgroundURL: (backgroundURL) ->
      room = self.currentRoom()
      room.backgroundURL(backgroundURL)
      room.sync()

    setAvatar: (avatarURL) ->
      self.currentUser()
      .update
        avatarURL: avatarURL
      .sync()

    joinRoom: (room, force) ->
      if !force and room is self.currentRoom()
        return

      user = self.currentUser()

      accountId = user?.key()
      return unless accountId

      self.currentRoom()?.disconnect(accountId)
      room.connect(accountId)

      user.roomId room.key()
      user.sync()
      
      console.log "croom", self.currentRoom()?.I

      return

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

  self.element = element = ChateauPresenter self

  Drop element, (e) ->
    files = e.dataTransfer.files

    if files.length
      # TODO: Process multiple files
      file = files[0]

      stats.increment "drop-file"

      shaUpload(firebase, file)
      .then (downloadURL) ->
        Modal.form require("./templates/asset-form")()
        .then (result) ->
          switch result?.selection
            when "avatar"
              self.setAvatar downloadURL

            when "background"
              self.setBackgroundURL downloadURL

  animate = ->
    requestAnimationFrame animate
    repaint()

  animate()

  db.ref(".info/connected").on "value", (snap) ->
    if snap.val()
      self.status "Connected"
      stats.increment "connect"
    else
      self.status "Connecting..."

  self.displayModalLoader("Initializing...")

  # Initialize auth state
  removeListener = firebase.auth().onAuthStateChanged (user) ->
    logger.info "Start", user
    if user
      # User is signed in.
      Modal.hide()
      removeListener()

      self.accountConnected(user)
    else
      # No user is signed in.
      loginTemplate = require("./templates/login")(self)
      Modal.show loginTemplate,
        cancellable: false

  return self
