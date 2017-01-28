Chateau = require "./chateau"
  
if PACKAGE.name is "ROOT"
  style = document.createElement "style"
  style.innerHTML = require("./style")
  document.head.appendChild style

  global.firebase = firebase

  # Initialize Firebase
  firebase.initializeApp
    apiKey: "AIzaSyCnhTPOri3XGQ0q5pw0u8dRPZQwr74fpuw"
    authDomain: "chateau-f2799.firebaseapp.com"
    databaseURL: "https://chateau-f2799.firebaseio.com"
    storageBucket: "chateau-f2799.appspot.com"
    messagingSenderId: "2073045470"

  document.body.appendChild Chateau(firebase).element
else
  module.exports = Chateau
