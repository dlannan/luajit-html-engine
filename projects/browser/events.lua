
-- These event handlers look after input event generation. 
-- Each handler can be overridden if needed

local ffi           = require("ffi")

local tinsert       = table.insert

-----------------------------------------------------------------------------------------------------------------------------------

local CHAR_KEY_TEST = bit.bor(sg.SAPP_MODIFIER_ALT, bit.bor(sg.SAPP_MODIFIER_CTRL, sg.SAPP_MODIFIER_SUPER))

-----------------------------------------------------------------------------------------------------------------------------------

local function _snk_is_ctrl(modifiers) 
    if (ffi.os == "MacOSX") then
        return bit.band(modifiers, sg.SAPP_MODIFIER_SUPER) == 0
    else 
        return  bit.band(modifiers, sg.SAPP_MODIFIER_CTRL) == 0
    end
end

-----------------------------------------------------------------------------------------------------------------------------------
-- Set this on init

local allevents    = {

    dpi_scale       = 1.0,

    -- Recent key events
    --   key events have: eventid, keyid, timepressed, timereleased, isdown.
    --   mouse events have: eventid, pos, scroll, buttons, moved and scrolled.
    queue       = {},  

    -- List of responders that act on specific events
    responders  = {},
}

-----------------------------------------------------------------------------------------------------------------------------------

local function key_event( eid, kid, pressed, char )
    
    local evt = { 
        evtid       = eid,
        keyid       = kid, 
        time        = 0, 
        pressed     = pressed or 1, 
        released    = 1-(pressed or 1),
        char        = char, 
    }
    return evt
end

-----------------------------------------------------------------------------------------------------------------------------------

local function mouse_event( eid )

    local mevent = { 
        evtid   = eid,
        pos     = { x = 0, y = 0 },
        scroll  = { x = 0, y = 0 },
        buttons = {
            [0] = { pressed = 0, released = 0 },
            [1] = { pressed = 0, released = 0 },
            [2] = { pressed = 0, released = 0 },
        },
        moved        = 0,
        scrolled     = 0,
    }
    return mevent
end

-------------------------------------------------------------0----------------------------------------------------------------------

local event_handlers = {

    [sg.SAPP_EVENTTYPE_MOUSE_DOWN] = function(ev)
        local me = mouse_event(sg.SAPP_EVENTTYPE_MOUSE_DOWN)
        me.pos.x = (ev.mouse_x / allevents.dpi_scale)
        me.pos.y = (ev.mouse_y / allevents.dpi_scale)
        if(ev.mouse_button == sg.SAPP_MOUSEBUTTON_LEFT) then
            me.buttons[0].pressed = 1
        elseif(ev.mouse_button == sg.SAPP_MOUSEBUTTON_RIGHT) then
            me.buttons[2].pressed = 1
        elseif(ev.mouse_button == sg.SAPP_MOUSEBUTTON_MIDDLE) then
            me.buttons[1].pressed = 1
        end
        tinsert(allevents.queue, me)
    end,
    [sg.SAPP_EVENTTYPE_MOUSE_UP] = function(ev)
        local me = mouse_event(sg.SAPP_EVENTTYPE_MOUSE_UP)
        me.pos.x = (ev.mouse_x * allevents.dpi_scale)
        me.pos.y = (ev.mouse_y * allevents.dpi_scale)
        if(ev.mouse_button == sg.SAPP_MOUSEBUTTON_LEFT) then
            me.buttons[0].released = 1
        elseif(ev.mouse_button == sg.SAPP_MOUSEBUTTON_RIGHT) then
            me.buttons[2].released = 1
        elseif(ev.mouse_button == sg.SAPP_MOUSEBUTTON_MIDDLE) then
            me.buttons[1].released = 1
        end
        tinsert(allevents.queue, me)
    end,
    [sg.SAPP_EVENTTYPE_MOUSE_MOVE] = function(ev)
        local me = mouse_event(sg.SAPP_EVENTTYPE_MOUSE_MOVE)
        me.pos.x = (ev.mouse_x * allevents.dpi_scale)
        me.pos.y = (ev.mouse_y * allevents.dpi_scale)
        me.moved = 1
        tinsert(allevents.queue, me)
    end,
    [sg.SAPP_EVENTTYPE_MOUSE_ENTER] = function(ev) 
        tinsert(allevents.queue, mouse_event(sg.SAPP_EVENTTYPE_MOUSE_ENTER))
    end,
    [sg.SAPP_EVENTTYPE_MOUSE_SCROLL] = function(ev)
        local me = mouse_event(sg.SAPP_EVENTTYPE_MOUSE_SCROLL)
        me.scroll.x = ev.scroll_x
        me.scroll.y = ev.scroll_y
        me.scrolled = 1
        tinsert(allevents.queue, me)
    end,
    [sg.SAPP_EVENTTYPE_TOUCHES_BEGAN] = function(ev)
        local me = mouse_event(sg.SAPP_EVENTTYPE_TOUCHES_BEGAN)
        me.buttons[0].pressed = 1
        me.pos.x = (ev.mouse_x * allevents.dpi_scale)
        me.pos.y = (ev.mouse_y * allevents.dpi_scale)
        me.moved = 1
        tinsert(allevents.queue, me)
    end,
    [sg.SAPP_EVENTTYPE_TOUCHES_MOVED] = function(ev)
        local me = mouse_event(sg.SAPP_EVENTTYPE_TOUCHES_MOVED)
        me.pos.x = (ev.mouse_x * allevents.dpi_scale)
        me.pos.y = (ev.mouse_y * allevents.dpi_scale)
        me.moved = 1
        tinsert(allevents.queue, me)
    end,
    [sg.SAPP_EVENTTYPE_TOUCHES_ENDED] = function(ev)
        local me = mouse_event(sg.SAPP_EVENTTYPE_TOUCHES_ENDED)
        me.buttons[0].released = 1
        me.pos.x = (ev.mouse_x * allevents.dpi_scale)
        me.pos.y = (ev.mouse_y * allevents.dpi_scale)
        me.moved = 1
        tinsert(allevents.queue, me)
    end,
    [sg.SAPP_EVENTTYPE_TOUCHES_CANCELLED] = function(ev)
        local me = mouse_event(sg.SAPP_EVENTTYPE_TOUCHES_CANCELLED)
        tinsert(allevents.queue, me)
    end,
    [sg.SAPP_EVENTTYPE_KEY_DOWN] = function(ev)
        -- /* intercept Ctrl-V, this is handled via EVENTTYPE_CLIPBOARD_PASTED */
        if (_snk_is_ctrl(ev.modifiers) and (ev.key_code == sg.SAPP_KEYCODE_V)) then
            return
        end
        -- /* on web platform, don't forward Ctrl-X, Ctrl-V to the browser */
        if (_snk_is_ctrl(ev.modifiers) and (ev.key_code == sg.SAPP_KEYCODE_X)) then
            -- sapp_consume_event();
        end
        if (_snk_is_ctrl(ev.modifiers) and (ev.key_code == sg.SAPP_KEYCODE_C)) then
            -- sapp_consume_event();
        end
        local keyev = key_event(sg.SAPP_EVENTTYPE_KEY_DOWN, ev.key_code, 1, nil)
        tinsert(allevents.queue, keyev)
    end,
    [sg.SAPP_EVENTTYPE_KEY_UP] = function(ev)
        -- /* intercept Ctrl-V, this is handled via EVENTTYPE_CLIPBOARD_PASTED */
        if (_snk_is_ctrl(ev.modifiers) and (ev.key_code == sg.SAPP_KEYCODE_V)) then
            return
        end
        -- /* on web platform, don't forward Ctrl-X, Ctrl-V to the browser */
        if (_snk_is_ctrl(ev.modifiers) and (ev.key_code == sg.SAPP_KEYCODE_X)) then
            -- sapp_consume_event();
        end
        if (_snk_is_ctrl(ev.modifiers) and (ev.key_code == sg.SAPP_KEYCODE_C)) then
            -- sapp_consume_event();
        end
        local keyev = key_event(sg.SAPP_EVENTTYPE_KEY_DOWN, ev.key_code, 0, nil)
        tinsert(allevents.queue, keyev)        
    end,
    [sg.SAPP_EVENTTYPE_CHAR] = function(ev)
        if ((ev.char_code >= 32) and
            (ev.char_code ~= 127) and
            (0 == (bit.band(ev.modifiers, CHAR_KEY_TEST))) ) then 
        
            local keyev = key_event(sg.SAPP_EVENTTYPE_CHAR, ev.char_code, 1, 1)
            tinsert(allevents.queue, keyev)              
        end
    end,
    [sg.SAPP_EVENTTYPE_CLIPBOARD_PASTED] = function(ev)
        local keyev = key_event(sg.SAPP_EVENTTYPE_CLIPBOARD_PASTED, nil, 0, nil)
        tinsert(allevents.queue, keyev) 
    end,
}

-----------------------------------------------------------------------------------------------------------------------------------

event_handlers[sg.SAPP_EVENTTYPE_MOUSE_LEAVE] = event_handlers[sg.SAPP_EVENTTYPE_MOUSE_ENTER]

allevents.handlers = event_handlers

-----------------------------------------------------------------------------------------------------------------------------------

allevents.add_event = function( event )
    local etype = tonumber(event.type)
    if(allevents.handlers[etype]) then 
        allevents.handlers[etype](event)
    end
end

-----------------------------------------------------------------------------------------------------------------------------------

allevents.get_handler = function( event )
    local etype = tonumber(event.type)
    if(allevents.handlers[etype]) then 
        return allevents.handlers[etype]
    end
    return nil
end

-----------------------------------------------------------------------------------------------------------------------------------
-- This is only really useful if you want your own input handling routines
allevents.set_handler = function( event, handlerfunc )
    local etype = tonumber(event.type)
    allevents.handlers[etype] = handlerfunc
end

-----------------------------------------------------------------------------------------------------------------------------------
-- Go through queued events and process them. 
--     timeout  - allowed amount of time spent (in ms)
--     limit    - number of queued items that must be processed
allevents.process = function( timeout, limit )
    local responders = allevents.responders
    for i, v in ipairs(allevents.queue) do
        local resp = responders[v.evtid]
        if(resp) then 
            print(v.evtid)
            -- Can have multiple responders to a single event
            for ir, respfunc in ipairs(resp) do 
                if(respfunc) then respfunc( v ) end 
            end
        end
    end
    allevents.queue = {}
end

-----------------------------------------------------------------------------------------------------------------------------------
-- Add a function that responds to specific events (keys, etc)
--   These will be called in the process_queue pass in order of incoming events
allevents.add_responder = function( eid, respond_func)
    local resp = allevents.responders[eid] or {}
    tinsert( resp, respond_func )
    allevents.responders[eid] = resp
end 

-----------------------------------------------------------------------------------------------------------------------------------

allevents.clear_responders  = function() 
    allevents.responders = {}
end

-----------------------------------------------------------------------------------------------------------------------------------

return allevents

-----------------------------------------------------------------------------------------------------------------------------------
