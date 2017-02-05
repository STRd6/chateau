module.exports =
  defaults: (target, objects...) ->
    for object in objects
      for name of object
        unless target.hasOwnProperty(name)
          target[name] = object[name]

    return target

  sortBy: (attribute) ->
    (a, b) ->
      a[attribute] - b[attribute]
