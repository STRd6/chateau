module.exports = (I, self) ->
  self.attrSync "x", "y"

  self.extend
    updatePosition: ({x, y}) ->
      self.update
        x: x
        y: y
