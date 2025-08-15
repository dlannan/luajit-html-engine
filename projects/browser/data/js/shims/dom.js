
// ----------------------- NODE/ELEMENT -------------------
function Node() {
    this.children = [];
    this.appendChild = function(child) {
        this.children.push(child);
        // You could proxy this to Lua:
        // LuaBridge.appendChild(this, child);
    };
    this.removeChild = function(child) {
        var newChildren = [];
        for (var i = 0; i < this.children.length; i++) {
            if (this.children[i] !== child) {
                newChildren.push(this.children[i]);
            }
        }
        this.children = newChildren;
    };
}

function Element(tagName) {
    this.tagName = tagName.toUpperCase();
    this.children = [];
    this.attributes = {};
    this.style = {};
    this.classList = {
        classes: [],
        add: function(cls) {
            this.classes.push(cls);
        },
        remove: function(cls) {
            var newClasses = [];
            for (var i = 0; i < this.classes.length; i++) {
                if (this.classes[i] !== cls) {
                    newClasses.push(this.classes[i]);
                }
            }
            this.classes = newClasses;
        },
        contains: function(cls) {
            for (var i = 0; i < this.classes.length; i++) {
                if (this.classes[i] === cls) {
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
    this.setAttribute = function(name, value) {
        this.attributes[name] = value;
        // Optionally notify Lua
    };
    this.getAttribute = function(name) {
        return this.attributes[name] || null;
    };
    this.appendChild = function(child) {
        this.children.push(child);
        // You could proxy this to Lua:
        // LuaBridge.appendChild(this, child);
    };
    this.removeChild = function(child) {
        var newChildren = [];
        for (var i = 0; i < this.children.length; i++) {
            if (this.children[i] !== child) {
                newChildren.push(this.children[i]);
            }
        }
        this.children = newChildren;
    };
    this.innerHTML = ""; // jQuery looks at this
    // if (this.tagName === 'A' || this.tagName === 'LINK' || this.tagName === 'AREA') {
        this.href = "";
    // }
}

// ---------------------------- DOCUMENT -------------------
function Document() {
    this.nodeType = 9; // DOCUMENT_NODE
    this.nodeName = "#document";
    this.children = [];

    this.appendChild = function(child) {
        this.children.push(child);
        // You could proxy this to Lua:
        // LuaBridge.appendChild(this, child);
    };
    this.removeChild = function(child) {
        var newChildren = [];
        for (var i = 0; i < this.children.length; i++) {
            if (this.children[i] !== child) {
                newChildren.push(this.children[i]);
            }
        }
        this.children = newChildren;
    };
}

Document.prototype = Object.create(Node.prototype);
Document.prototype.constructor = Document;

var document = new Document();
var window = this;
window.location = { href: "" };

document.createElement = function(tagName) {
    return new Element(tagName);
};
document.getElementById = function(id) {
    // Implement using your Lua document model (optional)
    return null;
};
document.getElementsByTagName = function(tag) {
    return []; // stub
};
document.querySelector = function(sel) {
    return null; // stub
};
document.querySelectorAll = function(sel) {
    return []; // stub
};
document.addEventListener = function(type, cb) {
    // Handle DOMContentLoaded etc.
    if (type === "DOMContentLoaded") {
        cb(); // trigger immediately for now
    }
};

document.readyState = "complete";
document.location = window.location;

// === Root Elements ===
// Create the <html> root and <body>
document.documentElement = new Element("html");
document.body = new Element("body");
document.documentElement.appendChild(document.body);
document.appendChild(document.documentElement);

document.createEvent = function(type) {
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

// ---------------------------- WINDOW -------------------

window.document = document;

window.getComputedStyle = function(elem) {
    return {
        getPropertyValue: function(prop) {
            // Return empty string or some defaults as needed
            return "";
        }
    };
};

window.HTMLElement = new Element("html");
window.Node = new Node();

Element.prototype.dispatchEvent = function(event) {
    var handler = this['on' + event.type];
    if (typeof handler === 'function') {
        handler.call(this, event);
    }
};

// ---------------------------- EVENT ---------------------
function Event(type, init) {
    this.type = type;
    this.target = null;
    this.srcElement = null;
    this.currentTarget = null;
}
window.Event = Event;


// ---------------------------- LUA BRIDGE -------------------
window.LuaBridge = {
    log: function(msg) {
        // Hook to Lua print/log
    },
    // Define Lua-side proxies for DOM ops
    // createElement, appendChild, etc
};   


// ---------------------------------------------------

// Calls back to lua, to say the JS has a fake dom ready to use
lj_shimdone( new Date().getTime() );

// ---------------------------------------------------