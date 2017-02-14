module.exports =
  defaults: (target, objects...) ->
    for object in objects
      for name of object
        unless target.hasOwnProperty(name)
          target[name] = object[name]

    return target

  # Get the view associated with a dom element
  # This will let us use the dom tree rather than manage a separate tree
  # to dispatch events at the view level
  # the assumption is that a .view property is written to the root element in the
  # view when rendering a view's template element
  elementView: elementView = (element) ->
    return unless element
    return element.view if element.view
    elementView element.parentElement

  sortBy: (attribute) ->
    (a, b) ->
      a[attribute] - b[attribute]

  timeAgoInWords: (date) ->
    if (typeof date != 'object')
      date = new Date(date)

    seconds = Math.floor((new Date() - date) / 1000)

    minutes = 60
    hours = minutes * 60
    days = hours * 24

    switch
      when seconds < 95
        "a minute ago"
      when seconds < 45 * minutes
        m = Math.round(seconds / minutes)

        "#{m} minutes ago"
      when seconds < 1.25 * hours
        "an hour ago"
      when seconds < 23 * hours
        h = Math.round(seconds / hours)

        "#{h} hours ago"
      when seconds < 1.5 * days
        "yesterday"
      when seconds < 6.45 * days
        d = Math.round(seconds / days)

        "#{d} days ago"
      when seconds < 7.5 * days
        "a week ago"
      else
        "a long time ago"
