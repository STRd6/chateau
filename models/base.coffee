# Base model generator
#
# Generates a model whose instances can sync and track changes in firebase

OpenPromise = require "../lib/open-promise"

Model = require "model"

module.exports = (tableName, Mixin) ->
  ModelConstructor = (I={}, self=Model(I)) ->
    self.attrReader "key"

    table = db.ref(tableName)
    ref = table.child(self.key())

    syncAttributes = []

    self.extend
      # List attributes to keep in sync
      attrSync: (names...) ->
        self.attrObservable names...

        syncAttributes = syncAttributes.concat names
      
      # TODO: Currently only using this to track when the current user
      # has refreshed from firebase
      connect: ->
        return connectedPromise

      # Stop tracking updates from the server
      disconnect: ->
        stats.increment "#{tableName}.disconnect"
        ref.off "value", update

      # Update our state to match the given data
      update: (data) ->
        return unless data
        stats.increment "#{tableName}.update"

        Object.keys(data).forEach (key) ->
          self[key]? data[key]

        return self

      ref: ->
        ref

      # Sync our local state to the server
      # TODO: success/fail promise?
      sync: ->
        stats.increment "#{tableName}.sync"

        # TODO: Only send changed
        data = syncAttributes.reduce (memo, name) ->
          memo[name] = self[name]()

          return memo
        , {}

        ref.update data

    self.include Mixin

    # Track all server updates
    # TODO: Fine grained tracking control
    connectedPromise = OpenPromise()
    update = (snap) ->
      connectedPromise.resolve() # TODO: Rethink this
      self.update snap.val()
    ref.on "value", update

    return self

  # Add class methods on the constructor
  identityMap = {}
  # Use an identity map to return the same instances for the same key
  # TODO: Allow for initializing with data
  ModelConstructor.find = (key) ->
    # Identity map instances by key
    identityMap[key] ?= ModelConstructor
      key: key

  ModelConstructor.fromSnap = (snap) ->
    key = snap.key
    data = snap.val()

    model = ModelConstructor.find(key)
    model.update(data)

    return model

  return ModelConstructor
