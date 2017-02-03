module.exports = (bus) ->
  logFn = (label) ->
    ->
      bus [label, arguments...]

  self = {}

  ["error", "warn", "debug", "info", "log"].forEach (label) ->
    self[label] = logFn(label)

  return self
