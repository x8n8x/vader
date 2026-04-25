-- cache
if _G.vh9_cache == nil then
    _G.vh9_cache = {}
end

--global state init
if _G.vh9 == nil then
    _G.vh9 = {
        -- theme
        col = {
            accent      = {255, 200, 69},
            text        = {255, 255, 255},
            text_dim    = {170, 170, 170},
            a           = {0,   0,   0  },
            b           = {56,  56,  56 },
            c           = {46,  46,  46 },
            d           = {12,  12,  12 },
            e           = {21,  21,  21 },
            f           = {84,  84,  84 },
            g           = {54,  54,  54 },
        },

        -- input
        key         = "",
        prev_key    = "",
        lmb         = false,
        prev_lmb    = false,
        rmb         = false,
        prev_rmb    = false,
        lmb_held    = false,
        mouse       = {x=0, y=0},

        -- windows list
        windows     = {},

        -- keybind list entries  {text}
        keybind_entries = {},

        -- notification list
        notifs      = {},

        -- watermark
        wm = {
            text    = "vaderhaxx9",
            visible = true,
            x       = 10,
            y       = 10,
        },

        -- rainbow
        rainbow_hue = 0,
        rainbow_col = {255, 0, 0},

        -- clock
        t_prev = os.clock(),
        dt     = 0,

        first_run = nil,
    }
end

local G   = _G.vh9
local col = G.col

-- first run flag
if G.first_run == nil then
    G.first_run = true
elseif G.first_run == true then
    G.first_run = false
end

-- update dt
local _now = os.clock()
G.dt = math.min(_now - G.t_prev, 0.1)
G.t_prev = _now

-- update input
G.prev_key  = G.key
G.prev_lmb  = G.lmb
G.prev_rmb  = G.rmb
G.key       = dx9.GetKey() or ""
G.lmb       = dx9.isLeftClick()
G.rmb       = dx9.isRightClick()
G.lmb_held  = dx9.isLeftClickHeld()
G.mouse     = dx9.GetMouse()

-- helpers
local function key_new()
    return G.key ~= "" and G.key ~= "[None]" and G.key ~= G.prev_key
end
local function lmb_new()
    return G.lmb and not G.prev_lmb
end
local function rmb_new()
    return G.rmb and not G.prev_rmb
end
local function mouse_in(x1, y1, x2, y2)
    local m = G.mouse
    return m.x >= x1 and m.x <= x2 and m.y >= y1 and m.y <= y2
end

-- drawing shortcuts
local function fill(x1,y1,x2,y2,c)
    dx9.DrawFilledBox({x1,y1},{x2,y2},c)
end
local function box(x1,y1,x2,y2,c)
    dx9.DrawBox({x1,y1},{x2,y2},c)
end
local function str(x,y,c,t)
    dx9.DrawString({x,y},c,t)
end
local function tw(t)
    return dx9.CalcTextWidth(t)
end

-- rainbow update
local function update_rainbow()
    G.rainbow_hue = G.rainbow_hue + 3
    if G.rainbow_hue > 1530 then G.rainbow_hue = 0 end
    local h = G.rainbow_hue
    if     h <= 255  then G.rainbow_col = {255, h, 0}
    elseif h <= 510  then G.rainbow_col = {510-h, 255, 0}
    elseif h <= 765  then G.rainbow_col = {0, 255, h-510}
    elseif h <= 1020 then G.rainbow_col = {0, 1020-h, 255}
    elseif h <= 1275 then G.rainbow_col = {h-1020, 0, 255}
    else                  G.rainbow_col = {255, 0, 1530-h}
    end
end
update_rainbow()

-- outline box
local function outline_box(x,y,w,h)
    fill(x,   y,   x+w,   y+h,   col.a)       -- outer black
    fill(x+1, y+1, x+w-1, y+h-1, col.b)       -- b layer
    fill(x+2, y+2, x+w-2, y+h-2, col.c)       -- c layer
    fill(x+3, y+3, x+w-3, y+h-3, col.d)       -- inner dark
end

-- content area
local function content_box(x,y,w,h)
    fill(x,   y,   x+w,   y+h,   col.a)
    fill(x+1, y+1, x+w-1, y+h-1, col.c)
    fill(x+2, y+2, x+w-2, y+h-2, col.e)
end

-- element box
local function elem_box(x,y,w,h, hovered)
    fill(x,   y,   x+w,   y+h,   col.d)
    fill(x+1, y+1, x+w-1, y+h-1, hovered and col.c or col.b)
end

------ lib

local library = {}
library.__index = library

-- notifications
function library.notify(text, duration)
    duration = duration or 3
    table.insert(G.notifs, {
        text  = text,
        timer = duration,
        alpha = 1.0,
    })
end

local function draw_notifs()
    local sw = dx9.size().width
    local nw = 220
    local nh = 20
    local pad = 4

    for i = #G.notifs, 1, -1 do
        local n = G.notifs[i]
        n.timer = n.timer - G.dt
        if n.timer <= 0 then
            table.remove(G.notifs, i)
        end
    end

    for i, n in ipairs(G.notifs) do
        local nx = sw - nw - 10
        local ny = dx9.size().height - 10 - (i * (nh + pad))

        fill(nx,   ny,   nx+nw,   ny+nh,   col.a)
        fill(nx+1, ny+1, nx+nw-1, ny+nh-1, col.c)
        fill(nx+2, ny+2, nx+nw-2, ny+nh-2, col.e)

        -- progress bar
        local prog = math.max(0, n.timer / 3)
        fill(nx+2, ny+2, nx+2+math.floor((nw-4)*prog), ny+4, col.accent)

        str(nx+6, ny+5, col.text, n.text)
    end
end

-- watermark
local function draw_watermark()
    if not G.wm.visible then return end

    local fps_text = G.wm.text .. " | fps: " .. tostring(math.floor(1/(G.dt+0.0001)))
    local ww = tw(fps_text) + 16
    local wh = 18
    local x, y = G.wm.x, G.wm.y

    fill(x,   y,   x+ww,   y+wh,   col.a)
    fill(x+1, y+1, x+ww-1, y+wh-1, col.c)
    fill(x+2, y+2, x+ww-2, y+wh-2, col.e)

    -- accent top bar
    fill(x+2, y+2, x+ww-2, y+4, col.accent)

    str(x+6, y+5, G.rainbow_col, fps_text)
end

-- keybindlist
local function draw_keybind_list()
    if #G.keybind_entries == 0 then return end

    local x = dx9.size().width - 220
    local y = 40
    local w = 200
    local lh = 16
    local h = 28 + (#G.keybind_entries * lh) + 8

    fill(x,   y,   x+w,   y+h,   col.a)
    fill(x+1, y+1, x+w-1, y+h-1, col.b)
    fill(x+2, y+2, x+w-2, y+h-2, col.e)

    -- title tab
    fill(x+2, y+2, x+w-2, y+4, col.accent)
    str(x + (w - tw("keybinds"))/2, y+6, col.text, "keybinds")

    -- accent underline
    fill(x+2, y+22, x+w-2, y+24, col.accent)

    local cy = y + 26
    for _, entry in ipairs(G.keybind_entries) do
        str(x+8, cy, col.text, entry)
        cy = cy + lh
    end
end

-- window
function library:window(params)
    local name = params.name or params.Name or "vaderhaxx9"
    local toggle_key = params.toggle_key or "[INSERT]"
    local x = params.x or 100
    local y = params.y or 100
    local w = params.w or 560
    local h = params.h or 480

    if G.windows[name] == nil then
        G.windows[name] = {
            name        = name,
            toggle_key  = toggle_key,
            x = x, y = y, w = w, h = h,
            visible     = true,
            dragging    = false,
            drag_ox     = 0,
            drag_oy     = 0,
            tabs        = {},
            tab_order   = {},
            current_tab = nil,
            -- open dropdown/picker ref
            open_tool   = nil,
        }
    end

    local win = G.windows[name]

    -- toggle key
    if key_new() and G.key == win.toggle_key then
        win.visible = not win.visible
    end

    if not win.visible then
        return setmetatable(win, library)
    end

    -- dragging (title bar = top 24px)
    local drag_h = 24
    if G.lmb_held then
        if win.dragging then
            win.x = G.mouse.x - win.drag_ox
            win.y = G.mouse.y - win.drag_oy
        elseif mouse_in(win.x, win.y, win.x+win.w, win.y+drag_h) then
            win.dragging = true
            win.drag_ox  = G.mouse.x - win.x
            win.drag_oy  = G.mouse.y - win.y
        end
    else
        win.dragging = false
    end

    -- draw window shell
    local wx, wy, ww, wh = win.x, win.y, win.w, win.h

    -- outer border layers
    fill(wx,   wy,   wx+ww,   wy+wh,   col.a)
    fill(wx+1, wy+1, wx+ww-1, wy+wh-1, col.b)
    fill(wx+2, wy+2, wx+ww-2, wy+wh-2, col.c)
    fill(wx+3, wy+3, wx+ww-3, wy+wh-3, col.c)
    fill(wx+4, wy+4, wx+ww-4, wy+wh-4, col.a)
    -- inner fill
    fill(wx+5, wy+5, wx+ww-5, wy+wh-5, col.e)

    -- title bar accent
    fill(wx+5, wy+5, wx+ww-5, wy+7, col.accent)

    -- window name
    str(wx + (ww - tw(name))/2, wy+8, col.text, name)

    -- tab bar background
    fill(wx+5, wy+22, wx+ww-5, wy+50, col.d)
    fill(wx+5, wy+48, wx+ww-5, wy+50, col.accent)

    -- draw tabs
    local tx = wx + 17
    win._tab_render_x = tx
    win._tab_bar_y    = wy + 22

    local tab_h = 26
    for _, tname in ipairs(win.tab_order) do
        local t = win.tabs[tname]
        local tlen = tw(tname) + 14
        t._bx  = tx
        t._bw  = tlen
        t._by  = wy + 22
        t._bh  = tab_h

        local is_sel = (win.current_tab == tname)

        if is_sel then
            fill(tx, wy+22, tx+tlen, wy+48, col.e)
            fill(tx, wy+46, tx+tlen, wy+50, col.accent)
        else
            fill(tx, wy+23, tx+tlen, wy+48, col.d)
        end

        str(tx + (tlen - tw(tname))/2, wy+30, is_sel and col.accent or col.text_dim or col.text, tname)

        -- click
        if lmb_new() and mouse_in(tx, wy+22, tx+tlen, wy+50) then
            win.current_tab = tname
        end

        tx = tx + tlen + 4
    end

    -- content area
    fill(wx+5, wy+50, wx+ww-5, wy+wh-5, col.e)
    fill(wx+17, wy+60, wx+ww-17, wy+wh-10, col.d)
    fill(wx+18, wy+61, wx+ww-18, wy+wh-11, col.e)

    win._cx = wx + 18
    win._cy = wy + 61
    win._cw = ww - 36
    win._ch = wh - 72

    -- set default tab
    if win.current_tab == nil and #win.tab_order > 0 then
        win.current_tab = win.tab_order[1]
    end

    return setmetatable(win, library)
end

-- tab
function library:tab(params)
    local name = params.name or "tab"
    local win  = self  -- self is the window

    if win.tabs[name] == nil then
        win.tabs[name] = {
            name     = name,
            sections = {},
            sec_order= {},
        }
        table.insert(win.tab_order, name)
    end

    local t = win.tabs[name]
    t._win = win

    return setmetatable(t, library)
end

-- section
function library:section(params)
    local name = params.name or "section"
    local side = params.side or "left"
    local tab  = self

    if tab.sections[name] == nil then
        tab.sections[name] = {
            name     = name,
            side     = side,
            items    = {},
            item_order = {},
        }
        table.insert(tab.sec_order, name)
    end

    local s = tab.sections[name]
    s._tab = tab

    return setmetatable(s, library)
end

-- render help
local function draw_section(sec, x, y, w, win)
    local lh   = 16
    local pad  = 8
    local th   = 18  -- title height

    -- total height
    local content_h = th + pad
    for _, iname in ipairs(sec.item_order) do
        local item = sec.items[iname]
        if item.type == "toggle"   then content_h = content_h + lh + 4
        elseif item.type == "slider"   then content_h = content_h + lh*2 + 4
        elseif item.type == "dropdown" then
            content_h = content_h + lh + th + 4
            if item.open then
                content_h = content_h + (#item.values * lh) + 4
            end
        elseif item.type == "button"   then content_h = content_h + lh + 4
        elseif item.type == "keybind"  then content_h = content_h + lh + 4
        end
    end
    content_h = content_h + pad

    -- section shell
    fill(x,   y,   x+w,   y+content_h,   col.a)
    fill(x+1, y+1, x+w-1, y+content_h-1, col.c)
    fill(x+2, y+2, x+w-2, y+content_h-2, col.e)

    -- title accent bar
    fill(x+2, y+2, x+w-2, y+4, col.accent)

    -- section title
    str(x+8, y+6, col.text, sec.name)
    fill(x+2, y+th, x+w-2, y+th+1, col.f)

    -- items
    local cy = y + th + pad
    local iw = w - 16  -- item width

    for _, iname in ipairs(sec.item_order) do
        local item = sec.items[iname]
        item._x = x + 8
        item._y = cy
        item._w = iw

        if item.type == "toggle" then
            -- checkbox
            local bsize = 10
            local bx, by = x+8, cy
            local hov = mouse_in(bx, by, bx+iw, by+lh)
            local checked = item.value

            fill(bx,   by,   bx+bsize,   by+bsize,   col.d)
            fill(bx+1, by+1, bx+bsize-1, by+bsize-1, checked and col.accent or (hov and col.f or col.f))

            if checked then
                -- checkmark lines
                dx9.DrawLine({bx+2, by+5}, {bx+4, by+8}, col.d)
                dx9.DrawLine({bx+4, by+8}, {bx+8, by+2}, col.d)
            end

            str(bx+bsize+4, by-1, hov and col.accent or col.text, item.name)

            -- click
            if lmb_new() and hov and not win.open_tool then
                item.value = not item.value
                if item.callback then item.callback(item.value) end
            end

            cy = cy + lh + 4

        elseif item.type == "slider" then
            str(x+8, cy, col.text, item.name)
            cy = cy + lh

            local sw = iw
            local sx, sy = x+8, cy
            local hov = mouse_in(sx, sy, sx+sw, sy+lh-2)

            fill(sx,   sy,   sx+sw,   sy+lh-2,   col.d)
            fill(sx+1, sy+1, sx+sw-1, sy+lh-3,   col.b)

            local range = item.max - item.min
            local pct   = (item.value - item.min) / range
            local fill_w = math.floor(pct * (sw-2))
            fill(sx+1, sy+1, sx+1+fill_w, sy+lh-3, col.accent)

            local val_str = tostring(item.value) .. (item.suffix or "")
            str(sx + (sw - tw(val_str))/2, sy+1, col.text, val_str)

            if (hov or item.dragging) and G.lmb_held and not win.open_tool then
                item.dragging = true
                local rel = math.max(0, math.min(1, (G.mouse.x - sx) / sw))
                local raw = item.min + rel * range
                local steps = item.interval or 1
                item.value  = math.floor(raw / steps + 0.5) * steps
                item.value  = math.max(item.min, math.min(item.max, item.value))
                if item.callback then item.callback(item.value) end
            else
                item.dragging = false
            end

            cy = cy + lh + 4

        elseif item.type == "dropdown" then
            str(x+8, cy, col.text, item.name)
            cy = cy + lh

            local dw = iw
            local dx2, dy = x+8, cy
            local hov = mouse_in(dx2, dy, dx2+dw, dy+lh)
            local is_open = (win.open_tool == item)

            fill(dx2,   dy,   dx2+dw,   dy+lh,   col.d)
            fill(dx2+1, dy+1, dx2+dw-1, dy+lh-1, is_open and col.c or col.b)

            local sel_str = item.value or "..."
            str(dx2+4, dy+2, col.text, sel_str)

            -- arrow
            local ax = dx2+dw-12
            if is_open then
                dx9.DrawLine({ax,   dy+8}, {ax+4, dy+4}, col.accent)
                dx9.DrawLine({ax+4, dy+4}, {ax+8, dy+8}, col.accent)
            else
                dx9.DrawLine({ax,   dy+4}, {ax+4, dy+8}, col.f)
                dx9.DrawLine({ax+4, dy+8}, {ax+8, dy+4}, col.f)
            end

            if lmb_new() and hov then
                if is_open then
                    win.open_tool = nil
                else
                    win.open_tool = item
                end
            end

            item._dropdown_x = dx2
            item._dropdown_y = dy
            item._dropdown_w = dw

            cy = cy + lh + 4

        elseif item.type == "button" then
            local bw = iw
            local bx2, by2 = x+8, cy
            local hov = mouse_in(bx2, by2, bx2+bw, by2+lh)

            fill(bx2,   by2,   bx2+bw,   by2+lh,   col.d)
            fill(bx2+1, by2+1, bx2+bw-1, by2+lh-1, hov and col.c or col.b)
            str(bx2 + (bw - tw(item.name))/2, by2+2, hov and col.accent or col.text, item.name)

            if lmb_new() and hov and not win.open_tool then
                if item.callback then item.callback() end
            end

            cy = cy + lh + 4

        elseif item.type == "keybind" then
            local kw = 44
            local kx  = x + w - kw - 12
            local ky  = cy
            local hov = mouse_in(kx, ky, kx+kw, ky+lh-2)

            str(x+8, cy-1, col.text, item.name)

            fill(kx,   ky,   kx+kw,   ky+lh-2,   col.a)
            fill(kx+1, ky+1, kx+kw-1, ky+lh-3,   hov and col.c or col.b)

            local kdisp = item.listening and "..." or ("[".. (item.key or "NONE") .."]")
            str(kx + (kw - tw(kdisp))/2, ky+1, item.listening and col.accent or col.text, kdisp)

            if lmb_new() and hov and not win.open_tool then
                item.listening = true
            end

            if item.listening and key_new() and G.key ~= "" and G.key ~= "[None]" then
                local k = G.key:match("%[(.+)%]") or G.key
                item.key = (k == "BACK") and "NONE" or k
                item.listening = false
                if item.callback then item.callback(item.key) end

                -- update keybind list
                G.keybind_entries = {}
                -- rebuilt below in render
            end

            cy = cy + lh + 4
        end
    end

    return content_h
end

-- dropdown topmost
local function draw_open_dropdown(win)
    local item = win.open_tool
    if item == nil or item.type ~= "dropdown" then return end

    local dx2 = item._dropdown_x
    local dy  = item._dropdown_y + 18
    local dw  = item._dropdown_w
    local lh  = 16
    local oh  = #item.values * lh + 8

    fill(dx2,   dy,   dx2+dw,   dy+oh,   col.d)
    fill(dx2+1, dy+1, dx2+dw-1, dy+oh-1, col.c)

    local oy = dy + 4
    for _, v in ipairs(item.values) do
        local hov = mouse_in(dx2, oy, dx2+dw, oy+lh)
        local sel = (item.value == v)

        if hov then fill(dx2+2, oy, dx2+dw-2, oy+lh, col.b) end
        str(dx2+6, oy+1, sel and col.accent or col.text, v)

        if lmb_new() and hov then
            if item.multi then
                -- toggle in multi list
                local found = false
                for i2, mv in ipairs(item.multi_values) do
                    if mv == v then
                        table.remove(item.multi_values, i2)
                        found = true
                        break
                    end
                end
                if not found then table.insert(item.multi_values, v) end
                item.value = table.concat(item.multi_values, ", ")
                if item.callback then item.callback(item.multi_values) end
            else
                item.value = v
                win.open_tool = nil
                if item.callback then item.callback(v) end
            end
        end

        oy = oy + lh
    end

    -- close 
    if lmb_new() and not mouse_in(dx2, item._dropdown_y, dx2+dw, dy+oh) then
        win.open_tool = nil
    end
end


-- elements
function library:toggle(params)
    local sec  = self
    local name = params.name or "toggle"
    local flag = params.flag or name

    if sec.items[flag] == nil then
        sec.items[flag] = {
            type     = "toggle",
            name     = name,
            flag     = flag,
            value    = params.default or false,
            callback = params.callback or nil,
        }
        table.insert(sec.item_order, flag)
    else
        sec.items[flag].callback = params.callback or sec.items[flag].callback
    end

    return setmetatable(sec.items[flag], library)
end

function library:slider(params)
    local sec  = self
    local name = params.name or "slider"
    local flag = params.flag or name

    if sec.items[flag] == nil then
        sec.items[flag] = {
            type     = "slider",
            name     = name,
            flag     = flag,
            value    = params.default or params.value or params.min or 0,
            min      = params.min or params.minimum or 0,
            max      = params.max or params.maximum or 100,
            interval = params.interval or params.decimal or 1,
            suffix   = params.suffix or "",
            callback = params.callback or nil,
            dragging = false,
        }
        table.insert(sec.item_order, flag)
    else
        sec.items[flag].callback = params.callback or sec.items[flag].callback
    end

    return setmetatable(sec.items[flag], library)
end

function library:dropdown(params)
    local sec    = self
    local name   = params.name or "dropdown"
    local flag   = params.flag or name
    local values = params.items or params.values or {}
    local multi  = params.multi or false

    if sec.items[flag] == nil then
        local default_val
        if multi then
            default_val = (type(params.default) == "table") and table.concat(params.default, ", ") or (values[1] or "")
        else
            default_val = params.default or values[1] or ""
        end
        sec.items[flag] = {
            type         = "dropdown",
            name         = name,
            flag         = flag,
            value        = default_val,
            values       = values,
            multi        = multi,
            multi_values = (multi and (type(params.default) == "table") and params.default) or {},
            callback     = params.callback or nil,
            open         = false,
            _dropdown_x  = 0,
            _dropdown_y  = 0,
            _dropdown_w  = 0,
        }
        table.insert(sec.item_order, flag)
    else
        sec.items[flag].values   = values
        sec.items[flag].callback = params.callback or sec.items[flag].callback
    end

    return setmetatable(sec.items[flag], library)
end

function library:button(params)
    local sec  = self
    local name = params.name or "button"
    local flag = params.flag or name

    if sec.items[flag] == nil then
        sec.items[flag] = {
            type     = "button",
            name     = name,
            flag     = flag,
            callback = params.callback or nil,
        }
        table.insert(sec.item_order, flag)
    else
        sec.items[flag].callback = params.callback or sec.items[flag].callback
    end

    return setmetatable(sec.items[flag], library)
end

function library:keybind(params)
    local sec  = self
    local name = params.name or "keybind"
    local flag = params.flag or name

    if sec.items[flag] == nil then
        sec.items[flag] = {
            type      = "keybind",
            name      = name,
            flag      = flag,
            key       = params.default or "NONE",
            listening = false,
            callback  = params.callback or nil,
        }
        table.insert(sec.item_order, flag)
    else
        sec.items[flag].callback = params.callback or sec.items[flag].callback
    end

    return setmetatable(sec.items[flag], library)
end

-- colorpicker stub for now
function library:colorpicker(params)
    return self
end


function library:on_changed(func)
    self.callback = func
    return self
end

-- render
function library:render()
    -- draw windows
    for _, win in pairs(G.windows) do
        if not win.visible then goto continue end

        local ct = win.current_tab
        if ct == nil then goto continue end

        local tab = win.tabs[ct]
        if tab == nil then goto continue end

        -- collect sections
        local left_secs  = {}
        local right_secs = {}
        for _, sname in ipairs(tab.sec_order) do
            local s = tab.sections[sname]
            if s.side == "right" then
                table.insert(right_secs, s)
            else
                table.insert(left_secs, s)
            end
        end

        local col_w = math.floor((win._cw - 12) / 2)
        local lx    = win._cx + 4
        local rx    = win._cx + col_w + 12
        local start_y = win._cy + 4

        local ly = start_y
        for _, s in ipairs(left_secs) do
            local h = draw_section(s, lx, ly, col_w, win)
            ly = ly + h + 8
        end

        local ry = start_y
        for _, s in ipairs(right_secs) do
            local h = draw_section(s, rx, ry, col_w, win)
            ry = ry + h + 8
        end

        -- dropdown draw ontop
        if win.open_tool then
            draw_open_dropdown(win)
        end

        ::continue::
    end

    -- rebuild keybindlist
    G.keybind_entries = {}
    for _, win in pairs(G.windows) do
        for _, tname in ipairs(win.tab_order) do
            local t = win.tabs[tname]
            for _, sname in ipairs(t.sec_order) do
                local s = t.sections[sname]
                for _, iname in ipairs(s.item_order) do
                    local item = s.items[iname]
                    if item.type == "keybind" and item.key and item.key ~= "NONE" then
                        table.insert(G.keybind_entries,
                            "[ "..item.key.." ] "..item.name)
                    end
                end
            end
        end
    end

    draw_watermark()
    draw_keybind_list()
    draw_notifs()
end

-- get value
function library.get(flag, win_name)
    for _, win in pairs(G.windows) do
        if win_name == nil or win.name == win_name then
            for _, tname in ipairs(win.tab_order) do
                local t = win.tabs[tname]
                for _, sname in ipairs(t.sec_order) do
                    local s = t.sections[sname]
                    if s.items[flag] then
                        return s.items[flag].value
                    end
                end
            end
        end
    end
    return nil
end

_G.vh9_lib = library
return library
