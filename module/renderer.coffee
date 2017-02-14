{elementView} = require "../util"

BackgroundImageTemplate = require "../templates/background-image"

SceneObjectTemplate = require "../templates/scene-object"
SceneObjectView = (object) ->
  self =
    element: null

  element = SceneObjectTemplate Object.assign self, object,
    style: ->
      x = object.x()|0
      y = object.y()|0

      hw = Math.floor object.img().width / 2
      hh = Math.floor object.img().height / 2

      "transform: matrix(1, 0, 0, 1, #{x}, #{y}); left: -#{hw}px; top: -#{hh}px"

  element.view = self
  element.object = object
  self.element = element

  return self

addDragHandling = (element) ->
  # Drag Handling
  activeDrag = null
  dragStart = null
  element.addEventListener "mousedown", (e) ->
    {target} = e

    view = elementView target

    # TODO: Ensure view is an avatar or prop
    return unless view

    e.preventDefault()

    dragStart = e
    activeDrag = view
    view.element.classList.add "dragging"

  element.addEventListener "mousemove", (e) ->
    if activeDrag
      {clientX:prevX, clientY:prevY} = dragStart
      {clientX:x, clientY:y} = e

      dx = x - prevX
      dy = y - prevY

      activeDrag.updatePosition
        x: activeDrag.x() + dx
        y: activeDrag.y() + dy
      .sync()

      dragStart = e

  # This is document to capture all mouseups, even those that take place outside
  # of the element
  document.addEventListener "mouseup", ->
    activeDrag?.element.classList.remove "dragging"

    activeDrag = null
    activeResize = null

# A scene to contain the background, all the avatars, and props
# We use DOM nodes because we want fancy CSS3 transforms, interactivity, and
# more advanced widgets like youtube embeds
module.exports = (I, self) ->
  scene = document.createElement 'scene'

  addDragHandling(scene)

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
    view = SceneObjectView object
    scene.appendChild view.element

  objectRemoved = (object) ->
    toRemove = Array::filter.call scene.children, (element) ->
      element.object is object

    toRemove.forEach (element) ->
      element.remove()

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
