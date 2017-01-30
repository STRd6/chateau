# Chat Based MUD

ChateauTemplate = require "../templates/chateau"
Observable = require "observable"
Drop = require "./lib/drop"

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
  self.attrObservable "avatarURL", "x", "y", "text", "key"

  img = new Image

  update = (memberData) ->
    dataValue = memberData.val()
    console.log dataValue
    Object.keys(dataValue).forEach (key) ->
      self[key]? dataValue[key]

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

  self.avatarURL.observe (url) ->
    console.log "settin", url
    img.src = url

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

    [member] = 

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
    
    memberByKey = (key) ->
      [member] = self.members.filter (member) ->
        member.key() is key

      return member

    updatePosition: (pos) ->
      memberByKey(accountId)?.updatePosition(pos)

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
# firebase.auth().signInAnonymously()

accountId = null
initialize = (self) ->
  {firebase} = self
  db = firebase.database()

  firebase.auth().onAuthStateChanged (user) ->
    if user
      # User is signed in.
      accountId = user.uid
    else
      # No user is signed in.

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

  canvas.onclick = (e) ->
    {pageX, pageY, currentTarget} = e
    {top, left} = currentTarget.getBoundingClientRect()

    x = pageX - left
    y = pageY - top

    room?.updatePosition
      x: x
      y: y

  repaint = ->
    context.fillStyle = 'white'
    context.fillRect(0, 0, canvas.width, canvas.height)

    if room
      drawRoom(context, room)

    return

  animate = ->
    requestAnimationFrame animate
    repaint()

  animate()

  room = null

  self =
    canvas: canvas
    firebase: firebase
    rooms: Observable []
    joinRoom: ({name, backgroundURL}) ->
      return if name is room?.name()

      room?.disconnect()

      room = Room
        name: name
        backgroundURL: backgroundURL
        members: []
        objects: []
      .init db, accountId
      .connect()

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
