if SERVER then
    util.AddNetworkString("hr_reload_confirm")
    util.AddNetworkString("hr_reload_execute")

    local function deleteCacheFolder(path)
        -- Ensure the path ends with a slash
        if not string.EndsWith(path, "/") then
            path = path .. "/"
        end

        -- Get a list of all files and directories in the specified path
        local files, directories = file.Find(path .. "*", "GAME")

        -- Recursively delete all files
        for _, filename in ipairs(files) do
            file.Delete(path .. filename)
        end

        -- Recursively delete all directories
        for _, dirName in ipairs(directories) do
            deleteCacheFolder(path .. dirName)
        end
    end

    concommand.Add("hr_reload", function(ply, cmd, args)
        -- Only allow admins to use this command
        if IsValid(ply) and not ply:IsAdmin() then
            ply:PrintMessage(HUD_PRINTCONSOLE, "You do not have permission to run this command.")
            return
        end

        -- Send a net message to open the confirmation dialog on the client
        net.Start("hr_reload_confirm")
        if IsValid(ply) then
            net.Send(ply)
        else
            net.Broadcast()
        end
    end)

    net.Receive("hr_reload_execute", function(len, ply)
        -- Only allow admins to execute the reload
        if IsValid(ply) and not ply:IsAdmin() then return end

        -- Attempt to delete the cache folder
        local cachePath = "cache/"
        if file.Exists(cachePath, "GAME") then
            deleteCacheFolder(cachePath)
            print("Cache folder deleted successfully.")
        else
            print("Cache folder does not exist.")
        end

        -- Reload the current map (which forces addons to reload)
        local currentMap = game.GetMap()
        print("Reloading map: " .. currentMap)
        game.ConsoleCommand("changelevel " .. currentMap .. "\n")
    end)
else -- CLIENT
    net.Receive("hr_reload_confirm", function()
        -- Create a simple VGUI frame for confirmation
        local frame = vgui.Create("DFrame")
        frame:SetTitle("Warning")
        frame:SetSize(300, 150)
        frame:Center()
        frame:MakePopup()

        local label = vgui.Create("DLabel", frame)
        label:SetPos(20, 40)
        label:SetSize(260, 30)
        label:SetText("This will delete the Lua addons cache. Continue?")

        local btnYes = vgui.Create("DButton", frame)
        btnYes:SetPos(50, 80)
        btnYes:SetSize(80, 30)
        btnYes:SetText("Yes")
        btnYes.DoClick = function()
            frame:Close()
            net.Start("hr_reload_execute")
            net.SendToServer()
        end

        local btnNo = vgui.Create("DButton", frame)
        btnNo:SetPos(170, 80)
        btnNo:SetSize(80, 30)
        btnNo:SetText("No")
        btnNo.DoClick = function()
            frame:Close()
        end
    end)
end
