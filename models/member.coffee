Drawable = require "./drawable"
Model = require "model"
OpenPromise = require "../lib/open-promise"

module.exports = Member = (I={}, self=Model(I)) ->
  defaults I,
    text: ""
    x: 480
    y: 270

  self.include Drawable

  self.attrReader "key"
  self.attrObservable "x", "y", "text", "roomId"

  wordElement = document.createElement "words"

  table = db.ref("members")
  ref = table.child(self.key())

  connectedPromise = OpenPromise()

  update = (memberData) ->
    connectedPromise.resolve()
    self.update memberData.val()

  ref.on "value", update

  self.extend
    connect: ->
      connectedPromise

    disconnect: ->
      ref.off "value", update

      return self

    updatePosition: ({x, y}) ->
      self.x x
      self.y y

    update: (data) ->
      return unless data
      stats.increment "member.update"

      Object.keys(data).forEach (key) ->
        self[key]? data[key]

      return self

    wordElement: ->
      wordElement

    sync: ->
      # TODO: Only update changed
      ref.update
        imageURL: self.imageURL()
        x: self.x()
        y: self.y()
        text: self.text()
        roomId: self.roomId()

  updateTextPosition = ->
    wordElement.style.left = "#{self.x()}px"
    wordElement.style.top = "#{self.y() - self.height()/2 - 30}px"

  self.text.observe (text) ->
    wordElement.textContent = text
    updateTextPosition()

  self.x.observe updateTextPosition
  self.y.observe updateTextPosition
  self.imageURL.observe updateTextPosition

  return self

identityMap = {}

Member.find = (id) ->
  # Identity map account ids
  identityMap[id] ?= Member
    key: id
