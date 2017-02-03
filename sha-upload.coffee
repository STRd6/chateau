UI = require "ui"
require "./extensions"

{Modal, Progress} = UI

# Upload to firebase storage based on SHA256 of file
module.exports = (firebase, file) ->
  file.readAsArrayBuffer()
  .then (buffer) ->
    crypto.subtle.digest("SHA-256", buffer)
  .then hex
  .then (sha) ->
    console.log sha

    new Promise (resolve, reject) ->
      # Upload to CDN
      ref = firebase.storage().ref(sha)
      uploadTask = ref.put file

      progressView = Progress
        value: 0
        max: 1

      Modal.show progressView.element,
        cancellable: false

      uploadTask.on 'state_changed', (snapshot) ->
        progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;

        progressView.value progress

      , (error) ->
        # Handle unsuccessful uploads
        Modal.hide()
        reject(error)
      , () ->
        # Handle successful uploads on complete
        # For instance, get the download URL: https://firebasestorage.googleapis.com/...
        Modal.hide()

        resolve(uploadTask.snapshot.downloadURL)

hex = (buffer) ->
  buffer = new Uint8Array(buffer)

  Array::map.call buffer, (x) ->
    ('00' + x.toString(16)).slice(-2)
  .join('')
