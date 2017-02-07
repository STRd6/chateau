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
