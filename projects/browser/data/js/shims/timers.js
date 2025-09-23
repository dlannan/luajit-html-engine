(function(global) {
    var _nextTimerId = 1;
    var _timers = {};

    function now() {
        return new Date().getTime();
    }

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

    function runTimers() {
        var current = now();
        for (var id in _timers) {
            var t = _timers[id];
            if (t.time <= current) {
                updateTimer(id);
            }
        }
    }

    // Expose to global scope
    global.setTimeout = function(fn, delay) {
        var id = _nextTimerId++;
        _timers[id] = {
            fn: fn,
            time: now() + delay,
            delay: delay,
            repeat: false
        };
        lj_newtimer(id, _timers[id].time, _timers[id].delay, _timers[id].repeat);
        return id;
    };

    global.setInterval = function(fn, delay) {
        var id = _nextTimerId++;
        _timers[id] = {
            fn: fn,
            time: now() + delay,
            delay: delay,
            repeat: true
        };
        lj_newtimer(id, _timers[id].time, _timers[id].delay, _timers[id].repeat);
        return id;
    };

    global.clearTimeout = function(id) {
        delete _timers[id];
        lj_deltimer(id);
    };

    global.clearInterval = global.clearTimeout;
    global.updateTimer = updateTimer;
    global.runTimers = runTimers;  // 💡 Exposed here
})(typeof window !== 'undefined' ? window : this);
