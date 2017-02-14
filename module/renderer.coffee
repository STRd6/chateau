BackgroundImageTemplate = require "../templates/background-image"

SceneObjectTemplate = require "../templates/scene-object"
SceneObjectPresenter = (object) ->
  SceneObjectTemplate Object.assign {}, object,
    style: ->
      x = object.x()|0
      y = object.y()|0

      hw = Math.floor object.img().width / 2
      hh = Math.floor object.img().height / 2

      "transform: matrix(1, 0, 0, 1, #{x}, #{y}); left: -#{hw}px; top: -#{hh}px"

# A scene to contain the background, all the avatars, and props
# We use DOM nodes because we want fancy CSS3 transforms, interactivity, and
# more advanced widgets like youtube embeds
module.exports = (I, self) ->
  scene = document.createElement 'scene'

  # TODO: Drag and move props
  scene.onclick = (e) ->
    {pageX, pageY, currentTarget} = e
    {top, left} = currentTarget.getBoundingClientRect()

    x = pageX - left
    y = pageY - top

    self.currentUser()
    .update
      x: x
      y: y
    .sync(db)

  previousRoom = null

  unbindRoomEvents = (room) ->
    return unless room
    room.off "memberAdded", objectAdded
    room.off "propAdded", objectAdded

    room.off "memberRemoved", objectRemoved
    room.off "propRemoved", objectRemoved

  bindRoomEvents = (room) ->
    return unless room
    room.on "memberAdded", objectAdded
    room.on "propAdded", objectAdded

    room.on "memberRemoved", objectRemoved
    room.on "propRemoved", objectRemoved

  objectAdded = (object) ->
    scene.appendChild SceneObjectPresenter object

  objectRemoved = (object) ->
    

  self.currentRoom.observe (room) ->
    # Empty previous scene
    scene.empty()
    # Unbind add/remove listeners on previous room
    unbindRoomEvents(previousRoom)

    if room
      # Add bg
      scene.appendChild BackgroundImageTemplate room

      # Add avatars
      room.members.forEach objectAdded
      # Add props
      room.props.forEach objectAdded
      # Listen to add/remove events on room and add/remove props and avatars
      bindRoomEvents room

  self.extend
    canvas: scene

  return self
