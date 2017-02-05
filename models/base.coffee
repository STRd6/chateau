Model = require "model"

module.exports = BaseModel = (I={}, self=Model(I)) ->
  defaults I,
    x: 480
    y: 270

  self.attrReader "key", "creatorKey", "roomKey"
  self.attrObservable "type", "content"

  img = new Image

  update = (snap) ->
    self.update snap.val()

  table = db.ref("room-events/#{self.roomKey()}")

# TODO: Work in progress base model for firebase "tables"
# Ideally an ActiveRecord/Backbone type live binding thing
# With just the right amount of magic
BaseModel.create = (tableName) ->
  table = db.ref("#{table-name}")

  (I={}, self=Model(I)) ->
    ref = table.child(self.key())

    # attrSync
    # attrAssociations

    self.extend
      update: (data) ->
        return unless data
        stats.increment "#{tableName}.update"

        Object.keys(data).forEach (key) ->
          self[key]? data[key]

        return self

      sync: ->
        # TODO: Update change props marked sync
        ref.update

    return self
