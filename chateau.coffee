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

Model = require "model"
Member = (I={}, self=Model(I)) ->
  I.text ?= ""

  self.attrObservable "avatarURL", "x", "y", "text", "key"

  img = new Image
  wordElement = document.createElement "words"

  update = (memberData) ->
    self.update memberData.val()

  self.extend
    img: ->
      img

    connect: (db) ->
      db.ref("members/#{self.key()}").on "value", update

      return self

    disconnect: (db) ->
      db.ref("members/#{self.key()}").off "value", update

      return self

    updatePosition: ({x, y}) ->
      self.x x
      self.y y

    update: (data) ->
      Object.keys(data).forEach (key) ->
        self[key]? data[key]

      return self

    wordElement: ->
      wordElement

    sync: (db) ->
      db.ref("members/#{self.key()}").update
        x: self.x()
        y: self.y()
        text: self.text()

      # TODO: Return promise for status?
      return self

  updateTextPosition = ->
    wordElement.style.left = "#{self.x()}px"
    wordElement.style.top = "#{self.y() - 50}px"

  self.avatarURL.observe (url) ->
    console.log "settin", url
    img.src = url

  self.text.observe (text) ->
    wordElement.textContent = text
    updateTextPosition()

  self.x.observe updateTextPosition
  self.y.observe updateTextPosition

  return self

Prop = Member

Room = (I={}, self=Model(I)) ->
  self.attrObservable "backgroundURL", "name"
  self.attrModels "members", Member
  self.attrModels "props", Prop

  db = null
  accountId = null

  backgroundImage = new Image
  backgroundImage.src = I.backgroundURL

  subscribeToMember = (memberData) ->
    {key} = memberData
    console.log "Sub", key

    member = Member()
    member.key key
    member.connect(db)

    self.members.push member

  unsubscribeFromMember = ({key}) ->
    console.log "Unsub", key

    member = self.memberByKey(key)

    if member
      self.members.remove member
      member.disconnect(db, key)

  self.extend
    init: (_db, _accountId) ->
      accountId = _accountId
      db = _db

      return self

    backgroundImage: ->
      backgroundImage

    connect: ->
      name = self.name()

      db.ref("rooms/#{name}/members").on "child_added", subscribeToMember
      db.ref("rooms/#{name}/members").on "child_removed", unsubscribeFromMember

      # TODO: Should we do this changeover atomically?
      # Add member to current room
      db.ref("rooms/#{name}/members/#{accountId}").set true
      db.ref("members/#{accountId}/room").set name

      return self

    disconnect: ->
      name = self.name()

      # Remove self from previous room
      db.ref("rooms/#{name}/members/#{accountId}").set null

      db.ref("rooms/#{name}/members").off "child_added", subscribeToMember
      db.ref("rooms/#{name}/members").off "child_removed", unsubscribeFromMember
    
    memberByKey: (key) ->
      [member] = self.members.filter (member) ->
        member.key() is key

      return member

    updatePosition: (pos) ->
      self.memberByKey(accountId)?.update pos
      .sync(db)

    updateText: (text) ->
      self.memberByKey(accountId)?.update
        text: text
      .sync(db)

drawRoom = (context, room) ->
  backgroundImage = room.backgroundImage()
  members = room.members()
  props = room.props()

  if backgroundImage
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

# TODO: If we call this too early it may needlessly swap anon accounts
# 

accountId = null
initialize = (self) ->
  {firebase} = self
  db = firebase.database()

  firebase.auth().onAuthStateChanged (user) ->
    console.log "Start", user
    if user
      # User is signed in.
      accountId = user.uid
    else
      # No user is signed in.
      firebase.auth().signInAnonymously()

  firebase.database().ref("rooms").once "value", (rooms) ->
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

  # TODO: Drag and move props
  canvas.onclick = (e) ->
    {pageX, pageY, currentTarget} = e
    {top, left} = currentTarget.getBoundingClientRect()

    x = pageX - left
    y = pageY - top

    self.currentRoom()?.updatePosition
      x: x
      y: y

  repaint = ->
    context.fillStyle = 'white'
    context.fillRect(0, 0, canvas.width, canvas.height)

    if room = self.currentRoom()
      drawRoom(context, room)

    return

  self =
    canvas: canvas
    firebase: firebase
    currentRoom: Observable null
    rooms: Observable []
    joinRoom: ({name, backgroundURL}) ->
      return if name is room?.name()

      self.currentRoom()?.disconnect()

      room = Room
        name: name
        backgroundURL: backgroundURL
        members: []
        objects: []
      .init db, accountId
      .connect()

      self.currentRoom room

    saySubmit: (e) ->
      e.preventDefault()

      input = e.currentTarget.querySelector('input')
      words = input.value
      if words
        input.value = ""

        self.currentRoom()?.updateText words

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
        UI.Modal.form require("./templates/asset-form")()
        .then (result) ->
          switch result?.selection
            when "avatar"
              ;
            when "background"
              ;

  animate = ->
    requestAnimationFrame animate
    repaint()

  animate()

  return self
