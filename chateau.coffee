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

  self.attrReader "accountId"
  self.attrObservable "avatarURL", "x", "y", "text", "key"

  img = new Image
  wordElement = document.createElement "words"

  update = (memberData) ->
    self.update memberData.val()

  self.extend
    img: ->
      img

    connect: (db) ->
      db.ref("members/#{self.accountId()}").on "value", update

      return self

    disconnect: (db) ->
      db.ref("members/#{self.accountId()}").off "value", update

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
      db.ref("members/#{self.accountId()}").update
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

Member.fromAccountId = (db, id) ->
  # TODO: Identity map account ids

  new Promise (resolve, reject) ->
    db.ref("members/#{id}").once "value", (data) ->
      resolve Member Object.assign {}, data.val(),
        accountId: id
    , reject

Prop = Member

Room = (I={}, self=Model(I)) ->
  self.attrObservable "backgroundURL", "name"
  self.attrModels "members", Member
  self.attrModels "props", Prop

  db = null

  backgroundImage = new Image
  backgroundImage.src = I.backgroundURL

  subscribeToMember = (memberData) ->
    {key} = memberData
    console.log "Sub", key

    member = Member
      accountId: key
    member.connect(db)

    self.members.push member

  unsubscribeFromMember = ({key}) ->
    console.log "Unsub", key

    member = self.memberByKey(key)

    if member
      self.members.remove member
      member.disconnect(db, key)

  self.extend
    init: (_db) ->
      db = _db

      return self

    backgroundImage: ->
      backgroundImage

    connect: (accountId) ->
      name = self.name()

      db.ref("rooms/#{name}/members").on "child_added", subscribeToMember
      db.ref("rooms/#{name}/members").on "child_removed", unsubscribeFromMember

      # TODO: Should we do this changeover atomically?
      # Add member to current room
      db.ref("rooms/#{name}/members/#{accountId}").set true
      db.ref("members/#{accountId}/room").set name

      return self

    disconnect: (accountId) ->
      name = self.name()

      # Remove self from previous room
      db.ref("rooms/#{name}/members/#{accountId}").set null

      db.ref("rooms/#{name}/members").off "child_added", subscribeToMember
      db.ref("rooms/#{name}/members").off "child_removed", unsubscribeFromMember
    
    memberByKey: (key) ->
      [member] = self.members.filter (member) ->
        member.key() is key

      return member

    sync: (db) ->
      # TODO: Switch to unique ids?
      db.ref("rooms/#{self.name()}").update
        backgroundURL: self.backgroundURL()

  self.backgroundURL.observe (url) ->
    backgroundImage.src = url

  return self

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

accountId = null
initialize = (self) ->
  {firebase} = self
  db = firebase.database()

  firebase.auth().onAuthStateChanged (user) ->
    console.log "Start", user
    if user
      # User is signed in.
      accountId = user.uid
      
      Member.fromAccountId(db, accountId)
      .then self.currentUser
    else
      # No user is signed in.
      firebase.auth().signInAnonymously()

  db.ref("rooms").once "value", (rooms) ->
    rooms = rooms.val()

    results = Object.values(rooms)

    # TODO: Use room models for auto-binding
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
    canvas: canvas
    firebase: firebase
    currentRoom: Observable null
    currentUser: Observable null
    rooms: Observable []
    joinRoom: ({name, backgroundURL}) ->
      return if name is room?.name()

      accountId = self.currentUser()?.accountId()
      return unless accountId

      self.currentRoom()?.disconnect(accountId)

      room = Room
        name: name
        backgroundURL: backgroundURL
        members: []
        objects: []
      .init db
      .connect(accountId)

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
        UI.Modal.form require("./templates/asset-form")()
        .then (result) ->
          switch result?.selection
            when "avatar"
              self.currentUser()
              .update
                avatarURL: downloadURL
              .sync(db)

            when "background"
              room = self.currentRoom()
              room.backgroundURL(downloadURL)
              room.sync(db)

  animate = ->
    requestAnimationFrame animate
    repaint()

  animate()

  return self
