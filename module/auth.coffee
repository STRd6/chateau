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
        stats.increment "connect"
        # TODO: Remove room membership onDisconnect
        # TODO: Update presence

      else
        self.connectionStatus "Disconnected"
        stats.increment "disconnected"

  # Initialize auth state
  initializeAuth = ->
    self.displayModalLoader("Initializing...")

    firebase.auth().onAuthStateChanged (user) ->
      stats.increment "authStateChanged"

      if user
        # User is signed in.
        Modal.hide()

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
