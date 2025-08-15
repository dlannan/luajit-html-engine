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
        
        // The readystate listener shall be called when the file load is complete?!
        self.readyState = 2;
        self.status = 0;
        if (self.onreadystatechange) self.onreadystatechange();
        // simulate response headers -- need to generate this from mime types
        self._headers["content-type"] = "text/html";

        // Check url and load in luajit?
        self._requestId = lj_loadurl(self, function(respText) {
            self.readyState = 4;
            self.status = 200;
            self.responseText = respText;
            if (self.onreadystatechange) self.onreadystatechange();
        });

    };

    // Expose FakeXHR globally as XMLHttpRequest
    global.XMLHttpRequest = FakeXHR;

})(typeof window !== "undefined" ? window : this);