Firebase
========

Anonymous Sign In
-----------------

    firebase.auth().signInAnonymously()

This signs in anonymously and will keep the account when you return by
persisting data in local storage.

Handling Log In
---------------

Detect when the user has logged in or out and firebase has finished initializing.

    firebase.auth().onAuthStateChanged (user) ->
      if user
        # User is signed in.
      else
        # No user is signed in.
