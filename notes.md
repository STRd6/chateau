Firebase
========

Anonymous Sign In
-----------------

    firebase.auth().signInAnonymously()

This signs in anonymously and will keep the account when you return by
persisting data in local storage.

Caveat: If you call this before firebase is fully initialized it may generate a
new anonymous account instead of reusing the existing one.

Push Key Uniqueness
-------------------

Push keys are unique enough to be considered globally unique.

http://stackoverflow.com/a/38498220/68210

Sorting, Filtering, Pagination
------------------------------

TODO: Get a good handle on this.

Syncing Models
--------------

There's some nuance to syncing only the minimal amount of live data with models,
especially with compositions.

TODO: Concrete examples and cookbook.

Shallow Data
------------

In order to scope syncing, security rules, limit unnecessary data in queries,
making many shallow compositions related by a shared key is the recommended way.

TODO: Examples and cookbook


Handling Log In
---------------

Detect when the user has logged in or out and firebase has finished initializing.

    firebase.auth().onAuthStateChanged (user) ->
      if user
        # User is signed in.
      else
        # No user is signed in.

FAQ
---

`ref.on` is not working... make sure you've set ".read" permission in the
security rules ya dummy!