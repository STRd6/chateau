
module.exports = (I, self) ->
  img = new Image

  if self.attrSync
    self.attrSync "imageURL"
  else
    self.attrObservable "imageURL"

  self.extend
    img: ->
      img

    height: ->
      img.height | 0

    width: ->
      img.width | 0

  # TODO: Cleanly swap image when loaded
  updateImageURL = (url) ->
    if url
      img.src = url

  self.imageURL.observe updateImageURL

  return self
