
// ----------------------- Cache -------------------

var _cache     = [];

// ----------------------- NODE -------------------
// New Node mapped to Luajit side
function Node(luaNodeId) {
    this.children = [];
    this.luaNodeId = luaNodeId; // link to Lua-side DOM node
}

Node.prototype.appendChild = function(child) {
    // Update JS proxy children for local consistency
    this.children.push(child);

    // Proxy call to Lua to update the real DOM tree
    dt_appendChild( this.luaNodeId, child.luaNodeId );
};

Node.prototype.removeChild = function(child) {
    var newChildren = [];
    for (var i = 0; i < this.children.length; i++) {
        if (this.children[i] !== child) {
            newChildren.push(this.children[i]);
        }
    }
    this.children = newChildren;

    // Proxy call to Lua to update the real DOM tree
    dt_removeChild( this.luaNodeId, child.luaNodeId );
};

Node.prototype.contains = function(node) {
    if (!node) return false;
    var current = node;
    while (current) {
        if (current === this) {
            return true;
        }
        current = current.parentNode;
    }
    return false;
};

function createNode(nodeName) {
    var luaNodeId = dt_createNode(nodeName);
    return new Node(luaNodeId);
}

// ----------------------- ELEMENT -------------------

function Element(tagName) {
    if (!tagName) tagName = "unknown";

    this.luaNodeId = dt_createElement(tagName); // Call Lua to create the element

    this.tagName = tagName.toUpperCase();
    this.children = [];
    //this.attributes = {}; // Cache for JS side
    // this.style = {}; // Optional; could proxy to Lua
    this._innerHTML = "";

    var self = this;

    Object.defineProperty(this, 'innerHTML', {
        get: function () {
            this._innerHTML = dt_getTextContent(this.luaNodeId);
            return this._textContent;
        },
        set: function (value) {
            print("textContent set called with" + value);
            this._innerHTML = value;
            dt_setTextContent(this.luaNodeId, value);
        },
        enumerable: true,
        configurable: true
    });
      

    // classList implementation (ES5-safe)
    this.classList = {
        classes: [],

        add: function(cls) {
            if (self.classList.classes.indexOf(cls) === -1) {
                self.classList.classes.push(cls);
                dt_classListAdd(self.luaNodeId, cls);
            }
        },

        remove: function(cls) {
            var newClasses = [];
            for (var i = 0; i < self.classList.classes.length; i++) {
                if (self.classList.classes[i] !== cls) {
                    newClasses.push(self.classList.classes[i]);
                }
            }
            self.classList.classes = newClasses;
            dt_classListRemove(self.luaNodeId, cls);
        },

        contains: function(cls) {
            for (var i = 0; i < self.classList.classes.length; i++) {
                if (self.classList.classes[i] === cls) {
                    return true;
                }
            }
            return false;
        }
    };

    this.addEventListener = function(type, callback) {
        // Hook to Lua here if desired
        if (!this._listeners) this._listeners = {};
        if (!this._listeners[type]) this._listeners[type] = [];
        this._listeners[type].push(callback);
    };    

    this.removeEventListener = function(type, callback) {
        if (this._listeners && this._listeners[type]) {
            var newList = [];
            for (var i = 0; i < this._listeners[type].length; i++) {
                if (this._listeners[type][i] !== callback) {
                    newList.push(this._listeners[type][i]);
                }
            }
            this._listeners[type] = newList;
        }
    };
    this.dispatchEvent = function(event) {
        if (this._listeners && this._listeners[event.type]) {
            var listeners = this._listeners[event.type];
            for (var i = 0; i < listeners.length; i++) {
                listeners[i].call(this, event);
            }
        }
    };        

    if (this.tagName === 'A' || this.tagName === 'LINK' || this.tagName === 'AREA') {
        this.href = "";
    }

    _cache.push(this);
}

// Prototype methods
Element.prototype.setAttribute = function(name, value) {
    // this.attributes[name] = value;
    dt_setAttribute(this.luaNodeId, name, value);
};

Element.prototype.getAttribute = function(name) {
    // Note: if you want to force always asking Lua, remove the cache
    // if (this.attributes.hasOwnProperty(name)) {
        // return this.attributes[name];
    // }
    return dt_getAttribute(this.luaNodeId, name);
};

Element.prototype.appendChild = function(child) {

    this.children.push(child);
    dt_appendChild(this.luaNodeId, child.luaNodeId);
};

Element.prototype.removeChild = function(child) {
    var newChildren = [];
    for (var i = 0; i < this.children.length; i++) {
        if (this.children[i] !== child) {
            newChildren.push(this.children[i]);
        }
    }
    this.children = newChildren;
    dt_removeChild(this.luaNodeId, child.luaNodeId);
};

// ---------------------------- DOCUMENT -------------------

function Document() {

    var node = createNode("#document"); // this tells LuaJIT to create the node
    this.luaNodeId = node.luaNodeId;
    this.nodeType = 9; // DOCUMENT_NODE
    this.nodeName = "#document";
    this.children = node.children;

    this.appendChild = node.appendChild;

    this.removeChild = node.removeChild;

    this.createElement = function(tagName) {
        return new Element(tagName); // This will proxy to Lua inside Element constructor
    };

    this.createTextNode = function(text) {
        var textnode = new Element("text");
        textnode.innerHTML = text;
        return textnode;
    };

    this.getElementById = function(id) {
        for (var i = 0; i < _cache.length; i++) {
            if (_cache[i].getAttribute && _cache[i].getAttribute("id") === id) {
                return _cache[i];
            }
        }
        return null;
    };

    this.getElementsByTagName = function(tag) {
        var results = [];
        for (var i = 0; i < _cache.length; i++) {
            if (_cache[i].tagName === tag.toUpperCase()) {
                results.push(_cache[i]);
            }
        }
        return results;
    };

    this.querySelector = function(sel) {
        // Minimal stub: return first element with tag match
        var parts = sel.split(' ');
        var tag = parts[parts.length - 1];
        var elements = this.getElementsByTagName(tag);
        return elements.length > 0 ? elements[0] : null;
    };

    this.querySelectorAll = function(sel) {
        // Minimal stub: return all matching tag elements
        var parts = sel.split(' ');
        var tag = parts[parts.length - 1];
        return this.getElementsByTagName(tag);
    };

    this.addEventListener = function(type, cb) {
        // Support for DOMContentLoaded (simplified)
        if (type === "DOMContentLoaded") {
            cb();
        }
    };

    this.createEvent = function(type) {
        return {
            type: null,
            bubbles: false,
            cancelable: false,
            initEvent: function(eventType, bubbles, cancelable) {
                this.type = eventType;
                this.bubbles = bubbles;
                this.cancelable = cancelable;
            }
        };
    };

    this.readyState = "complete";
    this.location = { href: "" };
}

// ---------------------------- PATCHES -------------------

Element.prototype.contains = Node.prototype.contains;
Document.prototype.contains = Node.prototype.contains;

Document.prototype = Object.create(Node.prototype);
Document.prototype.constructor = Document;

// ---------------------------- WINDOW -------------------
// Safe window reference
var document = new Document();
var window = this;

// Attach document (make sure `document` is already defined)
window.document = document;
window.location = { href: "" };

// === Root Elements ===
// Create the <html> root and <body>
document.documentElement = new Element("html");
document.body = new Element("body");
document.documentElement.appendChild(document.body);
document.appendChild(document.documentElement);

// Basic getComputedStyle stub
window.getComputedStyle = function(elem) {
    return {
        getPropertyValue: function(prop) {
            // Return empty string or defaults if needed
            return "";
        }
    };
};

// Assign to global window scope (Zepto may check for these)
window.Node = Node;
window.HTMLElement = Element; // Make Element act as HTMLElement

// Event system (basic)
function Event(type, init) {
    this.type = type;
    this.bubbles = init && init.bubbles || false;
    this.cancelable = init && init.cancelable || false;
    this.target = null;
    this.srcElement = null;
    this.currentTarget = null;
    this.defaultPrevented = false;
}

Event.prototype.preventDefault = function() {
    this.defaultPrevented = true;
};

Event.prototype.stopPropagation = function() {
    // no-op stub
};

window.Event = Event;

// Patch Element to support event dispatching
Element.prototype.dispatchEvent = function(event) {
    event.target = this;
    event.currentTarget = this;

    var handler = this['on' + event.type];
    if (typeof handler === 'function') {
        handler.call(this, event);
    }

    // You could also support listeners array like:
    // if (this._listeners && this._listeners[event.type]) { ... }
};

// ---------------------------------------------------

// Calls back to lua, to say the JS has a fake dom ready to use
lj_shimdone( new Date().getTime() );

// ---------------------------------------------------