local PLUGIN = PLUGIN

PLUGIN.name = "Logs UI"
PLUGIN.author = "Sunshi"
PLUGIN.description = "A simple logs ui for helix."

ix.command.Add("Logs", {
    description = "Open the logs menu.",
    superAdminOnly = true,
    arguments = {
        bit.bor(ix.type.string, ix.type.optional)
    },
    OnRun = function(self, client, filter)
        if filter then

            local files, dirs = file.Find("helix/logs/*", "DATA") 

            local fileName = files[#files]
            local path = "helix/logs/" .. fileName
            local content = file.Read(path, "DATA") or "Fichier introuvable."

            if not client:IsAdmin() then return end

            net.Start("ixulx_sendlogfilecontent")
                net.WriteString(fileName)
                net.WriteString(content)
                net.WriteString(filter)
            net.Send(client)     

        else
            client:ConCommand("request_helix_logs")
        end
    end
})


if SERVER then

    util.AddNetworkString("ixulx_sendlogfileslist")
    util.AddNetworkString("ixulx_sendlogfilecontent")

    concommand.Add("request_helix_logs", function(ply)
        if not IsValid(ply) then return end
        if not ply:IsAdmin() then return end

        local files, dirs = file.Find("helix/logs/*", "DATA")
        net.Start("ixulx_sendlogfileslist")
            net.WriteTable(files)
        net.Send(ply)
    end)

    net.Receive("ixulx_sendlogfilecontent", function(len, ply)
        local fileName = net.ReadString()
        local filter = net.ReadString()
        local path = "helix/logs/" .. fileName
        local content = file.Read(path, "DATA") or "Fichier introuvable."
        if not ply:IsAdmin() then return end

        net.Start("ixulx_sendlogfilecontent")
            net.WriteString(fileName)
            net.WriteString(content)
            net.WriteString(filter)
        net.Send(ply)
    end)

else


net.Receive("ixulx_sendlogfileslist", function()
    local files = net.ReadTable()

    local frame = vgui.Create("DFrame")
    frame:SetSize(ScrW()*0.2, ScrH()*0.3)
    frame:Center()
    frame:SetTitle("Helix Logs")
    frame:MakePopup()

    local textlog = vgui.Create("RichText", frame)
    textlog:Dock(TOP)
    textlog:DockMargin( 0, 10, 0, 0 )
    textlog:SetVerticalScrollbarEnabled(true)
    textlog:InsertColorChange(255, 255, 255, 255)
    textlog:AppendText("Choose a log file to view, by default today’s log is selected. You can add filters to narrow your search, and leaving the filters empty will show the entire log.")
    textlog:SetVerticalScrollbarEnabled(false )
    textlog:SetTextSelectionColors( Color(255,255,255),ix.config.Get("color"))
    local DComboBox = vgui.Create( "DComboBox", frame )
    DComboBox:Dock(TOP)
    DComboBox:DockMargin( 0, 10, 0, 0 )
    DComboBox:SetValue( files[#files] )
    for i,v in pairs(table.Reverse( files )) do
        DComboBox:AddChoice( v )
    end
    DComboBox:SetSortItems( false )

    local textkeyword = vgui.Create("RichText", frame)
    textkeyword:Dock(TOP)
    textkeyword:DockMargin( 0, 10, 0, 0 )
    textkeyword:SetVerticalScrollbarEnabled(true)
    textkeyword:InsertColorChange(255, 255, 255, 255)
    textkeyword:AppendText("Use & for AND and | for OR, for example player1&keyword|player2 shows lines where player1 is present and (keyword or player2).")
    textkeyword:SetVerticalScrollbarEnabled(false )
    textkeyword:SetTextSelectionColors( Color(255,255,255),ix.config.Get("color"))
    local TextEntryKey = vgui.Create( "DTextEntry", frame )
    TextEntryKey:Dock(TOP)
    TextEntryKey:DockMargin( 0, 10, 0, 0 )
    TextEntryKey:SetPlaceholderText( "player1&player2|player3" )
    TextEntryKey:SetValue("")
    TextEntryKey.OnEnter = function( self )
    end

    local texttime = vgui.Create("RichText", frame)
    texttime:Dock(TOP)
    texttime:DockMargin( 0, 10, 0, 0 )
    texttime:SetVerticalScrollbarEnabled(true)
    texttime:InsertColorChange(255, 255, 255, 255)
    texttime:AppendText("Use [TIME:HH:MM-HH:MM] to filter logs by time, for example [TIME:13:00-14:30] shows only lines between 13:00 and 14:30.")
    texttime:SetVerticalScrollbarEnabled(false )
    texttime:SetTextSelectionColors( Color(255,255,255),ix.config.Get("color"))
    local TextEntryTime = vgui.Create( "DTextEntry", frame )
    TextEntryTime:Dock(TOP)
    TextEntryTime:DockMargin( 0, 10, 0, 0 )
    TextEntryTime:SetPlaceholderText( "[TIME:00:00-23:59]" )
    TextEntryTime:SetValue("[TIME:00:00-23:59]")
    TextEntryTime.OnEnter = function( self )
    end

    local DermaButton = vgui.Create( "DButton", frame )
    DermaButton:SetText( "Open Log" )
    DermaButton:Dock(BOTTOM)
    DermaButton.DoClick = function()
        net.Start("ixulx_sendlogfilecontent")
            net.WriteString(DComboBox:GetValue())
            net.WriteString(TextEntryKey:GetValue().."&"..TextEntryTime:GetValue())
        net.SendToServer()
    end

end)

  local function FilterLogLines(content, rawFilters)
        local andParts = {}
        for part in rawFilters:gmatch("[^&]+") do table.insert(andParts, part) end

        local filters, timeGroups = {}, {}

        for _, part in ipairs(andParts) do
            local lowerPart = part:lower():gsub("^%s*(.-)%s*$", "%1")
            local ors, isTimeGroup = {}, false
            for orPart in lowerPart:gmatch("[^|]+") do
                local timeStart, timeEnd = orPart:match("^%[time:(%d%d:%d%d)%-(%d%d:%d%d)%]$")
                if timeStart and timeEnd then
                    table.insert(ors, {timeStart, timeEnd})
                    isTimeGroup = true
                else
                    table.insert(ors, orPart)
                end
            end
            if isTimeGroup then
                table.insert(timeGroups, ors)
            else
                table.insert(filters, ors)
            end
        end

        local function TimeInRange(lineTime, startTime, endTime)
            local function ToMinutes(t)
                local h,m = t:match("(%d%d):(%d%d)")
                return tonumber(h)*60 + tonumber(m)
            end
            local t = ToMinutes(lineTime)
            return t >= ToMinutes(startTime) and t <= ToMinutes(endTime)
        end

        local filteredLines = {}
        for line in content:gmatch("[^\r\n]+") do
            local lowerLine = line:lower()
            local matchesAll = true

            for _, orGroup in ipairs(filters) do
                local matchGroup = false
                for _, kw in ipairs(orGroup) do
                    if lowerLine:find(kw, 1, true) then matchGroup = true break end
                end
                if not matchGroup then matchesAll = false break end
            end

            if matchesAll then
                for _, timeGroup in ipairs(timeGroups) do
                    local matchTime = false
                    local lineTime = line:match("^%[(%d%d:%d%d):%d%d%]")
                    if lineTime then
                        for _, t in ipairs(timeGroup) do
                            if TimeInRange(lineTime, t[1], t[2]) then
                                matchTime = true break
                            end
                        end
                    end
                    if not matchTime then matchesAll = false break end
                end
            end

            if matchesAll then table.insert(filteredLines, line) end
        end
        return filteredLines
end

net.Receive("ixulx_sendlogfilecontent", function()
    local fileName = net.ReadString()
    local content = net.ReadString()
    local rawFilters = net.ReadString() 

    local filteredLines = FilterLogLines(content, rawFilters)

    local frame = vgui.Create("DFrame")
    frame:SetSize(800, 600)
    frame:Center()
    frame:SetTitle(fileName .. " (filters : " .. rawFilters .. ")")
    frame:MakePopup()

    local rich = vgui.Create("RichText", frame)
    rich:Dock(FILL)
    rich:SetVerticalScrollbarEnabled(true)
    rich:InsertColorChange(255, 255, 255, 255)
    rich:SetTextSelectionColors( Color(255,255,255),ix.config.Get("color"))
    for _, line in ipairs(filteredLines) do
        rich:AppendText(line .. "\n")
    end

    -- Scroll automatique en bas
    timer.Simple(0, function()
        if rich.VBar then rich.VBar:SetScroll(rich.VBar:GetMax()) end
    end)
end)

function OpenHelixLogsMenu()
    RunConsoleCommand("request_helix_logs")
end


end