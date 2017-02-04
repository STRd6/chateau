
module.exports = (I, self) ->
  img = new Image

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
