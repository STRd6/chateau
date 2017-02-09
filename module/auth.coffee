# Basic Firebase Auth and Presence Mix-in

# We display a modal until the person is authenticated
# then pass control back to the source

# We also set up basic account presence indicators

{Modal, Observable} = UI = require "ui"

LoginTemplate = require("../templates/login")

module.exports = (I, self) ->

  # This always triggers one disconnected if we attach before we are connected
  monitorConnectionStatus = ->
    db.ref(".info/connected").on "value", (snap) ->
      connected = snap.val()

      if connected
        self.connectionStatus "Connected"
        stats.increment "status.connected"
      else
        self.connectionStatus "Disconnected"
        stats.increment "status.disconnected"

  # Initialize auth state
  initializeAuth = ->
    self.displayModalLoader("Initializing...")

    firebase.auth().onAuthStateChanged (user) ->
      stats.increment "auth.state-changed"

      if user
        # User is signed in.
        Modal.hide()

        self.trigger "event", "login"

        self.firebaseUser(user)
      else
        # No user is signed in.
        # Display modal when user is no longer signed in
        loginTemplate = LoginTemplate(self)
        Modal.show loginTemplate,
          cancellable: false

  self.extend
    connectionStatus: Observable "Disconnected" # [Connected, Disconnected]
    firebaseUser: Observable null # The current firebase user
    initializeAuth: initializeAuth

    logout: (e) ->
      e?.preventDefault()

      self.trigger "event", "logout"

      # TODO: Need to update presence when logging out, disconnect stuff doesn't
      # trigger when we just sign out

      firebase.auth().signOut()

    anonLogin: (e) ->
      e.preventDefault()

      firebase.auth().signInAnonymously()

    googleLogin: (e) ->
      e.preventDefault()

      provider = new firebase.auth.GoogleAuthProvider()
      provider.addScope('profile')
      provider.addScope('email')
      firebase.auth().signInWithPopup(provider)

    facebookLogin: (e) ->
      e.preventDefault()

      provider = new firebase.auth.FacebookAuthProvider()
      firebase.auth().signInWithPopup(provider)

    twitterLogin: (e) ->
      e.preventDefault()

      provider = new firebase.auth.TwitterAuthProvider()
      firebase.auth().signInWithPopup(provider)

    githubLogin: (e) ->
      e.preventDefault()

      provider = new firebase.auth.GithubAuthProvider()
      provider.addScope('user:email')
      firebase.auth().signInWithPopup(provider)
