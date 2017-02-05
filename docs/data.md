Data
----

    Members members/$account_uid
      name : Display Name
      imageURL
      roomKey : room key of currentRoom
      saying : current voice bubble
      x : x coordinate in room
      y : y coordinate in room

    Presence presence/$account_uid
      online :
      lastSeen :
      status :

    Rooms rooms/$room_key
      name : Room name
      imageURL
      owner : the creator of the room
      public : whether the room is public to all or private

    room-data/$key/memberships[] : shallow list of member keys
    room-data/$key/props[] : complete props data
    room-data/$key/events[] : complete events log
      source : account_id
      type : [speak, emote]
      content : type dependent

Later... scripts, complex objects, animations. Props can reference animations
and scripts to gain advanced behaviors.
