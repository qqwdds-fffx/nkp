local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    SuckHeight = 12,
    VisualHide = true,
    AutoShoot = true,
}

local CoreStorage = CoreGui:FindFirstChild("SuckSystem")
if not CoreStorage then
    CoreStorage = Instance.new("Folder")
    CoreStorage.Name = "SuckSystem"
    CoreStorage.Parent = CoreGui
end

local SuckState = CoreStorage:FindFirstChild("SuckState")
if not SuckState then
    SuckState = Instance.new("BoolValue")
    SuckState.Name = "SuckState"
    SuckState.Value = false
    SuckState.Parent = CoreStorage
end

local suckConnection = nil
local ScreenGui = nil
local ToggleBtn = nil
local detectedPlayers = {}

local function getWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            return child
        end
    end
    return nil
end

local function getWeaponRemotes(tool)
    if not tool then return nil end
    local remotes = tool:FindFirstChild("Remotes")
    if remotes then
        local checkShot = remotes:FindFirstChild("CheckShot")
        if checkShot then
            return checkShot
        end
    end
    for _, child in ipairs(tool:GetChildren()) do
        if child:IsA("RemoteEvent") and (child.Name:find("Shoot") or child.Name:find("Fire") or child.Name:find("Shot")) then
            return child
        end
    end
    return nil
end

local function getWeaponConfig(tool)
    if not tool then return nil end
    local config = tool:FindFirstChild("Configuration") or tool:FindFirstChild("Config")
    if config then
        return {
            Ammo = config:FindFirstChild("Ammo"),
            Spread = config:FindFirstChild("spread") or config:FindFirstChild("Spread"),
            ReloadTime = config:FindFirstChild("reloadTime") or config:FindFirstChild("ReloadTime"),
        }
    end
    return nil
end

local function autoShoot(targetPlayer)
    if not targetPlayer then return end
    local tool = getWeapon()
    if not tool then return end
    local checkShot = getWeaponRemotes(tool)
    if not checkShot then return end
    local config = getWeaponConfig(tool)
    if not config then return end
    local targetChar = targetPlayer.Character
    if not targetChar then return end
    local head = targetChar:FindFirstChild("Head")
    if not head then return end
    local headPos = head.Position
    local cam = Camera
    if not cam then return end
    local lookCF = CFrame.new(cam.CFrame.Position, headPos)
    local ammoValue = config.Ammo and config.Ammo.Value or 17
    local spreadValue = config.Spread and config.Spread.Value or 0
    local reloadTimeValue = config.ReloadTime and config.ReloadTime.Value or 1
    local seed = tool:FindFirstChild("Seed")
    local seedValue = seed and seed.Value or math.random(1, 999999)
    pcall(function()
        checkShot:FireServer(ammoValue, spreadValue, ammoValue, reloadTimeValue, lookCF, Vector3.new(headPos.X, headPos.Y, headPos.Z), head, seedValue, tick())
    end)
end

local function suckAllToHead()
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHead = myChar:FindFirstChild("Head")
    if not myHead then return end
    local headPos = myHead.Position
    local headCFrame = myHead.CFrame
    local upVector = headCFrame.UpVector
    local targetPos = headPos + upVector * 12
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local targetChar = player.Character
            if targetChar then
                local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = targetChar:FindFirstChild("Humanoid")
                if targetHRP and targetHumanoid and targetHumanoid.Health > 0 then
                    targetHRP.CFrame = CFrame.new(targetPos, targetPos + Vector3.new(0, 1, 0))
                    if Config.VisualHide then
                        pcall(function()
                            for _, part in ipairs(targetChar:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.LocalTransparencyModifier = 0.9
                                end
                            end
                            task.wait(0.02)
                            for _, part in ipairs(targetChar:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.LocalTransparencyModifier = 0
                                end
                            end
                        end)
                    end
                    autoShoot(player)
                    detectedPlayers[player.Name] = true
                end
            end
        end
    end
end

local function checkNewPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not detectedPlayers[player.Name] then
                detectedPlayers[player.Name] = true
                local myChar = LocalPlayer.Character
                if myChar then
                    local myHead = myChar:FindFirstChild("Head")
                    if myHead then
                        local headPos = myHead.Position
                        local headCFrame = myHead.CFrame
                        local upVector = headCFrame.UpVector
                        local targetPos = headPos + upVector * 12
                        local targetChar = player.Character
                        if targetChar then
                            local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                            if targetHRP then
                                targetHRP.CFrame = CFrame.new(targetPos, targetPos + Vector3.new(0, 1, 0))
                                autoShoot(player)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function suckLoop()
    if not SuckState.Value then return end
    if not LocalPlayer.Character then return end
    checkNewPlayers()
    suckAllToHead()
end

local function startSuck()
    if suckConnection then
        suckConnection:Disconnect()
        suckConnection = nil
    end
    SuckState.Value = true
    suckConnection = RunService.Heartbeat:Connect(suckLoop)
    if ToggleBtn then
        ToggleBtn.Text = "停止"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
    end
end

local function stopSuck()
    SuckState.Value = false
    if suckConnection then
        suckConnection:Disconnect()
        suckConnection = nil
    end
    detectedPlayers = {}
    if ToggleBtn then
        ToggleBtn.Text = "开启"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 120)
    end
end

local function toggleSuck()
    if SuckState.Value then
        stopSuck()
    else
        startSuck()
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        detectedPlayers[player.Name] = true
        if SuckState.Value then
            task.wait(0.5)
            local myChar = LocalPlayer.Character
            if myChar then
                local myHead = myChar:FindFirstChild("Head")
                if myHead then
                    local headPos = myHead.Position
                    local headCFrame = myHead.CFrame
                    local upVector = headCFrame.UpVector
                    local targetPos = headPos + upVector * 12
                    player.CharacterAdded:Connect(function()
                        task.wait(0.5)
                        local targetChar = player.Character
                        if targetChar then
                            local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                            if targetHRP then
                                targetHRP.CFrame = CFrame.new(targetPos, targetPos + Vector3.new(0, 1, 0))
                                autoShoot(player)
                            end
                        end
                    end)
                end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    detectedPlayers[player.Name] = nil
end)

local function createGUI()
    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
        ScreenGui = nil
    end
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SuckSystem"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 120, 0, 50)
    MainFrame.Position = UDim2.new(0, 10, 0, 80)
    MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
    MainFrame.BackgroundTransparency = 0.1
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 1.5
    Stroke.Color = Color3.fromRGB(100, 150, 255)
    Stroke.Transparency = 0.4
    Stroke.Parent = MainFrame
    
    ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 100, 0, 35)
    ToggleBtn.Position = UDim2.new(0, 10, 0, 8)
    ToggleBtn.Text = "开启"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.TextSize = 16
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 120)
    ToggleBtn.Parent = MainFrame
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = ToggleBtn
    
    ToggleBtn.MouseButton1Click:Connect(function()
        toggleSuck()
        pcall(function()
            game:GetService("HapticService"):VibrateHandheld(Enum.VibratorType.Handheld, 0.1)
        end)
    end)
    
    return ScreenGui
end

local function init()
    createGUI()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            detectedPlayers[player.Name] = true
        end
    end
    if SuckState.Value then
        startSuck()
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if SuckState.Value then
        startSuck()
    end
end)

local touchStart = nil
UserInputService.TouchStarted:Connect(function(touch)
    touchStart = touch.Position
end)
UserInputService.TouchEnded:Connect(function(touch)
    if not touchStart then return end
    local delta = touch.Position - touchStart
    if delta.Magnitude > 50 then
        local direction = delta.Unit
        if direction.X > 0.5 then
            if ToggleBtn then ToggleBtn.MouseButton1Click:Fire() end
        end
    end
    touchStart = nil
end)

init()
