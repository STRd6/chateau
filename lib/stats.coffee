module.exports = ->
  stats = {}

  self =
    increment: (bucket, amount=1) ->
      stats[bucket] ?= 0
      stats[bucket] += amount

    decrement: (bucket, amount=1) ->
      self.increment(bucket, -amount)

    stats: stats

  return self
