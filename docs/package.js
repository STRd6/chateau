(function(pkg) {
  (function() {
  var annotateSourceURL, cacheFor, circularGuard, defaultEntryPoint, fileSeparator, generateRequireFn, global, isPackage, loadModule, loadPackage, loadPath, normalizePath, publicAPI, rootModule, startsWith,
    __slice = [].slice;

  fileSeparator = '/';

  global = self;

  defaultEntryPoint = "main";

  circularGuard = {};

  rootModule = {
    path: ""
  };

  loadPath = function(parentModule, pkg, path) {
    var cache, localPath, module, normalizedPath;
    if (startsWith(path, '/')) {
      localPath = [];
    } else {
      localPath = parentModule.path.split(fileSeparator);
    }
    normalizedPath = normalizePath(path, localPath);
    cache = cacheFor(pkg);
    if (module = cache[normalizedPath]) {
      if (module === circularGuard) {
        throw "Circular dependency detected when requiring " + normalizedPath;
      }
    } else {
      cache[normalizedPath] = circularGuard;
      try {
        cache[normalizedPath] = module = loadModule(pkg, normalizedPath);
      } finally {
        if (cache[normalizedPath] === circularGuard) {
          delete cache[normalizedPath];
        }
      }
    }
    return module.exports;
  };

  normalizePath = function(path, base) {
    var piece, result;
    if (base == null) {
      base = [];
    }
    base = base.concat(path.split(fileSeparator));
    result = [];
    while (base.length) {
      switch (piece = base.shift()) {
        case "..":
          result.pop();
          break;
        case "":
        case ".":
          break;
        default:
          result.push(piece);
      }
    }
    return result.join(fileSeparator);
  };

  loadPackage = function(pkg) {
    var path;
    path = pkg.entryPoint || defaultEntryPoint;
    return loadPath(rootModule, pkg, path);
  };

  loadModule = function(pkg, path) {
    var args, content, context, dirname, file, module, program, values;
    if (!(file = pkg.distribution[path])) {
      throw "Could not find file at " + path + " in " + pkg.name;
    }
    if ((content = file.content) == null) {
      throw "Malformed package. No content for file at " + path + " in " + pkg.name;
    }
    program = annotateSourceURL(content, pkg, path);
    dirname = path.split(fileSeparator).slice(0, -1).join(fileSeparator);
    module = {
      path: dirname,
      exports: {}
    };
    context = {
      require: generateRequireFn(pkg, module),
      global: global,
      module: module,
      exports: module.exports,
      PACKAGE: pkg,
      __filename: path,
      __dirname: dirname
    };
    args = Object.keys(context);
    values = args.map(function(name) {
      return context[name];
    });
    Function.apply(null, __slice.call(args).concat([program])).apply(module, values);
    return module;
  };

  isPackage = function(path) {
    if (!(startsWith(path, fileSeparator) || startsWith(path, "." + fileSeparator) || startsWith(path, ".." + fileSeparator))) {
      return path.split(fileSeparator)[0];
    } else {
      return false;
    }
  };

  generateRequireFn = function(pkg, module) {
    var fn;
    if (module == null) {
      module = rootModule;
    }
    if (pkg.name == null) {
      pkg.name = "ROOT";
    }
    if (pkg.scopedName == null) {
      pkg.scopedName = "ROOT";
    }
    fn = function(path) {
      var otherPackage;
      if (typeof path === "object") {
        return loadPackage(path);
      } else if (isPackage(path)) {
        if (!(otherPackage = pkg.dependencies[path])) {
          throw "Package: " + path + " not found.";
        }
        if (otherPackage.name == null) {
          otherPackage.name = path;
        }
        if (otherPackage.scopedName == null) {
          otherPackage.scopedName = "" + pkg.scopedName + ":" + path;
        }
        return loadPackage(otherPackage);
      } else {
        return loadPath(module, pkg, path);
      }
    };
    fn.packageWrapper = publicAPI.packageWrapper;
    fn.executePackageWrapper = publicAPI.executePackageWrapper;
    return fn;
  };

  publicAPI = {
    generateFor: generateRequireFn,
    packageWrapper: function(pkg, code) {
      return ";(function(PACKAGE) {\n  var src = " + (JSON.stringify(PACKAGE.distribution.main.content)) + ";\n  var Require = new Function(\"PACKAGE\", \"return \" + src)({distribution: {main: {content: src}}});\n  var require = Require.generateFor(PACKAGE);\n  " + code + ";\n})(" + (JSON.stringify(pkg, null, 2)) + ");";
    },
    executePackageWrapper: function(pkg) {
      return publicAPI.packageWrapper(pkg, "require('./" + pkg.entryPoint + "')");
    },
    loadPackage: loadPackage
  };

  if (typeof exports !== "undefined" && exports !== null) {
    module.exports = publicAPI;
  } else {
    global.Require = publicAPI;
  }

  startsWith = function(string, prefix) {
    return string.lastIndexOf(prefix, 0) === 0;
  };

  cacheFor = function(pkg) {
    if (pkg.cache) {
      return pkg.cache;
    }
    Object.defineProperty(pkg, "cache", {
      value: {}
    });
    return pkg.cache;
  };

  annotateSourceURL = function(program, pkg, path) {
    return "" + program + "\n//# sourceURL=" + pkg.scopedName + "/" + path;
  };

  return publicAPI;

}).call(this);

  window.require = Require.generateFor(pkg);
})({
  "source": {
    "LICENSE": {
      "path": "LICENSE",
      "content": "MIT License\n\nCopyright (c) 2017 Daniel X Moore\n\nPermission is hereby granted, free of charge, to any person obtaining a copy\nof this software and associated documentation files (the \"Software\"), to deal\nin the Software without restriction, including without limitation the rights\nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the Software is\nfurnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all\ncopies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\nSOFTWARE.\n",
      "mode": "100644",
      "type": "blob"
    },
    "README.md": {
      "path": "README.md",
      "content": "# chateau\nRemake of thepalace.com\n",
      "mode": "100644",
      "type": "blob"
    },
    "main.coffee": {
      "path": "main.coffee",
      "content": "style = document.createElement \"style\"\nstyle.innerHTML = require(\"./style\")\ndocument.head.appendChild style\n\nChateau = require \"./chateau\"\n\ndocument.body.appendChild Chateau()\n",
      "mode": "100644"
    },
    "lib/drop.coffee": {
      "path": "lib/drop.coffee",
      "content": "module.exports = (element, handler) ->\n  cancel = (e) ->\n    e.preventDefault()\n    return false\n\n  element.addEventListener \"dragover\", cancel\n  element.addEventListener \"dragenter\", cancel\n  element.addEventListener \"drop\", (e) ->\n    e.preventDefault()\n    handler(e)\n    return false\n",
      "mode": "100644"
    },
    "chateau.coffee": {
      "path": "chateau.coffee",
      "content": "# Chat Based MUD\n\nDrop = require \"./lib/drop\"\n\nsortBy = (attribute) ->\n  (a, b) ->\n    a[attribute] - b[attribute]\n\nrand = (n) ->\n  Math.floor(Math.random() * n)\n\nmodule.exports = ->\n  canvas = document.createElement 'canvas'\n  canvas.width = 960\n  canvas.height = 540\n\n  context = canvas.getContext('2d')\n\n  repaint = ->\n    # Draw BG\n    context.fillStyle = 'blue'\n    context.fillRect(0, 0, canvas.width, canvas.height)\n\n    return\n\n    {background, objects} = roomstate\n    if background\n      context.drawImage(background, 0, 0, canvas.width, canvas.height)\n\n    # Draw Avatars/Objects\n    Object.keys(avatars).map (accountId) ->\n      avatars[accountId]\n    .concat(objects).sort(sortBy(\"z\")).forEach ({color, img, x, y}) ->\n      if img\n        {width, height} = img\n        context.drawImage(img, x - width / 2, y - height / 2)\n      else\n        context.fillStyle = color\n        context.fillRect(x - 25, y - 25, 50, 50)\n\n    # Draw connection status\n    if connected()\n      indicatorColor = \"green\"\n    else\n      indicatorColor = \"red\"\n\n    context.beginPath()\n    context.arc(canvas.width - 20, 20, 10, 0, 2 * Math.PI, false)\n    context.fillStyle = indicatorColor\n    context.fill()\n    context.lineWidth = 2\n    context.strokeStyle = '#003300'\n    context.stroke()\n\n  resize = ->\n    rect = canvas.getBoundingClientRect()\n    canvas.width = rect.width\n    canvas.height = rect.height\n\n  animate = ->\n    requestAnimationFrame animate\n    repaint()\n\n  animate()\n\n  # TODO: ViewDidLoad? or equivalent event?\n  setTimeout ->\n    resize()\n\n  return canvas\n",
      "mode": "100644"
    },
    "pixie.cson": {
      "path": "pixie.cson",
      "content": "\nwidth: 960\nheight: 540\n",
      "mode": "100644"
    },
    "style.styl": {
      "path": "style.styl",
      "content": "*\n  box-sizing: border-box\n\nhtml, body\n  height: 100%\n\nbody\n  display: flex\n  margin: 0\n  overflow: hidden\n\n  > canvas\n    flex: 0 0 auto\n    margin: auto\n",
      "mode": "100644"
    }
  },
  "distribution": {
    "main": {
      "path": "main",
      "content": "(function() {\n  var Chateau, style;\n\n  style = document.createElement(\"style\");\n\n  style.innerHTML = require(\"./style\");\n\n  document.head.appendChild(style);\n\n  Chateau = require(\"./chateau\");\n\n  document.body.appendChild(Chateau());\n\n}).call(this);\n",
      "type": "blob"
    },
    "lib/drop": {
      "path": "lib/drop",
      "content": "(function() {\n  module.exports = function(element, handler) {\n    var cancel;\n    cancel = function(e) {\n      e.preventDefault();\n      return false;\n    };\n    element.addEventListener(\"dragover\", cancel);\n    element.addEventListener(\"dragenter\", cancel);\n    return element.addEventListener(\"drop\", function(e) {\n      e.preventDefault();\n      handler(e);\n      return false;\n    });\n  };\n\n}).call(this);\n",
      "type": "blob"
    },
    "chateau": {
      "path": "chateau",
      "content": "(function() {\n  var Drop, rand, sortBy;\n\n  Drop = require(\"./lib/drop\");\n\n  sortBy = function(attribute) {\n    return function(a, b) {\n      return a[attribute] - b[attribute];\n    };\n  };\n\n  rand = function(n) {\n    return Math.floor(Math.random() * n);\n  };\n\n  module.exports = function() {\n    var animate, canvas, context, repaint, resize;\n    canvas = document.createElement('canvas');\n    canvas.width = 960;\n    canvas.height = 540;\n    context = canvas.getContext('2d');\n    repaint = function() {\n      var background, indicatorColor, objects;\n      context.fillStyle = 'blue';\n      context.fillRect(0, 0, canvas.width, canvas.height);\n      return;\n      background = roomstate.background, objects = roomstate.objects;\n      if (background) {\n        context.drawImage(background, 0, 0, canvas.width, canvas.height);\n      }\n      Object.keys(avatars).map(function(accountId) {\n        return avatars[accountId];\n      }).concat(objects).sort(sortBy(\"z\")).forEach(function(_arg) {\n        var color, height, img, width, x, y;\n        color = _arg.color, img = _arg.img, x = _arg.x, y = _arg.y;\n        if (img) {\n          width = img.width, height = img.height;\n          return context.drawImage(img, x - width / 2, y - height / 2);\n        } else {\n          context.fillStyle = color;\n          return context.fillRect(x - 25, y - 25, 50, 50);\n        }\n      });\n      if (connected()) {\n        indicatorColor = \"green\";\n      } else {\n        indicatorColor = \"red\";\n      }\n      context.beginPath();\n      context.arc(canvas.width - 20, 20, 10, 0, 2 * Math.PI, false);\n      context.fillStyle = indicatorColor;\n      context.fill();\n      context.lineWidth = 2;\n      context.strokeStyle = '#003300';\n      return context.stroke();\n    };\n    resize = function() {\n      var rect;\n      rect = canvas.getBoundingClientRect();\n      canvas.width = rect.width;\n      return canvas.height = rect.height;\n    };\n    animate = function() {\n      requestAnimationFrame(animate);\n      return repaint();\n    };\n    animate();\n    setTimeout(function() {\n      return resize();\n    });\n    return canvas;\n  };\n\n}).call(this);\n",
      "type": "blob"
    },
    "pixie": {
      "path": "pixie",
      "content": "module.exports = {\"width\":960,\"height\":540};",
      "type": "blob"
    },
    "style": {
      "path": "style",
      "content": "module.exports = \"* {\\n  box-sizing: border-box;\\n}\\nhtml,\\nbody {\\n  height: 100%;\\n}\\nbody {\\n  display: flex;\\n  margin: 0;\\n  overflow: hidden;\\n}\\nbody > canvas {\\n  flex: 0 0 auto;\\n  margin: auto;\\n}\\n\";",
      "type": "blob"
    }
  },
  "progenitor": {
    "url": "https://danielx.net/editor/"
  },
  "config": {
    "width": 960,
    "height": 540
  },
  "entryPoint": "main",
  "repository": {
    "branch": "master",
    "default_branch": "master",
    "full_name": "STRd6/chateau",
    "homepage": null,
    "description": "Remake of thepalace.com",
    "html_url": "https://github.com/STRd6/chateau",
    "url": "https://api.github.com/repos/STRd6/chateau",
    "publishBranch": "gh-pages"
  },
  "dependencies": {}
});