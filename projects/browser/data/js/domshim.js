// === Globals ===
var window = this;
var document = {};

// ---------------------------- WINDOW -------------------

window.document = document;
window.location = { href: "" };

window.getComputedStyle = function(elem) {
    return {
        getPropertyValue: function(prop) {
            // Return empty string or some defaults as needed
            return "";
        }
    };
};


// ---------------------------- EVENT ---------------------
function Event(type) {
    this.type = type;
    this.target = null;
}
window.Event = Event;

// ----------------------- NODE/ELEMENT -------------------
function Node() {}

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

Element.prototype = new Node();
window.HTMLElement = Element;
window.Node = Node;

// ---------------------------- DOCUMENT -------------------

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
document.body = new Element("body");
document.documentElement = new Element("html");

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

Element.prototype.dispatchEvent = function(event) {
    var handler = this['on' + event.type];
    if (typeof handler === 'function') {
        handler.call(this, event);
    }
};

// ---------------------------- LUA BRIDGE -------------------
window.LuaBridge = {
    log: function(msg) {
        // Hook to Lua print/log
    },
    // Define Lua-side proxies for DOM ops
    // createElement, appendChild, etc
};   

// ---------------------------- TIMERS -------------------
(function() {
    var _nextTimerId = 1;
    var _timers = {};

    function now() {
        return new Date().getTime();
    }

    // function runTimers() {
    //     var time = now();
    //     for (var id in _timers) {
    //         var t = _timers[id];
    //         if (t && time >= t.time) {
    //             try {
    //                 t.fn();
    //             } catch (e) {
    //                 print("Timer error: " + e);
    //             }

    //             if (t.repeat) {
    //                 t.time = time + t.delay;
    //             } else {
    //                 delete _timers[id];
    //             }
    //         }
    //     }
    // }


    function updateTimer(id) {
        var t = _timers[id];
        if (t) {
            try {
                t.fn();
            } catch (e) {
                print("Timer error: " + e);
            }

            if (t.repeat) {
                t.time = now() + t.delay;
                lj_reptimer(id, t.time);
            } else {
                delete _timers[id];
                lj_deltimer(id);
            }
        }
    }

    this.setTimeout = function(fn, delay) {
        var id = _nextTimerId++;
        _timers[id] = {
            fn: fn,
            time: now() + delay,
            delay: delay,
            repeat: false
        };
        lj_newtimer(id, _timers[id].time, _timers[id].delay, _timers[id].repeat)
        return id;
    };

    this.setInterval = function(fn, delay) {
        var id = _nextTimerId++;
        _timers[id] = {
            fn: fn,
            time: now() + delay,
            delay: delay,
            repeat: true
        };
        lj_newtimer(id, _timers[id].time, _timers[id].delay, _timers[id].repeat)
        return id;
    };

    this.clearTimeout = function(id) {
        delete _timers[id];
    };

    this.clearInterval = this.clearTimeout;
    // this.runTimers = runTimers;
    this.updateTimer = updateTimer;
})(typeof window !== 'undefined' ? window : this);

// ---------------------------- XHR -------------------

(function(global) {
    function FakeXHR() {
        this.readyState = 0;
        this.status = 0;
        this.responseText = "";
        this._headers = {};
        this.onreadystatechange = null;
        this._method = null;
        this._url = null;
    }

    FakeXHR.prototype.open = function(method, url, async) {
        this._method = method;
        this._url = url;
        this.readyState = 1;

        // Check url and load in luajit?
        this._requestId = lj_loadurl(this._method, this._url)

        if (this.onreadystatechange) this.onreadystatechange();
    };

    FakeXHR.prototype.setRequestHeader = function(header, value) {
        this._headers[header.toLowerCase()] = value;
    };

    FakeXHR.prototype.getResponseHeader = function(header) {
        return this._headers[header.toLowerCase()] || null;
    };

    FakeXHR.prototype.getAllResponseHeaders = function() {
        var result = "";
        for (var key in this._headers) {
            if (this._headers.hasOwnProperty(key)) {
                result += key + ": " + this._headers[key] + "\r\n";
            }
        }
        return result;
    };

    FakeXHR.prototype.send = function(data) {
        var self = this;

        // Simulate an async HTTP GET request (or POST)
        // Replace this with native calls or your own loader if needed

        // For demo, respond with static HTML after a tiny delay
        self.readyState = 2;
        self.status = 0;
        if (self.onreadystatechange) self.onreadystatechange();

        // simulate response headers
        self._headers["content-type"] = "text/html";

        // simulate delay with setTimeout (must be polyfilled or native)
        setTimeout(function() {
            self.readyState = 4;
            self.status = 200;
            self.responseText = "<html><body><h1>Fake Response</h1></body></html>";
            if (self.onreadystatechange) self.onreadystatechange();
        }, 1000);
    };

    // Expose FakeXHR globally as XMLHttpRequest
    global.XMLHttpRequest = FakeXHR;

})(typeof window !== "undefined" ? window : this);

// ---------------------------------------------------

// Calls back to lua, to say the JS has a fake dom ready to use
lj_shimdone( new Date().getTime() );

// ---------------------------------------------------