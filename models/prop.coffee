Model = require "model"

Base = require "./base"
Drawable = require "./drawable"
Positionable = require "./positionable"

module.exports = (tableName) ->
  Base tableName, (I={}, self=Model(I)) ->
    defaults I,
      x: 480
      y: 270

    self.include Drawable, Positionable

    return self
