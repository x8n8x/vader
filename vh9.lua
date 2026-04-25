dx9.ShowConsole(true)

if _G.VDX == nil then
    _G.VDX = {
        Accent     = {255, 200, 69},
        Font       = {255, 255, 255},
        Black      = {0,   0,   0},
        Outline    = {56,  56,  56},
        Panel      = {46,  46,  46},
        Background = {21,  21,  21},
        Dark       = {12,  12,  12},
        Grey       = {120, 120, 120},

        RainbowHue = 0,
        Rainbow    = {255, 0, 0},

        Flags      = {},
        Windows    = {},
        Notifs     = {},

        WatermarkText = "",
        WMPos = {x=10, y=10},
        WMDragging = false,
        WMOffset   = nil,

        OpenElement = nil,

        Mouse      = {x=0, y=0},
        Key        = "[None]",
        FirstRun   = nil,
    }
end

local G = _G.VDX

if     G.FirstRun == nil  then G.FirstRun = true
elseif G.FirstRun == true then G.FirstRun = false
end

G.Mouse = dx9.GetMouse()
G.Key   = dx9.GetKey()

do
    G.RainbowHue = G.RainbowHue + 3
    if G.RainbowHue > 1530 then G.RainbowHue = 0 end
    local h = G.RainbowHue
    if     h <= 255  then G.Rainbow = {255,      h,       0}
    elseif h <= 510  then G.Rainbow = {510-h,    255,     0}
    elseif h <= 765  then G.Rainbow = {0,         255,    h-510}
    elseif h <= 1020 then G.Rainbow = {0,         1020-h, 255}
    elseif h <= 1275 then G.Rainbow = {h-1020,    0,      255}
    else                  G.Rainbow = {255,        0,      1530-h}
    end
end

local function Clamp(v,lo,hi)
    if v<lo then return lo end
    if v>hi then return hi end
    return v
end

local function MouseIn(x1,y1,x2,y2)
    local m=G.Mouse
    return m.x>x1 and m.y>y1 and m.x<x2 and m.y<y2
end

local function MakeCS()
    return {holding=false, hovered=false, fired=false}
end

local function TickCS(s, x1,y1,x2,y2)
    s.fired   = false
    s.hovered = MouseIn(x1,y1,x2,y2)
    if s.hovered then
        if dx9.isLeftClickHeld() then
            s.holding = true
        else
            if s.holding then s.fired=true s.holding=false end
        end
    else
        s.holding = false
    end
end

local function HueRGB(h)
    if     h<=255  then return {255,     h,     0}
    elseif h<=510  then return {510-h,   255,   0}
    elseif h<=765  then return {0,       255,   h-510}
    elseif h<=1020 then return {0,       1020-h,255}
    elseif h<=1275 then return {h-1020,  0,     255}
    else                return {255,     0,     1530-h}
    end
end

local function Blend(top, t)
    local s = t*765
    local r,g,b
    if s<255 then
        r=top[1]*(s/255); g=top[2]*(s/255); b=top[3]*(s/255)
    elseif s<510 then
        r=top[1]+(s-255); g=top[2]+(s-255); b=top[3]+(s-255)
    else
        local d=s-510
        r=255-d; g=255-d; b=255-d
    end
    return {Clamp(r,0,255),Clamp(g,0,255),Clamp(b,0,255)}
end

local function RGBHex(c)
    local function b(v)
        v=math.floor(v+0.5)
        local h2=""
        local d="0123456789ABCDEF"
        if v==0 then return "00" end
        while v>0 do
            local i=math.fmod(v,16)+1
            h2=string.sub(d,i,i)..h2
            v=math.floor(v/16)
        end
        if #h2==1 then h2="0"..h2 end
        return h2
    end
    return "#"..b(c[1])..b(c[2])..b(c[3])
end

local function Trim(s, maxW)
    while dx9.CalcTextWidth(s) > maxW and #s > 0 do
        s = s:sub(1,-2)
    end
    return s
end

local function TickNotifs()
    local now = os.clock()
    local ny  = 10
    local i   = 1
    while i <= #G.Notifs do
        local n = G.Notifs[i]
        local elapsed = now - n.start
        if elapsed > n.length then
            table.remove(G.Notifs,i)
        else
            local w = dx9.CalcTextWidth(n.text)+16
            local h = 20
            local x = 10

            dx9.DrawFilledBox({x,    ny},  {x+w,   ny+h},   G.Black)
            dx9.DrawFilledBox({x+1,  ny+1},{x+w-1, ny+h-1}, G.Panel)
            dx9.DrawFilledBox({x+2,  ny+2},{x+w-2, ny+h-2}, G.Background)
            local frac = elapsed/n.length
            local bw   = math.floor((w-4)*frac+0.5)
            dx9.DrawFilledBox({x+2,  ny+h-3},{x+2+bw,ny+h-2}, n.color or G.Accent)
            dx9.DrawString({x+6, ny+3}, G.Font, n.text)

            ny = ny + h + 4
            i  = i + 1
        end
    end
end

local function TickWatermark()
    if G.WatermarkText=="" then return end
    local text = G.WatermarkText
    local w = dx9.CalcTextWidth(text)+14
    local h = 18
    local x,y = G.WMPos.x, G.WMPos.y

    if dx9.isLeftClickHeld() and MouseIn(x,y,x+w,y+h) then
        if not G.WMDragging then
            G.WMDragging=true
            G.WMOffset={G.Mouse.x-x, G.Mouse.y-y}
        end
    end
    if not dx9.isLeftClickHeld() then G.WMDragging=false G.WMOffset=nil end
    if G.WMDragging and G.WMOffset then
        G.WMPos.x = G.Mouse.x-G.WMOffset[1]
        G.WMPos.y = G.Mouse.y-G.WMOffset[2]
        x,y = G.WMPos.x, G.WMPos.y
    end

    dx9.DrawFilledBox({x,    y},  {x+w,   y+h},   G.Black)
    dx9.DrawFilledBox({x+1,  y+1},{x+w-1, y+h-1}, G.Panel)
    dx9.DrawFilledBox({x+2,  y+2},{x+w-2, y+h-2}, G.Background)
    dx9.DrawFilledBox({x+2,  y+2},{x+w-2, y+4},   G.Rainbow)
    dx9.DrawString({x+5,y+5}, G.Font, text)
end

local function MakePicker(flag, name, defColor, defAlpha)
    defColor = defColor or {255,255,255}
    defAlpha = defAlpha or 0

    if G.Flags[flag]==nil then
        G.Flags[flag]={color=defColor, alpha=defAlpha}
    end

    local pk = {
        flag     = flag,
        name     = name,
        hueIdx   = 100,
        blendIdx = 103,
        cs       = MakeCS(),
    }

    function pk:_renderSwatch(sx,sy)
        local col = (G.Flags[self.flag] or {}).color or {255,255,255}
        local open = (G.OpenElement==self)
        dx9.DrawFilledBox({sx,sy},{sx+14,sy+10}, open and G.Accent or G.Black)
        dx9.DrawFilledBox({sx+1,sy+1},{sx+13,sy+9}, col)
        TickCS(self.cs, sx,sy,sx+14,sy+10)
        if self.cs.fired then
            if G.OpenElement==self then G.OpenElement=nil
            else G.OpenElement=self end
        end
    end

    function pk:_renderPicker()
        local accumH = 0
        local topColor = {255,0,0}
        for j=1,self.hueIdx do
            accumH = accumH + 1530/205
        end
        topColor = HueRGB(Clamp(accumH,0,1530))

        local finalColor = Blend(topColor, self.blendIdx/205)

        local scr = dx9.size()
        local pw, ph = 232, 112
        local ppx = Clamp(G.Mouse.x+8, 4, scr.width  - pw - 4)
        local ppy = Clamp(G.Mouse.y-8, 4, scr.height - ph - 4)

        dx9.DrawFilledBox({ppx,    ppy},  {ppx+pw,   ppy+ph},   G.Black)
        dx9.DrawFilledBox({ppx+1,  ppy+1},{ppx+pw-1, ppy+ph-1}, G.Panel)
        dx9.DrawFilledBox({ppx+2,  ppy+2},{ppx+pw-2, ppy+ph-2}, G.Background)
        dx9.DrawFilledBox({ppx+2,  ppy+2},{ppx+pw-2, ppy+4},    G.Accent)
        dx9.DrawString({ppx+5, ppy+5}, G.Font, self.name)

        dx9.DrawFilledBox({ppx+pw-28,ppy+18},{ppx+pw-8,ppy+ph-8}, G.Black)
        dx9.DrawFilledBox({ppx+pw-27,ppy+19},{ppx+pw-9,ppy+ph-9}, finalColor)

        local barX = ppx+8
        local barW = pw-48
        local barH = 14

        local b1Y = ppy+18
        local hStep = 1530/barW
        local hAccum = 0
        for i=0,barW do
            local col = HueRGB(Clamp(hAccum,0,1530))
            dx9.DrawBox({barX+i,b1Y},{barX+i,b1Y+barH}, col)
            hAccum = hAccum + hStep
        end
        dx9.DrawBox({barX,b1Y},{barX+barW,b1Y+barH}, G.Black)
        local hcx = barX + math.floor(self.hueIdx * barW/205 + 0.5)
        dx9.DrawFilledBox({hcx-1,b1Y-1},{hcx+1,b1Y+barH+1}, G.Black)
        dx9.DrawFilledBox({hcx,b1Y},{hcx,b1Y+barH}, {255,255,255})

        if dx9.isLeftClickHeld() and MouseIn(barX,b1Y,barX+barW,b1Y+barH) then
            local rel = Clamp(G.Mouse.x - barX, 0, barW)
            self.hueIdx = math.floor(rel*205/barW + 0.5)
            G.Flags[self.flag] = {color=finalColor, alpha=(G.Flags[self.flag] or {}).alpha or 0}
        end

        local b2Y = b1Y + barH + 6
        for i=0,barW do
            local t = i/barW
            local col = Blend(topColor, t)
            dx9.DrawBox({barX+i,b2Y},{barX+i,b2Y+barH}, col)
        end
        dx9.DrawBox({barX,b2Y},{barX+barW,b2Y+barH}, G.Black)
        local bcx = barX + math.floor(self.blendIdx * barW/205 + 0.5)
        dx9.DrawFilledBox({bcx-1,b2Y-1},{bcx+1,b2Y+barH+1}, G.Black)
        dx9.DrawFilledBox({bcx,b2Y},{bcx,b2Y+barH}, {255,255,255})

        if dx9.isLeftClickHeld() and MouseIn(barX,b2Y,barX+barW,b2Y+barH) then
            local rel = Clamp(G.Mouse.x - barX, 0, barW)
            self.blendIdx = math.floor(rel*205/barW + 0.5)
            G.Flags[self.flag] = {color=finalColor, alpha=(G.Flags[self.flag] or {}).alpha or 0}
        end

        dx9.DrawString({barX, b2Y+barH+4}, G.Grey, RGBHex(finalColor))

        if dx9.isLeftClickHeld() and not MouseIn(ppx,ppy,ppx+pw,ppy+ph) then
            G.OpenElement = nil
        end
    end

    return pk
end

local function BuildToggle(sec, opts)
    local name     = opts.name     or "Toggle"
    local flag     = opts.flag     or name
    local default  = opts.default  or false
    local callback = opts.callback or function() end

    if G.Flags[flag]==nil then G.Flags[flag]=default end

    local cs      = MakeCS()
    local pickers = {}

    local elem = {height=16, _pickers=pickers}

    function elem:_render(ex,ey,ew)
        local val = G.Flags[flag]

        local bx,by = ex, ey+3
        dx9.DrawFilledBox({bx,by},{bx+10,by+10}, G.Black)
        dx9.DrawFilledBox({bx+1,by+1},{bx+9,by+9}, val and G.Accent or G.Dark)

        dx9.DrawString({ex+14, ey+2}, G.Font, Trim(name, ew-30))

        local swX = ex+ew-2
        for i=#pickers,1,-1 do
            swX = swX-16
            pickers[i]:_renderSwatch(swX, ey+3)
        end

        TickCS(cs, ex,ey,ex+ew,ey+16)
        if cs.fired then
            G.Flags[flag] = not G.Flags[flag]
            callback(G.Flags[flag])
        end

        for _,pk in ipairs(pickers) do
            if G.OpenElement==pk then pk:_renderPicker() end
        end
    end

    function elem:colorpicker(pkOpts)
        local pk = MakePicker(
            pkOpts.flag  or pkOpts.name or flag.."_col",
            pkOpts.name  or "Color",
            pkOpts.color or {255,255,255},
            pkOpts.alpha or 0
        )
        table.insert(pickers, pk)
        return self
    end

    return elem
end

local function BuildSlider(sec, opts)
    local name     = opts.name     or opts.Name or "Slider"
    local flag     = opts.flag     or name
    local min      = opts.min      or opts.minimum or 0
    local max      = opts.max      or opts.maximum or 100
    local default  = opts.default  or opts.value  or min
    local suffix   = opts.suffix   or ""
    local interval = opts.interval or opts.decimal or 1
    local callback = opts.callback or function() end

    if G.Flags[flag]==nil then G.Flags[flag]=Clamp(default,min,max) end

    local cs = MakeCS()
    local elem = {height=30}

    function elem:_render(ex,ey,ew)
        local val = G.Flags[flag]

        dx9.DrawString({ex, ey}, G.Font, Trim(name, ew-40))
        local vs = tostring(val)..suffix
        dx9.DrawString({ex+ew-dx9.CalcTextWidth(vs), ey}, G.Grey, vs)

        local ty = ey+16
        local th = 8
        dx9.DrawFilledBox({ex,   ty},{ex+ew,  ty+th}, G.Black)
        dx9.DrawFilledBox({ex+1, ty+1},{ex+ew-1,ty+th-1}, G.Dark)
        local frac = (max>min) and (val-min)/(max-min) or 0
        local fw   = math.floor(frac*(ew-2)+0.5)
        if fw>0 then
            dx9.DrawFilledBox({ex+1,ty+1},{ex+1+fw,ty+th-1}, G.Accent)
        end

        TickCS(cs, ex,ty,ex+ew,ty+th)
        if cs.holding or (cs.hovered and dx9.isLeftClickHeld()) then
            local rel  = Clamp(G.Mouse.x-ex, 0, ew)
            local raw  = (rel/ew)*(max-min)+min
            local mult = 1/interval
            local rounded = math.floor(raw*mult+0.5)/mult
            rounded = Clamp(rounded,min,max)
            if rounded~=G.Flags[flag] then
                G.Flags[flag]=rounded
                callback(rounded)
            end
        end
    end

    return elem
end

local function BuildDropdown(sec, opts)
    local name     = opts.name     or opts.Name or "Dropdown"
    local flag     = opts.flag     or name
    local items    = opts.items    or {}
    local multi    = opts.multi    or false
    local callback = opts.callback or function() end
    local default  = opts.default  or opts.value or (multi and {} or (items[1] or ""))

    if G.Flags[flag]==nil then G.Flags[flag]= multi and {} or default end

    local cs      = MakeCS()
    local ddState = {open=false, itemCS={}}
    local elem    = {height=30, _dd=ddState}

    function elem:_render(ex,ey,ew)
        local val = G.Flags[flag]
        local disp
        if multi then
            if type(val)=="table" and #val>0 then disp=table.concat(val,", ") else disp="none" end
        else
            disp = tostring(val or "none")
        end

        dx9.DrawString({ex,ey}, G.Font, Trim(name,ew-4))

        local bx,by,bw,bh = ex,ey+14,ew,14
        dx9.DrawFilledBox({bx,   by},{bx+bw,  by+bh},   G.Black)
        dx9.DrawFilledBox({bx+1, by+1},{bx+bw-1,by+bh-1}, G.Dark)
        dx9.DrawString({bx+4,by+1}, G.Font, Trim(disp,bw-18))
        dx9.DrawString({bx+bw-10,by+1}, G.Accent, ddState.open and "-" or "+")

        TickCS(cs,bx,by,bx+bw,by+bh)
        if cs.fired then
            if G.OpenElement==ddState then
                G.OpenElement=nil ddState.open=false
            else
                G.OpenElement=ddState ddState.open=true
            end
        end

        if G.OpenElement==ddState and ddState.open then
            local ih   = 14
            local ly   = by+bh+2
            local lh   = ih*#items+4
            dx9.DrawFilledBox({bx,ly},{bx+bw,ly+lh}, G.Black)
            dx9.DrawFilledBox({bx+1,ly+1},{bx+bw-1,ly+lh-1}, G.Panel)

            for i,item in ipairs(items) do
                local iy = ly+2+(i-1)*ih
                local isSel
                if multi then
                    isSel=false
                    if type(val)=="table" then
                        for _,v in ipairs(val) do if v==item then isSel=true break end end
                    end
                else isSel=(val==item) end

                if MouseIn(bx+1,iy,bx+bw-1,iy+ih) then
                    dx9.DrawFilledBox({bx+1,iy},{bx+bw-1,iy+ih}, G.Dark)
                end
                dx9.DrawString({bx+5,iy}, isSel and G.Accent or G.Font, item)

                if not ddState.itemCS[i] then ddState.itemCS[i]=MakeCS() end
                TickCS(ddState.itemCS[i],bx+1,iy,bx+bw-1,iy+ih)
                if ddState.itemCS[i].fired then
                    if multi then
                        if type(G.Flags[flag])~="table" then G.Flags[flag]={} end
                        local found=false
                        for j,v in ipairs(G.Flags[flag]) do
                            if v==item then table.remove(G.Flags[flag],j) found=true break end
                        end
                        if not found then table.insert(G.Flags[flag],item) end
                        callback(G.Flags[flag])
                    else
                        G.Flags[flag]=item
                        G.OpenElement=nil ddState.open=false
                        callback(item)
                    end
                end
            end

            if dx9.isLeftClickHeld() and not MouseIn(bx,by,bx+bw,ly+lh) then
                G.OpenElement=nil ddState.open=false
            end
        end
    end

    return elem
end

local function BuildButton(sec, opts)
    local name     = opts.name     or opts.Name or "Button"
    local callback = opts.callback or function() end
    local cs       = MakeCS()
    local elem     = {height=18}

    function elem:_render(ex,ey,ew)
        local bg = cs.hovered and G.Accent or G.Dark
        local tc = cs.hovered and G.Dark   or G.Font
        dx9.DrawFilledBox({ex,ey},{ex+ew,ey+18}, G.Black)
        dx9.DrawFilledBox({ex+1,ey+1},{ex+ew-1,ey+17}, bg)
        local tw=dx9.CalcTextWidth(name)
        dx9.DrawString({ex+math.floor((ew-tw)/2), ey+3}, tc, name)
        TickCS(cs,ex,ey,ex+ew,ey+18)
        if cs.fired then callback() end
    end

    return elem
end

local function BuildLabel(sec, opts)
    local name  = opts.name  or opts.Name or ""
    local color = opts.color or G.Font
    local elem  = {height=14}

    function elem:_render(ex,ey,ew)
        dx9.DrawString({ex,ey+1}, color, Trim(name,ew))
    end

    function elem:setName(n) name=n end

    return elem
end

local function BuildColorpicker(sec, opts)
    local flag = opts.flag  or opts.name or "cp"
    local pk   = MakePicker(flag, opts.name or "Color", opts.color, opts.alpha)
    local elem = {height=16}

    function elem:_render(ex,ey,ew)
        dx9.DrawString({ex,ey+1}, G.Font, Trim(pk.name, ew-20))
        pk:_renderSwatch(ex+ew-16, ey+2)
        if G.OpenElement==pk then pk:_renderPicker() end
    end

    return elem
end

local function BuildKeybind(sec, opts)
    local name     = opts.name     or opts.Name or "Keybind"
    local flag     = opts.flag     or name
    local initKey  = opts.key      or "[NONE]"
    local initMode = opts.mode     or "Toggle"
    local callback = opts.callback or function() end

    if G.Flags[flag]==nil then
        G.Flags[flag]={key=initKey, mode=initMode, active=false}
    end

    local cs       = MakeCS()
    local modeCS   = MakeCS()
    local reading  = false
    local prevHeld = false

    local modeList = {"Hold","Toggle","Always"}
    local modeIdx  = 1
    for i,v in ipairs(modeList) do
        if v==initMode then modeIdx=i break end
    end

    local elem = {height=16}

    function elem:_render(ex,ey,ew)
        local kf  = G.Flags[flag]
        local kStr = reading and "..." or tostring(kf.key or "[NONE]")
        local mStr = "["..tostring(kf.mode or "Toggle").."]"

        dx9.DrawString({ex,ey+2}, G.Font, Trim(name,ew-80))

        local mW = dx9.CalcTextWidth(mStr)+8
        local mX = ex+ew-mW-dx9.CalcTextWidth(kStr)-14
        dx9.DrawFilledBox({mX-1,ey},{mX+mW+1,ey+16}, G.Black)
        dx9.DrawFilledBox({mX,  ey+1},{mX+mW,ey+15},  G.Dark)
        dx9.DrawString({mX+4,ey+2}, G.Accent, mStr)
        TickCS(modeCS,mX,ey,mX+mW+2,ey+16)
        if modeCS.fired then
            modeIdx = (modeIdx % #modeList)+1
            kf.mode = modeList[modeIdx]
            callback(kf)
        end

        local kW = dx9.CalcTextWidth(kStr)+10
        local kX = ex+ew-kW
        dx9.DrawFilledBox({kX-1,ey},{kX+kW+1,ey+16}, G.Black)
        dx9.DrawFilledBox({kX,  ey+1},{kX+kW,ey+15},  G.Dark)
        dx9.DrawString({kX+4,ey+2}, reading and G.Accent or G.Grey, kStr)
        TickCS(cs,kX,ey,kX+kW+2,ey+16)
        if cs.fired then reading=true end

        if reading then
            local k=G.Key
            if k and k~="[None]" and k~="[Unknown]" and k~="[LBUTTON]" then
                kf.key=k reading=false callback(kf)
            end
        end

        if kf.mode=="Always" then
            kf.active=true
        elseif kf.key and kf.key~="[NONE]" then
            local pressed=(G.Key==kf.key)
            if kf.mode=="Toggle" then
                if pressed and not prevHeld then
                    kf.active=not kf.active prevHeld=true callback(kf)
                elseif not pressed then prevHeld=false end
            elseif kf.mode=="Hold" then
                kf.active=pressed
            end
        end
    end

    return elem
end

local function MakeSection(opts)
    local sName = opts.name or opts.Name or "Section"
    local side  = opts.side or "left"

    local sec = {
        name     = sName,
        side     = side,
        elements = {},
        scrollY  = 0,
    }

    local function addElem(e) table.insert(sec.elements,e) end

    function sec:toggle(o)      local e=BuildToggle(self,o)      addElem(e) return e end
    function sec:slider(o)      local e=BuildSlider(self,o)      addElem(e) return e end
    function sec:dropdown(o)    local e=BuildDropdown(self,o)    addElem(e) return e end
    function sec:button(o)      local e=BuildButton(self,o)      addElem(e) return e end
    function sec:label(o)       local e=BuildLabel(self,o)       addElem(e) return e end
    function sec:colorpicker(o) local e=BuildColorpicker(self,o) addElem(e) return e end
    function sec:keybind(o)     local e=BuildKeybind(self,o)     addElem(e) return e end

    function sec:_render(sx,sy,sw)
        local HEADER   = 20
        local PAD      = 6
        local EPAD     = 5
        local VISIBLE_H= 280

        local totalC = PAD
        for _,e in ipairs(self.elements) do totalC=totalC+e.height+EPAD end
        totalC = totalC + PAD

        local visH   = math.min(totalC, VISIBLE_H)
        local boxH   = HEADER + visH + 4
        local maxSc  = math.max(0, totalC-visH)

        if MouseIn(sx,sy+HEADER,sx+sw,sy+boxH) then
            if G.Key=="[UP]"   then self.scrollY=math.max(0, self.scrollY-8) end
            if G.Key=="[DOWN]" then self.scrollY=math.min(maxSc, self.scrollY+8) end
        end
        self.scrollY = Clamp(self.scrollY,0,maxSc)

        dx9.DrawFilledBox({sx,    sy},{sx+sw,   sy+boxH},   G.Black)
        dx9.DrawFilledBox({sx+1,  sy+1},{sx+sw-1, sy+boxH-1}, G.Panel)
        dx9.DrawFilledBox({sx+2,  sy+2},{sx+sw-2, sy+boxH-2}, G.Background)
        dx9.DrawFilledBox({sx+2,sy+2},{sx+sw-2,sy+4}, G.Accent)
        local tw=dx9.CalcTextWidth(sName)
        dx9.DrawString({sx+math.floor((sw-tw)/2), sy+5}, G.Font, sName)

        local innerY = sy+HEADER
        dx9.DrawFilledBox({sx+3,innerY},{sx+sw-3,sy+boxH-2}, G.Dark)

        local ey = innerY+PAD - self.scrollY
        for _,e in ipairs(self.elements) do
            if ey+e.height>innerY and ey<innerY+visH then
                e:_render(sx+6, ey, sw-12)
            end
            ey = ey+e.height+EPAD
        end

        if maxSc>0 then
            local sbX = sx+sw-5
            local sbH = visH
            local thumb = math.floor((visH/totalC)*sbH+0.5)
            local sbPos = math.floor((self.scrollY/maxSc)*(sbH-thumb)+0.5)
            dx9.DrawFilledBox({sbX,innerY},{sbX+3,innerY+sbH}, G.Panel)
            dx9.DrawFilledBox({sbX,innerY+sbPos},{sbX+3,innerY+sbPos+thumb}, G.Accent)
        end

        return boxH
    end

    return sec
end

local function MakeTab(tName)
    local tab = {
        name     = tName,
        sections = {},
    }

    function tab:section(opts)
        local s=MakeSection(opts)
        table.insert(self.sections,s)
        return s
    end

    function tab:_render(cx,cy,cw,ch)
        local halfW  = math.floor(cw/2)-4
        local leftX  = cx
        local rightX = cx+halfW+8
        local leftY  = cy
        local rightY = cy

        for _,s in ipairs(self.sections) do
            if s.side=="right" then
                local used = s:_render(rightX, rightY, halfW)
                rightY = rightY+used+8
            else
                local used = s:_render(leftX, leftY, halfW)
                leftY = leftY+used+8
            end
        end
    end

    return tab
end

local function MakeWindow(opts)
    local wKey = opts.name or opts.Name or "Window"

    if G.Windows[wKey]==nil then
        G.Windows[wKey] = {
            x=100, y=100, w=600, h=520,
            dragging=false, dragOff=nil,
            tabs={}, tabData={}, currentTab=nil,
            active=true,
            toggleKey = opts.ToggleKey or "[INSERT]",
            togHeld=false,
        }
    end
    local win = G.Windows[wKey]

    if G.Key~="[None]" and G.Key==win.toggleKey then
        if not win.togHeld then win.active=not win.active win.togHeld=true end
    else win.togHeld=false end

    if not win.active then return win end

    local wx,wy,ww,wh = win.x,win.y,win.w,win.h

    local TITLE_H = 22
    if dx9.isLeftClickHeld() and MouseIn(wx,wy,wx+ww,wy+TITLE_H) and not win.dragging then
        win.dragging=true
        win.dragOff={G.Mouse.x-wx, G.Mouse.y-wy}
    end
    if not dx9.isLeftClickHeld() then win.dragging=false win.dragOff=nil end
    if win.dragging and win.dragOff then
        win.x=G.Mouse.x-win.dragOff[1]
        win.y=G.Mouse.y-win.dragOff[2]
        wx,wy=win.x,win.y
    end

    dx9.DrawFilledBox({wx-1,wy-1},{wx+ww+1,wy+wh+1}, G.Black)
    dx9.DrawFilledBox({wx,  wy},  {wx+ww,  wy+wh},   G.Accent)
    dx9.DrawFilledBox({wx+1,wy+1},{wx+ww-1,wy+wh-1}, G.Panel)
    dx9.DrawFilledBox({wx+2,wy+2},{wx+ww-2,wy+wh-2}, G.Background)
    dx9.DrawFilledBox({wx+2,wy+TITLE_H},{wx+ww-2,wy+wh-2}, G.Dark)
    dx9.DrawString({wx+6,wy+5}, G.Font, wKey)

    local TAB_H = 20
    local tabX  = wx+6
    local tabY  = wy+TITLE_H

    for _,tName in ipairs(win.tabs) do
        local tw=dx9.CalcTextWidth(tName)+14
        local active=(win.currentTab==tName)
        if active then
            dx9.DrawFilledBox({tabX,tabY},{tabX+tw,tabY+TAB_H}, G.Panel)
            dx9.DrawFilledBox({tabX,tabY},{tabX+tw,tabY+2}, G.Accent)
            dx9.DrawString({tabX+5,tabY+3}, G.Accent, tName)
        else
            dx9.DrawFilledBox({tabX,tabY},{tabX+tw,tabY+TAB_H}, G.Dark)
            dx9.DrawString({tabX+5,tabY+3}, G.Grey, tName)
            if MouseIn(tabX,tabY,tabX+tw,tabY+TAB_H) and dx9.isLeftClickHeld() then
                win.currentTab=tName
            end
        end
        tabX=tabX+tw+2
    end

    local cx = wx+6
    local cy = wy+TITLE_H+TAB_H+4
    local cw = ww-12
    local ch = wh-TITLE_H-TAB_H-10

    if win.currentTab and win.tabData[win.currentTab] then
        win.tabData[win.currentTab]:_render(cx,cy,cw,ch)
    end

    return win
end

local Lib = {}

function Lib:notify(text, length, color)
    table.insert(G.Notifs,{
        text=text or "", length=length or 3,
        color=color or G.Accent, start=os.clock()
    })
end

function Lib:watermark(opts)
    G.WatermarkText = opts.name or "dx9 ui"
    return self
end

function Lib:window(opts)
    local wKey = opts.name or opts.Name or "Window"

    if G.Windows[wKey]==nil then
        G.Windows[wKey]={
            x=100,y=100,w=600,h=520,
            dragging=false,dragOff=nil,
            tabs={},tabData={},currentTab=nil,
            active=true,
            toggleKey=opts.ToggleKey or "[INSERT]",
            togHeld=false,
        }
    end
    local win = G.Windows[wKey]

    function win:tab(tabOpts)
        local tName = tabOpts.name or tabOpts.Name or "Tab"
        local found=false
        for _,v in ipairs(self.tabs) do if v==tName then found=true break end end
        if not found then table.insert(self.tabs,tName) end
        if self.currentTab==nil then self.currentTab=tName end
        if self.tabData[tName]==nil then
            self.tabData[tName]=MakeTab(tName)
        end
        return self.tabData[tName]
    end

    MakeWindow(opts)

    return win
end

TickNotifs()
TickWatermark()

_G.VDX = G
return Lib
