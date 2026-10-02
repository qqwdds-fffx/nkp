local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local oldUI = playerGui:FindFirstChild("MyUI")
if oldUI then
    oldUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local midTextLines = {
    "        🤓🤓        ",
    "5秒后自动600",
    "5秒后自动600",
}

local midLabel = Instance.new("TextLabel")
midLabel.AnchorPoint = Vector2.new(0.5, 0.5)
midLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
midLabel.Size = UDim2.new(0.7, 0, 0.35, 0)
midLabel.BackgroundTransparency = 1
midLabel.TextColor3 = Color3.new(1, 1, 1)
midLabel.Font = Enum.Font.GothamBold
midLabel.TextSize = 36
midLabel.TextWrapped = true
midLabel.TextXAlignment = Enum.TextXAlignment.Center
midLabel.TextYAlignment = Enum.TextYAlignment.Center
midLabel.Text = ""
midLabel.Parent = ScreenGui

task.spawn(function()
    midLabel.Text = ""

    for _, line in ipairs(midTextLines) do
        for i = 1, #line do
            midLabel.Text = midLabel.Text .. line:sub(i, i)
            task.wait(0.03)
        end
        midLabel.Text = midLabel.Text .. "\n"
    end
end)
