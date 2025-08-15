// ---------------------------- TIMERS -------------------
(function() {
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