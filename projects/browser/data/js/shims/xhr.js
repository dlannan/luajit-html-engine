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
        // if (self.onreadystatechange) self.onreadystatechange();

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