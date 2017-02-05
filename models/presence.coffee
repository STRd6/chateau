# Presence
#
# Stored at presence/$uid
#
# Tracks user's online/offline status, status message, and lastSeen time

Base = require "./base"

module.exports = Base "presence", (I={}, self=Model(I)) ->
  self.attrSync "online", "lastSeen", "status"

  return self
