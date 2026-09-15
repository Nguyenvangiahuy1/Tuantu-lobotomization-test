if not game:IsLoaded() then game.Loaded:Wait() end --------------- START

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui") or Players.LocalPlayer.PlayerGui

local partthatdestroystheguialreadyexist = ReplicatedStorage:FindFirstChild("DESTROYLOBOTOMIZER")
if partthatdestroystheguialreadyexist then
    partthatdestroystheguialreadyexist:Destroy()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "LOBOTOMIZER PRE-EXECUTE",
        Text = "LOBOTOMIZER IS ALREADY EXECUTED! DESTROYING OLD GUI...",
        Duration = 5
    })
end

local player = Players.LocalPlayer

local assets = ReplicatedStorage:WaitForChild("Assets", 15)
local remotes = assets and assets:WaitForChild("RemoteEvents", 15)
local abnormalities = workspace:WaitForChild("Abnormalities", 15)
local units = workspace:WaitForChild("Units", 15)

if not assets or not remotes or not abnormalities or not units then
    warn("[Lobotomizer] Required game objects were not found.")
    return
end

---------------------------------------------------------- FUNCS
local function work(tablet, workType)
    if not tablet or not workType or (workType ~= "Attachment" and workType ~= "Insight" and workType ~= "Instinct" and workType ~= "Repression") then notif("What are you working with?", "Work Error") return end
    if not tablet:IsA("BasePart") or tablet.Name ~= "WorkTablet" then return end
    local abnormality = tablet.Parent
    local working = abnormality and abnormality:FindFirstChild("IsWorking")
    if working and working.Value == true then
        return false
    end

    local workEvent = remotes and remotes:FindFirstChild("WorkEvent")
    if not workEvent then
        notif("WorkEvent was not found.", "Work Error")
        return false
    end

    workEvent:FireServer(tablet, workType)
    return true
end
local function extract(abnormality, item)
    if not abnormality then notif("What abnormality are you extracting from?", "Extraction Error") return end
    if not item or item ~= "Suit" and item ~= "Weapon" then notif("What are you extracting?", "Extraction Error") return end

    remotes.ExtractEquipment:FireServer(abnormality, item)
    
    local info = safeFind(abnormality, {"InfoTablet","AbnormalityGui","Frame","EquipmentInfo"})
    local itemName

    if item == "Suit" then
        itemName = safeFind(info, {"SuitEquipment","EquipmentName"})
    elseif item == "Weapon" then
        itemName = safeFind(info, {"WeaponEquipment","EquipmentName"})
    end

    if itemName then
        if itemName.Text == "[Name]" then
            notif("Abnormality does not have a "..item, "Extraction Error: Got Nothing")
            return
        end

        notif("Extracted "..itemName.Text, "Extraction Request Success")
    end
end
local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart")
end
local function getHuman(char)
    return char:FindFirstChildOfClass("Humanoid")
end
function safeFind(root, path)
    local current = root
    for _, name in ipairs(path) do
        if not current then return nil end
        current = current:FindFirstChild(name)
    end
    return current
end
---------------------------------------------------------- VARS
local enemyEsp = false
--local autoParry = false

------------------------------------------------------------------------------ RAYFIELD SECTION
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Lobotomizer",
   LoadingTitle = "LOBOTOMIZER LOADING...",
   LoadingSubtitle = "by Ali",
   ShowText = "L",
   Theme = "Default",

   ToggleUIKeybind = "K",

   DisableRayfieldPrompts = true,
   DisableBuildWarnings = true,
})
function notif(txt, tit, dur)
    Rayfield:Notify({
        Content = txt,
        Title = tit or "Notification",
        Duration = dur or 5
    })
end

local abTab = Window:CreateTab("Abnormalities")
-- local statsTab = Window:CreateTab("Stats")
local visualTab = Window:CreateTab("Visual")
local charTab = Window:CreateTab("Character")
local settingsTab = Window:CreateTab("Settings")

local destroying = false

--------------------------------------------------------------------------- WORK SECTION
local selectedAbnormalities = {}
local selectedType = nil
local foundAbnormalities = {}
local waa
local tpta
local peekallinfo
local peeking = false
local abnormalityPeeking = selectedAbnormalities
local modified = {}
local restoreGuis

local abdd = abTab:CreateDropdown({
    Name = "Select Abnormalities",
    Options = {},
    CurrentOption = nil,
    MultipleOptions = true,
    Callback = function(option)
        selectedAbnormalities = {}
        for _, n in option do
            table.insert(selectedAbnormalities, foundAbnormalities[n])
        end
        local first = selectedAbnormalities[1]
        if first then
            tpta:Set("Teleport to the First Selected Abnormality ("..first.Name..")")
        end
    end
})
abTab:CreateDropdown({
    Name = "Work Type",
    Options = {
        "Instinct",
        "Insight",
        "Attachment",
        "Repression"
    },
    CurrentOption = nil,
    MultipleOptions = false,
    Callback = function(option)
        selectedType = option[1]
        waa:Set("Work at Selected Abnormalities with "..selectedType)
    end
})
abTab:CreateButton({
    Name = "Find Abnormalities",
    Callback = function()
        abdd:Set({})
        selectedAbnormalities = {}
        local a = {}
        foundAbnormalities = {}

        for _, model in abnormalities:GetChildren() do
            if (model:IsA("Model") or model:IsA("Folder"))
                and model:FindFirstChild("WorkTablet") then
                table.insert(a, model.Name)
                foundAbnormalities[model.Name] = model
            end
        end

        abdd:Refresh(a)
    end
})

abTab:CreateSection("Actions")
waa = abTab:CreateButton({
    Name = "Work at Selected Abnormalities with Selected Type",
    Callback = function()
        if selectedType == nil then
            notif("Select a Work Type first.", "Work Error")
            return
        end

        for _, abnormality in pairs(selectedAbnormalities) do
            work(abnormality.WorkTablet, selectedType)
            task.wait()
        end
    end
})
abTab:CreateButton({
    Name = "Extract Weapon from Selected Abnormalities",
    Callback = function()
        for _, abnormality in pairs(selectedAbnormalities) do
            extract(abnormality, "Weapon")
        end
    end
})
abTab:CreateButton({
    Name = "Extract Suit from Selected Abnormalities",
    Callback = function()
        for _, abnormality in pairs(selectedAbnormalities) do
            extract(abnormality, "Suit")
        end
    end
})

tpta = abTab:CreateButton({
    Name = "Teleport to the First Selected Abnormality (nil)",
    Callback = function()
        local abnormality = selectedAbnormalities[1]

        local root = getRoot(player.Character)

        if root and abnormality then
            root.CFrame = abnormality.LeavePosition.CFrame
        end
    end
})
peekallinfo = abTab:CreateButton({
    Name = "Peek Selected Abnormality's Locked Info [OFF]",
    Callback = function()
        peeking = not peeking

        if not peeking then
            restoreGuis()
            abnormalityPeeking = nil
        end
    end
})

local function setGui(gui, props)
    if not gui or not gui.Visible then
        return
    end

    if not modified[gui] then
        modified[gui] = {}
    end

    for property, value in props do
        if modified[gui][property] == nil then
            modified[gui][property] = gui[property]
        end

        gui[property] = value
    end
end
restoreGuis = function()
    for gui, properties in modified do
        if gui and gui.Parent then
            for property, original in properties do
                gui[property] = original
            end
        end
    end

    table.clear(modified)
end

local function peekAbnormality(selectedAbnormality)
    local infoGui = safeFind(selectedAbnormality, {"InfoTablet","AbnormalityGui"})
    local frame = infoGui and infoGui:FindFirstChild("Frame")

    local classified = infoGui and safeFind(infoGui, {"ClassifiedInfo","LockedFrame"})
    local cbutton = classified and classified:FindFirstChild("LockedButton")

    local equipment = frame and frame:FindFirstChild("EquipmentInfo")

    local weapon = equipment and safeFind(equipment, {
        "WeaponEquipment",
        "RequirerResearchLabel"
    })

    local suit = equipment and safeFind(equipment, {
        "SuitEquipment",
        "RequirerResearchLabel"
    })

    local gift = equipment and safeFind(equipment, {
        "GiftInfo",
        "GiftEquipment",
        "RequirerResearchLabel"
    })

    local management = frame and safeFind(frame, {
        "ManagementInfo",
        "ScrollingFrame"
    })

    local research = frame and frame:FindFirstChild("ResearchInfo")

    setGui(classified, {
        BackgroundTransparency = 0.5
    })

    setGui(cbutton, {
        BackgroundTransparency = 0.5,
        TextTransparency = 0.5
    })

    for _, gui in {weapon, suit, gift} do
        setGui(gui, {
            BackgroundTransparency = 0.25,
            TextTransparency = 0.5
        })
    end

    if management then
        for _, mt in management:GetChildren() do
            if mt:IsA("TextLabel")
            and mt.Name:find("MT")
            and mt:FindFirstChild("LockedFrame") then

                local lf = mt.LockedFrame
                local lb = lf:FindFirstChild("LockedButton")

                setGui(lf, {
                    BackgroundTransparency = 0.5
                })

                setGui(lb, {
                    BackgroundTransparency = 0.5,
                    TextTransparency = 0.5
                })
            end
        end
    end

    if research then
        for _, rt in research:GetChildren() do
            if rt.Name == "Attachment"
            or rt.Name == "Insight"
            or rt.Name == "Instinct"
            or rt.Name == "Repression" then

                local lf = rt:FindFirstChild("LockedFrame")
                local lb = lf and lf:FindFirstChild("LockedButton")

                setGui(lf, {
                    BackgroundTransparency = 0.5
                })

                setGui(lb, {
                    BackgroundTransparency = 0.5,
                    TextTransparency = 0.5
                })
            end
        end
    end
end

RunService:BindToRenderStep("PEEK", Enum.RenderPriority.Last.Value + 1, function()
    restoreGuis()

    if not peeking then
        peekallinfo:Set("Peek All Selected Abnormalities' Locked Info [OFF]")
        return
    end

    peekallinfo:Set("Peek All Selected Abnormalities' Locked Info [ON]")

    for _, abnormality in pairs(selectedAbnormalities) do
        peekAbnormality(abnormality)
    end
end)
----------------------------------------------------------------------------- STATS SECTION
-- statsTab:CreateSection("Character Stats")
-- local currentStatSpeed = safeFind(player.Character, {"CharStats","AttackSpeed"})
-- local editedSpeed = 1
-- statsTab:CreateSlider({
--     Name = "Attack Speed",
--     Range = {1, 100},
--     Increment = 1,
--     CurrentValue = currentStatSpeed and currentStatSpeed.Value or 1,
--     Callback = function(v)
--         editedSpeed = v
--     end
-- })

-- RunService:BindToRenderStep("STAT", Enum.RenderPriority.Character.Value + 1, function(...)
--     currentStatSpeed = safeFind(player.Character, {"CharStats","AttackSpeed"})
--     if currentStatSpeed and currentStatSpeed.Value ~= editedSpeed then
--         currentStatSpeed.Value = editedSpeed
--     end
-- end)

--------------------------------------------------------------------------- AUTO WORK SECTION
local autoWork = false
local autoWorkDelay = 1
local autoWorkType = nil
local autoWorkThread = nil

local function getWorkTablet(abnormality)
    if not abnormality then return nil end
    local tablet = abnormality:FindFirstChild("WorkTablet")
    if tablet and tablet:IsA("BasePart") then
        return tablet
    end
    return nil
end

local function canAutoWork(abnormality)
    local tablet = getWorkTablet(abnormality)
    if not tablet then return false end

    local working = abnormality:FindFirstChild("IsWorking")
    if working and working.Value == true then
        return false
    end

    return true
end

local function autoWorkOnce()
    if not autoWork or destroying then return end

    for _, abnormality in ipairs(abnormalities:GetChildren()) do
        if not autoWork or destroying then break end

        if (abnormality:IsA("Model") or abnormality:IsA("Folder"))
            and canAutoWork(abnormality) then

            local workType = autoWorkType or selectedType
            local tablet = getWorkTablet(abnormality)

            -- Never send an invalid/default work type.
            if tablet and workType then
                pcall(function()
                    work(tablet, workType)
                end)
                task.wait(autoWorkDelay)
            end
        end
    end
end

abTab:CreateSection("Auto Work")

abTab:CreateDropdown({
    Name = "Auto Work Type",
    Options = {
        "Use Selected Type",
        "Instinct",
        "Insight",
        "Attachment",
        "Repression"
    },
    CurrentOption = {"Use Selected Type"},
    MultipleOptions = false,
    Callback = function(option)
        local value = option and option[1]
        autoWorkType = (value == "Use Selected Type") and nil or value
    end
})

abTab:CreateSlider({
    Name = "Auto Work Delay",
    Range = {0.2, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 1,
    Callback = function(v)
        autoWorkDelay = math.max(0.2, tonumber(v) or 1)
    end
})

abTab:CreateToggle({
    Name = "Auto Work",
    CurrentValue = false,
    Callback = function(v)
        autoWork = v

        if autoWork then
            if autoWorkThread then
                task.cancel(autoWorkThread)
            end

            autoWorkThread = task.spawn(function()
                while autoWork and not destroying do
                    local ok, err = pcall(autoWorkOnce)
                    if not ok then
                        warn("[Lobotomizer] Auto Work error:", err)
                    end
                    task.wait(0.15)
                end
                autoWorkThread = nil
            end)

            notif("Auto Work started.", "Auto Work")
        else
            if autoWorkThread then
                task.cancel(autoWorkThread)
                autoWorkThread = nil
            end
            notif("Auto Work stopped.", "Auto Work")
        end
    end
})

--------------------------------------------------------------------------- ESP SECTION
visualTab:CreateSection("Abnormalities")
local espObj = {}
local eet = visualTab:CreateToggle({
    Name = "Enemy ESP",
    CurrentValue = enemyEsp,
    Callback = function(v)
        enemyEsp = v

        if #espObj > 0 then
            for _, o in espObj do
                o:Destroy()
            end
        end
    end
})

local lastRefresh = tick()
local refreshRate = 5
RunService:BindToRenderStep("ESP", Enum.RenderPriority.Camera.Value + 2, function(...)
    if enemyEsp then
        if tick() - lastRefresh >= refreshRate then
            lastRefresh = tick()
            
            if #espObj > 0 then
                for _, o in espObj do
                    o:Destroy()
                end
            end
        end

        for _, unit in units:GetChildren() do
            if unit.Name == "Clerk" or Players:GetPlayerFromCharacter(unit)
                or not unit:IsA("Model") or not unit:FindFirstChild("RiskLevel") then continue end
            if unit:FindFirstChild("LobotomizerESP") then continue end
            local unitRoot = getRoot(unit)
            local unitHuman = getHuman(unit)

            local marker = Instance.new("Folder")
            marker.Name = "LobotomizerESP"
            marker.Parent = unit

            local hl = Instance.new("Highlight")
            hl.Adornee = unit
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillColor = Color3.fromRGB(255, 0, 0)
            hl.FillTransparency = 0.67 + 0.067 -- 😊😊😊
            hl.OutlineTransparency = 0
            hl.Parent = CoreGui
            table.insert(espObj, hl)

            local billboard = Instance.new("BillboardGui")
            billboard.Adornee = unitRoot
            billboard.AlwaysOnTop = true
            billboard.Size = UDim2.fromOffset(150, 40)
            local nameText = Instance.new("TextLabel")
            nameText.Name = "EnemyName"
            nameText.Text = unit.Name
            nameText.TextScaled = true
            nameText.TextColor3 = Color3.new(1,1,1)
            nameText.BackgroundTransparency = 1
            nameText.Size = UDim2.fromScale(1, 0.33)
            nameText.Position = UDim2.fromScale(0, 0)
            nameText.Parent = billboard
            local distanceText = Instance.new("TextLabel")
            distanceText.Name = "Distance"
            distanceText.Text = "Distance: 0"
            distanceText.TextScaled = true
            distanceText.TextColor3 = Color3.new(1,1,1)
            distanceText.BackgroundTransparency = 1
            distanceText.Size = UDim2.fromScale(1, 0.33)
            distanceText.Position = UDim2.fromScale(0, 0.33)
            distanceText.Parent = billboard
            local hpText = Instance.new("TextLabel")
            hpText.Name = "HP"
            hpText.Text = "Health: 100"
            hpText.TextScaled = true
            hpText.TextColor3 = Color3.new(1,1,1)
            hpText.BackgroundTransparency = 1
            hpText.Size = UDim2.fromScale(1, 0.33)
            hpText.Position = UDim2.fromScale(0, 0.67) --😊😊😊
            hpText.Parent = billboard

            billboard.Parent = unit --better if inside unit
            table.insert(espObj, billboard)

            task.spawn(function()
                while unit and unitRoot and unit.Parent and billboard and billboard.Parent do
                    if destroying then break end

                    local plrChar = player.Character
                    local root = plrChar and getRoot(plrChar)
                    unitHuman = getHuman(unit)

                    if root then
                        local dist = (unitRoot.Position - root.Position).Magnitude
                        distanceText.Text = "Distance: "..tostring(math.round(dist*100)/100)
                    end

                    if unitHuman then
                        hpText.Text = "Health: "..unitHuman.Health
                    end

                    task.wait(.5)
                end 
            end)
        end
    end
end)

---------------------------------------------------------------------------------------- CHARACTER SECTION
charTab:CreateSection("Humanoid")
local setWS = false
local setJP = false
local currentWS = getHuman(player.Character) and getHuman(player.Character).WalkSpeed
local currentJP = getHuman(player.Character) and (getHuman(player.Character).JumpPower or getHuman(player.Character).JumpHeight)
charTab:CreateToggle({
    Name = "Set Walkspeed",
    CurrentValue = setWS,
    Callback = function(v)
        setWS = v
    end
})
charTab:CreateToggle({
    Name = "Set Jumppower",
    CurrentValue = setJP,
    Callback = function(v)
        setJP = v
    end
})
charTab:CreateSlider({
    Name = "Walkspeed",
    Range = {10, 200},
    Increment = 2,
    CurrentValue = currentWS,
    Callback = function(v)
        currentWS = v
    end
})
charTab:CreateSlider({
    Name = "Jumppower",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = currentJP,
    Callback = function(v)
        currentJP = v
    end
})

RunService:BindToRenderStep("SETHUMANOID", Enum.RenderPriority.Character.Value + 2, function(...)
    if setWS then
        local humanoid = getHuman(player.Character)
        if humanoid then
            humanoid.WalkSpeed = currentWS
        end
    end
    if setJP then
        local humanoid = getHuman(player.Character)
        if humanoid then
            if humanoid.UseJumpPower then
                humanoid.JumpPower = currentJP
            else
                humanoid.JumpHeight = currentJP
            end
        end
    end
end)

charTab:CreateDivider()
charTab:CreateSection("Auto Parry")
local apt
apt = charTab:CreateToggle({
    Name = "Auto Parry (UH NOT YET SORRY...)",
    CurrentValue = false,
    Callback = function(v)
        task.wait(.1)
        apt:Set(false)
    end
})

--------------------------------------------------------------------------- SETTINGS SECTION
function destroyGui()
    if destroying then return end

    notif("Destroying...")
    destroying = true
    autoWork = false
    if autoWorkThread then
        task.cancel(autoWorkThread)
        autoWorkThread = nil
    end
    print("start destroying assets")

    RunService:UnbindFromRenderStep("ESP")
    for _, o in espObj do
        o:Destroy()
    end
    espObj = nil
    print("unbinded esp and cleaned esp objects")

    RunService:UnbindFromRenderStep("SETHUMANOID")
    print("unbinded sethumanoid")

    RunService:UnbindFromRenderStep("PEEK")
    print("unbinded peek")

    restoreGuis()
    print("restored peeked guis")

    foundAbnormalities = nil
    modified = nil
    print("cleaned all tables")

    if ReplicatedStorage:FindFirstChild("DESTROYLOBOTOMIZER") then
        ReplicatedStorage.DESTROYLOBOTOMIZER:Destroy()
    end
    print("partthatdestroystheguiwhenitisdestroyed has been destroyed without re-destroying the gui")

    print("done, now destroying rayfield...")
    task.wait(.5)
    Rayfield:Destroy()
end

settingsTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        destroyGui()
    end
})

------------------------------------------------------------ THE END
local partthatdestroystheguiwhenitisdestroyed = Instance.new("Part")
partthatdestroystheguiwhenitisdestroyed.Name = "DESTROYLOBOTOMIZER"
partthatdestroystheguiwhenitisdestroyed.Parent = ReplicatedStorage
partthatdestroystheguiwhenitisdestroyed.Destroying:Once(destroyGui)

notif("Lobotomizer Executed!", "Lobotomizer GUI")