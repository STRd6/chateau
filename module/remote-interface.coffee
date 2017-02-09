Postmaster = require "postmaster"

# Mixin to attach postmaster and whitelist methods to expose to the remote interface
module.exports = (I, self) ->
  postmaster = Postmaster()

  self.extend
    # Expose methods on self to be able to be invoked remotely
    # Each method named is added to postmaster to proxy directly to our 'self'
    # method with the same name
    allowRemote: (methodNames...) ->
      methodNames.forEach (name) ->
        postmaster[name] = ->
          self[name](arguments...)

    # Invoke a method in the remote handler
    # do nothing if no remote target
    invokeRemote: ->
      stats.increment "remote-interface.no-target"
      return unless self.remoteTarget()

      postmaster.invokeRemote(arguments...)
      .catch (e) ->
        if e.message.match /No ack/
          stats.increment "remote-interface.timeout"
        else
          stats.increment "remote-interface.error"

        throw e

    # Expose the raw postmaster object for low level manipulation
    postmaster: ->
      postmaster

    # The remote target (parent page) if it exists or undefined
    remoteTarget: postmaster.remoteTarget

  return self
