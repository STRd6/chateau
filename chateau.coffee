# Chat Based MUD

ChateauPresenter = require "./presenters/chateau"
Model = require "model"
{Modal, Observable} = UI = require "ui"
Drop = require "./lib/drop"

Auth = require "./module/auth"
Renderer = require "./module/renderer"

shaUpload = require "./sha-upload"

rand = (n) ->
  Math.floor(Math.random() * n)

Member = require "./models/member"
Room = require "./models/room"

Prop = Member

module.exports = (I={}, self=Model(I)) ->

  self.extend
    currentRoom: ->
      Room.find self.currentUser()?.roomId()
    currentUser: Observable null
    avatars: Observable [
      "https://1.pixiecdn.com/sprites/148517/original.png"
      "https://0.pixiecdn.com/sprites/148468/original.png"
      "https://2.pixiecdn.com/sprites/137922/original.png"
      "https://1.pixiecdn.com/sprites/147597/original.png"
      "https://1.pixiecdn.com/sprites/151181/original.png"
      "https://1.pixiecdn.com/sprites/150973/original.png"
      "https://3.pixiecdn.com/sprites/151199/original.png"
      "https://3.pixiecdn.com/sprites/151187/original.png"
      "https://0.pixiecdn.com/sprites/151140/original.png"
      "https://3.pixiecdn.com/sprites/150719/original.png"
      "https://1.pixiecdn.com/sprites/151149/original.png"
      "https://2.pixiecdn.com/sprites/151046/original.png"
    ].map (url) -> avatarURL: url
    rooms: Observable []
    props: Observable [
      "https://1.pixiecdn.com/sprites/151213/original.png"
      "https://3.pixiecdn.com/sprites/151203/original.png"
      "https://0.pixiecdn.com/sprites/148204/original.png"
      "https://1.pixiecdn.com/sprites/148365/original.png"
      "https://2.pixiecdn.com/sprites/148330/original.png"
      "https://1.pixiecdn.com/sprites/148333/original.png"
      "https://1.pixiecdn.com/sprites/148329/original.png"
      "https://1.pixiecdn.com/sprites/137441/original.png"
      "https://0.pixiecdn.com/sprites/137380/original.png"
    ].map (url) -> imageURL: url

    displayModalLoader: (message) ->
      progressView = UI.Progress
        message: message
      Modal.show progressView.element,
        cancellable: false

    accountConnected: (firebaseUser) ->
      unless firebaseUser
        stats.increment "accountDisconnected"
        return

      stats.increment "accountConnected"

      user = Member.find(firebaseUser.uid)
      self.currentUser user

      self.displayModalLoader "Loading..."
      user.connect().then ->
        Modal.hide()

        # Display Avatar Drawer unless user has avatar
        new Promise (resolve, reject) ->
          if user.imageURL()
            resolve()
          else
            self.element.querySelectorAll("tab-drawer > *").forEach (element) ->
              element.classList.remove("show")
            self.element.querySelector("avatar-control").classList.add("show")

            checkForAvatarURL = (value) ->
              if value
                user.imageURL.stopObserving checkForAvatarURL
                resolve()

            user.imageURL.observe checkForAvatarURL
      .then ->
        # Connect to previously connected room
        previousRoom = Room.find(user.roomId())
        if previousRoom
          # Need to force join because currentRoom will be equal to previousRoom
          self.joinRoom previousRoom, true
        else
          # Display Rooms drawer
          self.element.querySelectorAll("tab-drawer > *").forEach (element) ->
            element.classList.remove("show")
          self.element.querySelector("room-control").classList.add("show")

    anonLogin: (e) ->
      e.preventDefault()

      firebase.auth().signInAnonymously()

    googleLogin: (e) ->
      e.preventDefault()

      provider = new firebase.auth.GoogleAuthProvider()
      provider.addScope('profile')
      provider.addScope('email')
      firebase.auth().signInWithPopup(provider)

    createRoom: ->
      Modal.prompt("Room name", "a fun room")
      .then (name) ->
        if name
          db.ref("rooms").push
            name: name

    clearAllProps: ->
      self.currentRoom().clearAllProps()

    addProp: (prop) ->
      stats.increment "prop.add"
      self.currentRoom().addProp prop

    setBackgroundURL: (backgroundURL) ->
      room = self.currentRoom()
      room.imageURL(backgroundURL)
      room.sync()

    setAvatar: (avatarURL) ->
      self.currentUser()
      .update
        imageURL: avatarURL
      .sync()

    joinRoom: (room, force) ->
      if !force and room is self.currentRoom()
        return

      user = self.currentUser()
      accountId = user?.key()
      return unless accountId

      self.currentRoom()?.leave(accountId)
      room.join(accountId)

      user.roomId room.key()
      user.sync()

      return

    saySubmit: (e) ->
      e.preventDefault()

      input = e.currentTarget.querySelector('input')
      words = input.value
      if words
        input.value = ""

        self.currentUser().update
          text: words
        .sync(db)

    words: ->
      self.currentRoom()?.members.map (member) ->
        member.wordElement()

  self.include Renderer
  self.include Auth
  self.initializeAuth()

  do -> # General App Connectivity
    # Populate Rooms list
    db.ref("rooms").on "child_added", (room) ->
      key = room.key
      value = room.val()
  
      delete value.props
  
      stats.increment "rooms.child_added"
      room = Room.find(key).update value
  
      self.rooms.push room

  self.firebaseUser.observe self.accountConnected

  self.element = element = ChateauPresenter self
  Drop element, (e) ->
    files = e.dataTransfer.files

    if files.length
      # TODO: Process multiple files
      file = files[0]

      stats.increment "drop-file"

      shaUpload(firebase, file)
      .then (downloadURL) ->
        Modal.form require("./templates/asset-form")()
        .then (result) ->
          switch result?.selection
            when "avatar"
              self.setAvatar downloadURL

            when "background"
              self.setBackgroundURL downloadURL

  return self
