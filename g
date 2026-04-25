-- cache
if _G._dx9ui_loaded then return end
_G._dx9ui_loaded = true


local C = {
    accent   = {255, 200, 69},
    text     = {255, 255, 255},
    bg       = {15,  15,  15},
    secbg    = {30,  30,  30},
    inactive = {65,  65,  65},
    tabdim   = {100, 100, 100},
    dark     = {8,   8,   8},
    mid      = {40,  40,  40},
    gray     = {60,  60,  60},
    notif_bg = {20,  20,  20},
}


local LH        = 13   
local FONT_W    = 7   
local ELEM_TOG  = 20
local ELEM_SLD  = 40
local ELEM_DROP = 28
local ELEM_BTN  = 25
local ELEM_KB   = 20
local COL_GAP   = 12
local SEC_HEAD  = 28



local KEY_DISPLAY = {
    LBUTTON="LMB", RBUTTON="RMB", MBUTTON="MMB",
    RETURN="ENT", SPACE="SPC", BACK="BS", TAB="TAB",
    SHIFT="SHIFT", LSHIFT="LSHIFT", RSHIFT="RSHIFT",
    CONTROL="CTRL", LCONTROL="LCTRL", RCONTROL="RCTRL",
    MENU="ALT", LMENU="LALT", RMENU="RALT",
    DELETE="DEL", INSERT="INS", HOME="HOME", END="END",
    PRIOR="PGUP", NEXT="PGDN",
    LEFT="LEFT", RIGHT="RIGHT", UP="UP", DOWN="DOWN",
    F1="F1",F2="F2",F3="F3",F4="F4",F5="F5",F6="F6",
    F7="F7",F8="F8",F9="F9",F10="F10",F11="F11",F12="F12",
    NUMPAD0="NP0",NUMPAD1="NP1",NUMPAD2="NP2",NUMPAD3="NP3",
    NUMPAD4="NP4",NUMPAD5="NP5",NUMPAD6="NP6",NUMPAD7="NP7",
    NUMPAD8="NP8",NUMPAD9="NP9",
    MULTIPLY="NUM*",ADD="NUM+",SUBTRACT="NUM-",
    DECIMAL="NUM.",DIVIDE="NUM/",
}
for i = 65, 90 do
    local s = string.char(i)
    KEY_DISPLAY[s] = s
end
for i = 0, 9 do
    KEY_DISPLAY[tostring(i)] = tostring(i)
end


local function strip_key(k)
    return (k or ""):match("%[(.+)%]") or k or ""
end

local function key_display(raw)
    if not raw or raw == "" or raw == "NONE" then return "NONE" end
    return KEY_DISPLAY[raw] or raw
end


local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function lerp(a, b, t)    return a + (b - a) * clamp(t, 0, 1)  end

local function sw() return dx9.size().width  end
local function sh() return dx9.size().height end

local function mouse()
    local m = dx9.GetMouse()
    return m.x, m.y
end

local function in_box(bx, by, bw, bh)
    local mx, my = mouse()
    return mx >= bx and mx <= bx+bw and my >= by and my <= by+bh
end


local function tw(s) return dx9.CalcTextWidth(tostring(s)) end


local function rect(x,y,w,h,c)
    dx9.DrawFilledBox({x,y},{x+w,y+h},c)
end

local function outline(x,y,w,h,c)
    dx9.DrawLine({x,y},   {x+w,y},   c)
    dx9.DrawLine({x,y+h}, {x+w,y+h}, c)
    dx9.DrawLine({x,y},   {x,y+h},   c)
    dx9.DrawLine({x+w,y}, {x+w,y+h}, c)
end

local function text(x,y,c,s)
    dx9.DrawString({x,y},c,tostring(s))
end

local function text_c(cx,y,c,s)  
    local s_str = tostring(s)
    text(cx - tw(s_str)/2, y, c, s_str)
end


local function panel(x,y,w,h)
    rect(x,   y,   w,   h,   C.dark)
    rect(x+1, y+1, w-2, h-2, C.mid)
    rect(x+2, y+2, w-4, h-4, C.secbg)
    rect(x+3, y+3, w-6, h-6, C.bg)
end

local function sec_panel(x,y,w,h)
    rect(x,   y,   w,   h,   C.dark)
    rect(x+1, y+1, w-2, h-2, C.secbg)
    rect(x+2, y+2, w-4, h-4, C.bg)
end


local function sort_by_name(t)
    for i = 2, #t do
        local v = t[i]
        local j = i - 1
        while j >= 1 and t[j].name > v.name do
            t[j+1] = t[j]; j = j - 1
        end
        t[j+1] = v
    end
end


local S = _G._dx9ui_state
if not S then
    S = {

        visible      = true,
        pos          = {x=100, y=100},
        size         = {x=560, y=740},
        drag         = false,
        drag_start   = nil,
        drag_pos     = nil,

        active_tab   = nil,
        tabs         = {},

        active_drop  = nil,
        active_sld   = nil,  

        -- scroll
        scroll_drag  = false,
        scroll_start = 0,
        scroll_off   = 0,


        anim = {active=false, x=0, to=0, w=0, t=0},


        listening    = nil,   


        key          = "",
        prev_key     = "",
        lmb          = false,
        lmb_held     = false,
        prev_lmb     = false,
        rmb          = false,
        prev_rmb     = false,
        lmb_click    = false,  
        rmb_click    = false,


        flags        = {},
        keybinds     = {},  
        active_binds = {},

        -- watermark
        wm = {
            show     = true,
            rainbow  = true,
            hue      = 0,
            pos      = {x=0, y=50},
            drag     = false,
            drag_s   = nil,
            init     = false,
        },

        -- keybinds
        kb_hud = {
            show = true,
            pos  = {x=100, y=600},
            drag = false,
            drag_s = nil,
        },

        -- keybind windows (flag → {name, elem})
        kb_windows   = {},

        -- notifications
        notifs       = {},

        -- name
        name         = "dx9ui",

        -- timing
        t_prev       = os.clock(),
        dt           = 0,
    }
    _G._dx9ui_state = S
end


Flags        = S.flags
ActiveBinds  = S.active_binds


function Notify(title, msg, dur)
    S.notifs[#S.notifs+1] = {
        title    = title,
        msg      = msg,
        dur      = dur or 3,
        start    = os.clock(),
    }
end

local function draw_notifs()
    local now  = os.clock()
    local i    = 1
    local nw   = 250
    local nh   = 65
    local base_x = sw() - nw - 10

    while i <= #S.notifs do
        local n = S.notifs[i]
        local elapsed = now - n.start

        if elapsed >= n.dur then
            table.remove(S.notifs, i)
        else
            local ny = 100 + (i-1)*(nh+6)

            -- alpha fade in/out
            local alpha
            if elapsed < 0.3 then
                alpha = elapsed / 0.3
            elseif elapsed > n.dur - 0.3 then
                alpha = 1 - (elapsed - (n.dur-0.3)) / 0.3
            else
                alpha = 1
            end


            local function fade(col)
                return {
                    math.floor(col[1]*alpha),
                    math.floor(col[2]*alpha),
                    math.floor(col[3]*alpha),
                }
            end

            rect(base_x, ny, nw, nh, fade(C.secbg))
            outline(base_x, ny, nw, nh, fade(C.mid))

            text(base_x+12, ny+10, fade(C.text),   n.title)
            text(base_x+12, ny+26, fade(C.tabdim), n.msg)

            -- progress bar
            local prog   = elapsed / n.dur
            local bar_w  = nw - 16
            rect(base_x+8, ny+nh-12, bar_w,              3, fade(C.gray))
            rect(base_x+8, ny+nh-12, math.floor(bar_w*prog), 3, fade(C.accent))

            i = i + 1
        end
    end
end


local function draw_watermark()
    local wm = S.wm
    if not wm.show then return end

    -- rainbow hue tick
    wm.hue = (wm.hue + S.dt * 0.3) % 1

    local label  = "[ " .. S.name .. " ]"
    local lw     = tw(label)
    local bw     = lw + 16
    local bh     = 18

    -- init centre
    if not wm.init then
        wm.pos.x = sw()/2
        wm.init  = true
    end

    local x = wm.pos.x - bw/2
    local y = wm.pos.y

    -- drag
    if in_box(x, y, bw, bh) and S.lmb_click then
        wm.drag   = true
        local mx, my = mouse()
        wm.drag_s = {x=mx, y=my, ox=wm.pos.x, oy=wm.pos.y}
    end
    if wm.drag then
        if S.lmb_held then
            local mx, my = mouse()
            wm.pos.x = wm.drag_s.ox + (mx - wm.drag_s.x)
            wm.pos.y = wm.drag_s.oy + (my - wm.drag_s.y)
            x = wm.pos.x - bw/2
            y = wm.pos.y
        else
            wm.drag = false
        end
    end

    rect(x,   y,   bw, bh, C.secbg)
    rect(x+1, y+1, bw-2, bh-2, C.bg)


    local prefix = "[ "
    local suffix = " ]"
    local name   = S.name
    local px     = x + 8

    text(px, y+3, C.text, prefix)
    px = px + tw(prefix)

    if wm.rainbow then
        for ci = 1, #name do
            local ch  = name:sub(ci,ci)
            local h   = (ci / #name + wm.hue) % 1
            local r   = math.sin(h*6.28318+0)*0.5+0.5
            local g   = math.sin(h*6.28318+2)*0.5+0.5
            local b   = math.sin(h*6.28318+4)*0.5+0.5
            text(px, y+3, {r*255, g*255, b*255}, ch)
            px = px + tw(ch)
        end
    else
        text(px, y+3, C.accent, name)
        px = px + tw(name)
    end

    text(px, y+3, C.text, suffix)
end


local function draw_kb_hud()
    local hud = S.kb_hud
    if not hud.show then return end

    local vis = {}
    for _, kw in pairs(S.kb_windows) do
        if kw.elem and kw.elem.active then
            vis[#vis+1] = kw
        end
    end
    if #vis == 0 then return end

    sort_by_name(vis)

    local x     = hud.pos.x
    local y     = hud.pos.y
    local hw    = 202
    local row_h = 15
    local hh    = 55 + #vis*row_h + 8


    if in_box(x, y, hw, 30) and S.lmb_click then
        hud.drag   = true
        local mx, my = mouse()
        hud.drag_s = {x=mx, y=my, ox=x, oy=y}
    end
    if hud.drag then
        if S.lmb_held then
            local mx, my = mouse()
            hud.pos.x = hud.drag_s.ox + (mx - hud.drag_s.x)
            hud.pos.y = hud.drag_s.oy + (my - hud.drag_s.y)
            x = hud.pos.x; y = hud.pos.y
        else
            hud.drag = false
        end
    end

    rect(x,   y,   hw,   hh,   C.dark)
    rect(x+1, y+1, hw-2, hh-2, C.mid)
    rect(x+2, y+2, hw-4, hh-4, C.bg)

    text_c(x+hw/2, y+13, C.text, "keybinds")

    local line_y = y+28
    rect(x+20, line_y, hw-40, 1, C.accent)

    local list_y = y+35
    local box_h  = #vis*row_h + 8

    rect(x+12, list_y, hw-24, box_h, C.secbg)

    for i, kw in ipairs(vis) do
        local k   = key_display(kw.elem.key)
        local str = "[ "..k.." ] "..kw.name
        text(x+16, list_y+4+(i-1)*row_h, C.text, str)
    end
end


local ELEM_H = {
    toggle  = ELEM_TOG,
    slider  = ELEM_SLD,
    dropdown= ELEM_DROP,
    button  = ELEM_BTN,
    keybind = ELEM_KB,
}

local function section_height(sec)
    local h = SEC_HEAD + 10   
    for _, e in ipairs(sec.elements) do
        h = h + (ELEM_H[e.type] or 20)
    end
    return h
end


local function update_tab_anim(tab_list, ux, tab_w)
    local anim = S.anim
    if anim.active then
        anim.t    = anim.t + S.dt / 0.15
        anim.x    = lerp(anim.x, anim.to, math.min(anim.t, 1))
        if anim.t >= 1 then anim.active = false end
    else

        for i, t in ipairs(tab_list) do
            if t.active then
                anim.x = ux + 14 + (i-1)*(tab_w+4) + 4
                anim.w = tab_w - 8
                break
            end
        end
    end
end

local function draw_element(elem, ex, ey, col_w, vis_top, vis_bot)
    if ey + (ELEM_H[elem.type] or 20) < vis_top then return false end
    if ey > vis_bot then return false end

    if elem.type == "toggle" then

        local cbx = ex + 8
        local cby = ey
        rect(cbx, cby, 10, 10, C.dark)
        if elem.value then
            rect(cbx+1, cby+1, 8, 8, C.accent)
        else
            rect(cbx+1, cby+1, 8, 8, C.inactive)
        end
        text(ex+23, ey, C.text, elem.name)


        local name_w = tw(elem.name)
        if in_box(cbx, cby-2, name_w+20, 14) and S.lmb_click then
            elem.value = not elem.value
            if elem.flag then S.flags[elem.flag] = elem.value end
            if elem.callback then elem.callback(elem.value) end
        end


        if elem.keybind then
            local kb    = elem.keybind
            local disp  = kb.binding and "[...]" or "["..key_display(kb.key).."]"
            local dw    = tw(disp)
            local kbx   = ex + col_w - dw - 15
            local kby   = ey
            rect(kbx-3, kby, dw+6, 12, C.dark)
            rect(kbx-2, kby+1, dw+4, 10, C.bg)
            local kc = kb.binding and C.accent or C.text
            text(kbx, kby, kc, disp)

            if in_box(kbx-3, kby, dw+6, 12) and S.lmb_click then
                kb.binding = true
                S.listening = kb
            end
        end

    elseif elem.type == "keybind" then
        text(ex+8, ey, C.text, elem.name)
        local disp = elem.binding and "[...]" or "["..key_display(elem.key).."]"
        local dw   = tw(disp)
        local kbx  = ex + col_w - dw - 15
        local kby  = ey
        rect(kbx-3, kby, dw+6, 12, C.dark)
        rect(kbx-2, kby+1, dw+4, 10, C.bg)
        text(kbx, kby, elem.binding and C.accent or C.text, disp)

        if in_box(kbx-3, kby, dw+6, 12) and S.lmb_click then
            elem.binding = true
            S.listening  = elem
        end

    elseif elem.type == "slider" then
        text(ex+8, ey, C.text, elem.name)

        local sld_w = col_w - 40
        local sld_x = ex + 20
        local sld_y = ey + 16
        local pct   = (elem.value - elem.min) / (elem.max - elem.min)
        local fill  = math.floor(sld_w * pct)


        rect(ex+9, sld_y+3, 5, 1, C.text)

        local px2 = ex + col_w - 14
        rect(px2, sld_y+3, 5, 1, C.text)
        rect(px2+2, sld_y+1, 1, 5, C.text)


        rect(sld_x,   sld_y,   sld_w, 6, C.dark)
        rect(sld_x+1, sld_y+1, sld_w-2, 4, C.inactive)
        rect(sld_x+1, sld_y+1, fill,    4, C.accent)

        rect(sld_x+fill-2, sld_y-1, 4, 8, C.accent)

        local val_s = tostring(elem.value)..(elem.suffix or "")
        text_c(sld_x + sld_w/2, sld_y+8, C.text, val_s)


        if S.lmb_click then
            if in_box(ex+6, sld_y-2, 9, 9) then
                elem:set(elem.value - 1)
            elseif in_box(px2-3, sld_y-2, 9, 9) then
                elem:set(elem.value + 1)
            elseif in_box(sld_x, sld_y-2, sld_w, 10) then
                S.active_sld = {elem=elem, sld_x=sld_x, sld_w=sld_w}
                local mx = mouse()
                local p  = clamp((mx - sld_x) / sld_w, 0, 1)
                elem:set(elem.min + (elem.max - elem.min)*p)
            end
        end

    elseif elem.type == "dropdown" then
        text(ex+8, ey+2, C.text, elem.name)

        local dw  = col_w - 14
        local dbx = ex + 8
        local dby = ey + 17

        rect(dbx,   dby,   dw,   18, C.dark)
        rect(dbx+1, dby+1, dw-2, 16, C.bg)


        local disp
        if elem.multi then
            disp = table.concat(elem.selected, ", ")
        else
            disp = elem.selected or ""
        end
        local max_w = dw - 20
        if tw(disp) > max_w then
            local cut = disp
            for j = #disp, 1, -1 do
                cut = disp:sub(1,j).."..."
                if tw(cut) <= max_w then break end
            end
            disp = cut
        end
        text(dbx+5, dby+3, C.text, disp)


        local ax = dbx + dw - 9
        local ay = dby + 9
        if elem.open then
            rect(ax, ay, 5, 1, C.text)
        else
            rect(ax+2, ay-4, 1, 1, C.text)
            rect(ax+1, ay-3, 3, 1, C.text)
            rect(ax,   ay-2, 5, 1, C.text)
        end


        if in_box(dbx-2, dby-2, dw+4, 22) and S.lmb_click then
            if S.active_drop == elem then
                elem.open     = false
                S.active_drop = nil
            else
                if S.active_drop then
                    S.active_drop.open = false
                end
                elem.open     = true
                S.active_drop = elem
            end
        end

    elseif elem.type == "button" then
        local bw  = col_w - 14
        local bbx = ex + 8
        local bby = ey + 2
        rect(bbx,   bby,   bw,   18, C.dark)
        rect(bbx+1, bby+1, bw-2, 16, C.bg)


        if in_box(bbx, bby, bw, 18) then
            rect(bbx+1, bby+1, bw-2, 16, {25,25,25})
        end

        text_c(bbx+bw/2, bby+4, C.text, elem.name)

        if in_box(bbx-2, bby-2, bw+4, 22) and S.lmb_click then
            if elem.callback then elem.callback() end
        end
    end
end


local function draw_dropdown_overlay()
    local elem = S.active_drop
    if not elem or not elem.open then return end


    local tab = S.active_tab
    if not tab then return end

    local ux  = S.pos.x + 10
    local uy  = S.pos.y + 40
    local uw  = S.size.x - 20
    local uh  = S.size.y - 50
    local lx  = ux + 18
    local rx  = ux + uw/2 + 10
    local cw  = uw/2 - 20
    local cy  = uy + 10

    local lY = cy - tab.scroll
    local rY = cy - tab.scroll

    for _, sec in ipairs(tab.sections) do
        local sx = sec.side == "left" and lx or rx
        local sy = sec.side == "left" and lY or rY

        for _, e in ipairs(sec.elements) do
            if e == elem then
             
                local ey = sy + SEC_HEAD
                for _, prev in ipairs(sec.elements) do
                    if prev == e then break end
                    ey = ey + (ELEM_H[prev.type] or 20)
                end

                local dbx  = sx + 8
                local dby  = ey + 17
                local dw   = cw - 14
                local opt_y = dby + 20
                local opt_h = #elem.items * 15 + 10

                rect(dbx,   opt_y,   dw,   opt_h, C.dark)
                rect(dbx+1, opt_y+1, dw-2, opt_h-2, C.bg)

                for i, item in ipairs(elem.items) do
                    local iy = opt_y + 5 + (i-1)*15
                    local sel = false
                    if elem.multi then
                        for _, sv in ipairs(elem.selected) do
                            if sv == item then sel = true; break end
                        end
                    else
                        sel = elem.selected == item
                    end
                    text(dbx+5, iy, sel and C.accent or C.text, item)

                    if in_box(dbx, iy-2, dw, 15) and S.lmb_click then
                        if elem.multi then
                            local found = false
                            for k, sv in ipairs(elem.selected) do
                                if sv == item then
                                    table.remove(elem.selected, k)
                                    found = true; break
                                end
                            end
                            if not found then
                                elem.selected[#elem.selected+1] = item
                            end
                            elem:set(elem.selected)
                        else
                            elem:set(item)
                            elem.open     = false
                            S.active_drop = nil
                        end
                    end
                end


                if S.lmb_click then
                    if not in_box(dbx-2, dby-2, dw+4, 22) and
                       not in_box(dbx-2, opt_y-2, dw+4, opt_h+4) then
                        elem.open     = false
                        S.active_drop = nil
                    end
                end

                return
            end
        end

        if sec.side == "left" then lY = lY + section_height(sec) + COL_GAP
        else                       rY = rY + section_height(sec) + COL_GAP end
    end
end


local function render_ui(win)
    if not S.visible then return end

    local x = S.pos.x
    local y = S.pos.y
    local w = S.size.x
    local h = S.size.y


    panel(x, y, w, h)


    local n_tabs = #win.tabs
    local tab_w  = math.floor((w - 28 - (n_tabs-1)*4) / n_tabs)
    local tab_y  = y + 5
    local tab_h  = 28

    for i, tab in ipairs(win.tabs) do
        local tx  = x + 14 + (i-1)*(tab_w+4)
        local col = tab.active and C.accent or C.tabdim
        text_c(tx + tab_w/2, tab_y+8, col, tab.name)

        if in_box(tx, tab_y, tab_w, tab_h) and S.lmb_click then
            if S.active_tab ~= tab then

                local dest_x = x + 14 + (i-1)*(tab_w+4) + 4
                S.anim = {active=true, x=S.anim.x, to=dest_x, w=tab_w-8, t=0}
                if S.active_tab then S.active_tab.active = false end
                S.active_tab = tab
                tab.active   = true

                if S.active_drop then
                    S.active_drop.open = false
                    S.active_drop = nil
                end
            end
        end
    end


    update_tab_anim(win.tabs, x, tab_w)
    local anim = S.anim
    rect(math.floor(anim.x), y+33, anim.w, 3, C.accent)


    local ux = x + 10
    local uy = y + 40
    local uw = w - 20
    local uh = h - 50


    rect(ux,   uy,   uw,   uh,   C.dark)
    rect(ux+1, uy+1, uw-2, uh-2, C.mid)
    rect(ux+2, uy+2, uw-4, uh-4, C.secbg)
    rect(ux+3, uy+3, uw-6, uh-6, C.mid)
    rect(ux+4, uy+4, uw-8, uh-8, C.bg)

    local tab = S.active_tab
    if not tab then return end

    local cx  = ux + 10
    local cy  = uy + 10
    local cw  = uw - 20
    local ch  = uh - 20

    local lx  = cx + 8
    local rx  = cx + cw/2 + 10
    local col_w = cw/2 - 20

    local vis_top = cy
    local vis_bot = cy + ch


    local lH, rH = 0, 0
    for _, sec in ipairs(tab.sections) do
        local sh2 = section_height(sec) + COL_GAP
        if sec.side == "left" then lH = lH + sh2 else rH = rH + sh2 end
    end
    local max_scroll = math.max(0, math.max(lH, rH) - ch + 40)
    tab.scroll = clamp(tab.scroll or 0, 0, max_scroll)

    local lY = cy - tab.scroll
    local rY = cy - tab.scroll


    for _, sec in ipairs(tab.sections) do
        local sx  = sec.side == "left" and lx or rx
        local sy  = sec.side == "left" and lY or rY
        local sh2 = section_height(sec)

        if sy + sh2 > vis_top and sy < vis_bot then

            sec_panel(sx, sy, col_w, sh2)
            text_c(sx+col_w/2, sy+8, C.text, sec.name)

            local ey = sy + SEC_HEAD
            for _, elem in ipairs(sec.elements) do
                draw_element(elem, sx, ey, col_w, vis_top, vis_bot)
                ey = ey + (ELEM_H[elem.type] or 20)
            end
        end

        if sec.side == "left" then lY = lY + sh2 + COL_GAP
        else                       rY = rY + sh2 + COL_GAP end
    end


    if max_scroll > 0 then
        local bx  = cx + cw - 8
        local by  = cy
        local bh  = ch
        rect(bx, by, 4, bh, C.dark)

        local thumb_h   = math.max(20, bh * (bh / (max_scroll + bh)))
        local thumb_pos = (tab.scroll / max_scroll) * (bh - thumb_h)
        rect(bx, by+thumb_pos, 4, thumb_h, C.accent)

        if in_box(bx-2, by+thumb_pos, 8, thumb_h) and S.lmb_click then
            S.scroll_drag  = true
            local _, my    = mouse()
            S.scroll_start = my
            S.scroll_off   = tab.scroll
        end
        if S.scroll_drag then
            if S.lmb_held then
                local _, my  = mouse()
                local delta  = my - S.scroll_start
                tab.scroll   = clamp(S.scroll_off + delta/(bh-thumb_h)*max_scroll, 0, max_scroll)
            else
                S.scroll_drag = false
            end
        end
    end


    if in_box(x, y, w, 35) and S.lmb_click and not S.drag then
        S.drag      = true
        local mx, my = mouse()
        S.drag_start = {x=mx, y=my}
        S.drag_pos   = {x=x,  y=y}
    end
    if S.drag then
        if S.lmb_held then
            local mx, my = mouse()
            S.pos.x = S.drag_pos.x + (mx - S.drag_start.x)
            S.pos.y = S.drag_pos.y + (my - S.drag_start.y)
        else
            S.drag = false
        end
    end
end


local function update_input()
    local now    = os.clock()
    S.dt         = math.min(now - S.t_prev, 0.1)
    S.t_prev     = now

    S.prev_lmb   = S.lmb
    S.prev_rmb   = S.rmb
    S.prev_key   = S.key

    S.lmb        = dx9.isLeftClickHeld()
    S.lmb_click  = S.lmb and not S.prev_lmb
    S.rmb        = dx9.isRightClickHeld()
    S.rmb_click  = S.rmb and not S.prev_rmb
    S.lmb_held   = S.lmb

    local raw_key = dx9.GetKey() or ""
    S.key = raw_key

    local key_new = raw_key ~= "" and raw_key ~= "[None]" and raw_key ~= S.prev_key


    if S.listening then
        if key_new then
            local k = strip_key(raw_key)
            if k == "BACK" then k = "NONE" end
            S.listening.key     = k
            S.listening.binding = false


            if S.listening.flag then
                local kw = S.kb_windows[S.listening.flag]
                if kw then kw.elem.key = k end
            end

            if S.listening.callback then S.listening.callback(k) end
            S.listening = nil
        end
        return
    end


    if win_toggle_key and key_new then
        if raw_key == win_toggle_key then
            S.visible = not S.visible
            if not S.visible and S.active_drop then
                S.active_drop.open = false
                S.active_drop = nil
            end
        end
    end


    for flag, kb in pairs(S.keybinds) do
        local pressed = (S.key == "["..kb.key.."]")
        if pressed and not kb._last then
            kb.active      = not kb.active
            S.active_binds[flag] = kb.active
            if kb.callback then kb.callback(kb.active) end
        end
        kb._last = pressed
    end

    -- slider drag
    if S.active_sld then
        if S.lmb_held then
            local mx = mouse()
            local a  = S.active_sld
            local p  = clamp((mx - a.sld_x) / a.sld_w, 0, 1)
            a.elem:set(a.elem.min + (a.elem.max - a.elem.min)*p)
        else
            S.active_sld = nil
        end
    end
end


library = {}

function library:Window(cfg)
    S.name          = cfg.name or "dx9ui"
    win_toggle_key  = cfg.toggle_key and ("["..cfg.toggle_key:upper().."]") or nil

    local win = {tabs = {}}


    S.wm.pos.x = sw() / 2
    S.wm.init  = true

    function win:Tab(tcfg)
        local tab = {
            name      = tcfg.name,
            active    = (#self.tabs == 0), 
            sections  = {},
            scroll    = 0,
            max_scroll= 0,
        }
        self.tabs[#self.tabs+1] = tab
        S.tabs = self.tabs

        if tab.active then S.active_tab = tab end

        function tab:Section(scfg)
            local sec = {
                name     = scfg.name,
                side     = scfg.side or "left",
                elements = {},
            }
            self.sections[#self.sections+1] = sec



            function sec:Toggle(ecfg)
                local elem = {
                    type     = "toggle",
                    name     = ecfg.name,
                    flag     = ecfg.flag,
                    value    = ecfg.default or false,
                    callback = ecfg.callback,
                    keybind  = nil,
                }
                if elem.flag then S.flags[elem.flag] = elem.value end

                function elem:set(v)
                    self.value = v
                    if self.flag then S.flags[self.flag] = v end
                    if self.callback then self.callback(v) end
                end

                function elem:AddKeybind(kbcfg)
                    local kb = {
                        name     = kbcfg.name,
                        flag     = kbcfg.flag,
                        key      = kbcfg.default or "NONE",
                        callback = kbcfg.callback,
                        active   = false,
                        binding  = false,
                        _last    = false,
                    }
                    self.keybind = kb

                    if kbcfg.flag then
                        S.keybinds[kbcfg.flag]     = kb
                        S.active_binds[kbcfg.flag] = false
                        S.kb_windows[kbcfg.flag]   = {name=kbcfg.name, elem=kb}
                    end
                end

                self.elements[#self.elements+1] = elem
                return elem
            end

            function sec:Slider(ecfg)
                local elem = {
                    type     = "slider",
                    name     = ecfg.name,
                    flag     = ecfg.flag,
                    min      = ecfg.min or 0,
                    max      = ecfg.max or 100,
                    value    = ecfg.default or 50,
                    suffix   = ecfg.suffix or "",
                    callback = ecfg.callback,
                }
                if elem.flag then S.flags[elem.flag] = elem.value end

                function elem:set(v)
                    self.value = clamp(math.floor(v+0.5), self.min, self.max)
                    if self.flag then S.flags[self.flag] = self.value end
                    if self.callback then self.callback(self.value) end
                end

                self.elements[#self.elements+1] = elem
                return elem
            end

            function sec:Dropdown(ecfg)
                local elem = {
                    type     = "dropdown",
                    name     = ecfg.name,
                    flag     = ecfg.flag,
                    items    = ecfg.items or {},
                    multi    = ecfg.multi or false,
                    selected = ecfg.multi and {} or (ecfg.default or (ecfg.items and ecfg.items[1] or "")),
                    open     = false,
                    callback = ecfg.callback,
                }
                if elem.flag then S.flags[elem.flag] = elem.selected end

                function elem:set(v)
                    self.selected = v
                    if self.flag then S.flags[self.flag] = v end
                    if self.callback then self.callback(v) end
                end

                self.elements[#self.elements+1] = elem
                return elem
            end

            function sec:Button(ecfg)
                local elem = {
                    type     = "button",
                    name     = ecfg.name,
                    flag     = ecfg.flag,
                    callback = ecfg.callback,
                }
                self.elements[#self.elements+1] = elem
                return elem
            end

            function sec:Keybind(ecfg)
                local elem = {
                    type     = "keybind",
                    name     = ecfg.name,
                    flag     = ecfg.flag,
                    key      = ecfg.default or "NONE",
                    callback = ecfg.callback,
                    active   = false,
                    binding  = false,
                    _last    = false,
                }
                if ecfg.flag then
                    S.keybinds[ecfg.flag]     = elem
                    S.active_binds[ecfg.flag] = false
                    S.kb_windows[ecfg.flag]   = {name=ecfg.name, elem=elem}
                end

                self.elements[#self.elements+1] = elem
                return elem
            end

            return sec
        end

        return tab
    end


    function win:Render()
        update_input()
        render_ui(self)
        draw_dropdown_overlay()
        draw_watermark()
        draw_kb_hud()
        draw_notifs()
    end

    return win
end


function library:Watermark(cfg)
    S.name         = cfg.name    or S.name
    S.wm.show      = (cfg.show   ~= nil) and cfg.show    or S.wm.show
    S.wm.rainbow   = (cfg.rainbow~= nil) and cfg.rainbow or S.wm.rainbow
end
