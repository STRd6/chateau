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

Data
----

    Accounts
      avatarURL
      room : room id
      saying : current voice bubble
      x : x coordinate in room
      y : y coordinate in room

    Rooms
      name : Room name
      backgroundURL
      members : list of account ids
      objects : list of objects in room
      owner : the creator of the room
      public : whether the room is public to all or private
