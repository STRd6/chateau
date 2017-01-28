style = document.createElement "style"
style.innerHTML = require("./style")
document.head.appendChild style

Chateau = require "./chateau"

document.body.appendChild Chateau()
