Chateau = require "./chateau"

if PACKAGE.name is "ROOT"
  require("analytics").init("UA-3464282-15")

  {Style} = require "ui"
  style = document.createElement "style"
  style.innerHTML = Style.all + "\n" + require("./style")
  document.head.appendChild style

  # Initialize Firebase
  firebase.initializeApp
    apiKey: "AIzaSyCnhTPOri3XGQ0q5pw0u8dRPZQwr74fpuw"
    authDomain: "chateau-f2799.firebaseapp.com"
    databaseURL: "https://chateau-f2799.firebaseio.com"
    storageBucket: "chateau-f2799.appspot.com"
    messagingSenderId: "2073045470"

  global.logger = require("./lib/logger")(console.log)
  global.stats = require("./lib/stats")()
  global.firebase = firebase
  global.db = firebase.database()
  db.TIMESTAMP = firebase.database.ServerValue.TIMESTAMP
  global.defaults = require("./util").defaults
  global.chateau = Chateau()

  document.body.appendChild chateau.element

  document.body.appendChild require("./lib/feedback-tab")("https://docs.google.com/forms/d/e/1FAIpQLScMur8T8VcgWGk0k-sFkNRmCiDGWAzTRTLICUC0v-W2J7rJKQ/viewform")
else
  module.exports = Chateau
