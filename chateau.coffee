# Chat Based MUD

Drop = require "./lib/drop"

sortBy = (attribute) ->
  (a, b) ->
    a[attribute] - b[attribute]

rand = (n) ->
  Math.floor(Math.random() * n)

module.exports = ->
  canvas = document.createElement 'canvas'
  canvas.width = 960
  canvas.height = 540

  context = canvas.getContext('2d')

  repaint = ->
    # Draw BG
    context.fillStyle = 'blue'
    context.fillRect(0, 0, canvas.width, canvas.height)

    return

    {background, objects} = roomstate
    if background
      context.drawImage(background, 0, 0, canvas.width, canvas.height)

    # Draw Avatars/Objects
    Object.keys(avatars).map (accountId) ->
      avatars[accountId]
    .concat(objects).sort(sortBy("z")).forEach ({color, img, x, y}) ->
      if img
        {width, height} = img
        context.drawImage(img, x - width / 2, y - height / 2)
      else
        context.fillStyle = color
        context.fillRect(x - 25, y - 25, 50, 50)

    # Draw connection status
    if connected()
      indicatorColor = "green"
    else
      indicatorColor = "red"

    context.beginPath()
    context.arc(canvas.width - 20, 20, 10, 0, 2 * Math.PI, false)
    context.fillStyle = indicatorColor
    context.fill()
    context.lineWidth = 2
    context.strokeStyle = '#003300'
    context.stroke()

  resize = ->
    rect = canvas.getBoundingClientRect()
    canvas.width = rect.width
    canvas.height = rect.height

  animate = ->
    requestAnimationFrame animate
    repaint()

  animate()

  # TODO: ViewDidLoad? or equivalent event?
  setTimeout ->
    resize()

  return canvas
