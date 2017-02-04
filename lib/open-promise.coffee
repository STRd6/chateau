module.exports = ->
  _resolve = _reject = null
  promise = new Promise (resolve, reject) ->
    _resolve = resolve
    _reject = reject

  promise.resolve = _resolve
  promise.reject = _reject

  return promise
