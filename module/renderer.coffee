drawRoom = (context, room) ->
  backgroundImage = room.img()
  members = room.members()
  props = room.props()

  if backgroundImage?.width
    context.drawImage(backgroundImage, 0, 0, context.width, context.height)

  # Draw Avatars/Objects
  Object.values(members)
  .concat(props).forEach (object) ->
    img = object.img()
    {width, height} = img
    x = (object.x() - width / 2) | 0
    y = (object.y() - height / 2) | 0

    if width and height
      context.drawImage(img, x, y)

drawAvatar = (context, member) ->
  return unless member

  img = member.img()
  {width, height} = img
  x = ((context.width - width) / 2) | 0
  y = ((context.height - height) / 2) | 0

  if width and height
    context.drawImage(img, x, y)

module.exports = (I, self) ->
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
    else if user = self.currentUser()
      drawAvatar(context, user)

    return

  # Just animate forever
  # later we can think about stopping/starting
  animate = ->
    requestAnimationFrame animate
    repaint()
  animate()

  self.extend
    canvas: canvas

  return self
