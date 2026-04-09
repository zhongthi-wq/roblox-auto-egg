-- Auto Buy Eggs GUI
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/zhongthi-wq/roblox-auto-egg/main/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")

-- === CONFIG ===
local EGGS = {
    {Name = "BasicEgg", Price = 250, Enabled = false},
    {Name = "UncommonEgg", Price = 2500, Enabled = false},
    {Name = "UncommonRareEgg", Price = 25000, Enabled = false},
}
local BUY_DELAY = 0.5
local CLAIM_DELAY = 1
local autoClaimEnabled = false

-- === FIND PLAYER PLOT ===
local function getPlayerPlot()
    for _, plot in pairs(workspace.Core.Scriptable.Plots:GetChildren()) do
        for _, child in pairs(plot.Eggs:GetChildren()) do
            if child:GetAttribute("plotOwner") == player.Name then
                return plot.Name
            end
        end
    end
    return "1"
end

-- === GET COINS ===
local function getCoins()
    return player.leaderstats.Coins.Value
end

-- === GUI ===
if player.PlayerGui:FindFirstChild("AutoBuyEggs") then
    player.PlayerGui.AutoBuyEggs:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoBuyEggs"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player.PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 0)
Frame.Position = UDim2.new(0, 10, 0.5, 0)
Frame.AnchorPoint = Vector2.new(0, 0.5)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Frame.AutomaticSize = Enum.AutomaticSize.Y

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

local Layout = Instance.new("UIListLayout", Frame)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 2)

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.Text = "Auto Egg Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.LayoutOrder = 0
Title.Parent = Frame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

-- Coin display
local CoinLabel = Instance.new("TextLabel")
CoinLabel.Size = UDim2.new(1, -10, 0, 28)
CoinLabel.Position = UDim2.new(0, 5, 0, 0)
CoinLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CoinLabel.Text = "Coins: 0"
CoinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
CoinLabel.Font = Enum.Font.GothamBold
CoinLabel.TextSize = 14
CoinLabel.LayoutOrder = 1
CoinLabel.Parent = Frame
Instance.new("UICorner", CoinLabel).CornerRadius = UDim.new(0, 6)

-- Drag
local dragging, dragStart, startPos
Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)
Title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- === HELPER: Create toggle button ===
local function createToggle(text, layoutOrder, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -10, 0, 36)
    Btn.Position = UDim2.new(0, 5, 0, 0)
    Btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    Btn.Text = text .. " - OFF"
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 13
    Btn.LayoutOrder = layoutOrder
    Btn.Parent = Frame
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    local enabled = false
    Btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            Btn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
            Btn.Text = text .. " - ON"
        else
            Btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
            Btn.Text = text .. " - OFF"
        end
        callback(enabled)
    end)
    return Btn
end

-- Auto Claim Coins button
createToggle("Auto Claim Coins", 2, function(state)
    autoClaimEnabled = state
end)

-- Egg buttons
for i, egg in ipairs(EGGS) do
    createToggle(egg.Name .. " (" .. egg.Price .. ")", i + 2, function(state)
        egg.Enabled = state
    end)
end

-- === UPDATE COINS DISPLAY ===
spawn(function()
    while wait(0.5) do
        pcall(function()
            CoinLabel.Text = "Coins: " .. tostring(getCoins())
        end)
    end
end)

-- === AUTO CLAIM COINS ===
spawn(function()
    while wait(CLAIM_DELAY) do
        if autoClaimEnabled then
            pcall(function()
                Events:WaitForChild("ClaimCoins"):FireServer("Collect_Coins")
            end)
        end
    end
end)

-- === AUTO BUY EGGS ===
spawn(function()
    local plotId = getPlayerPlot()
    while wait(BUY_DELAY) do
        for _, egg in ipairs(EGGS) do
            if egg.Enabled and getCoins() >= egg.Price then
                pcall(function()
                    local eggsFolder = workspace.Core.Scriptable.Plots[plotId].Eggs
                    for _, child in pairs(eggsFolder:GetChildren()) do
                        if child:GetAttribute("baseName") == egg.Name then
                            Events:WaitForChild("PurchaseConveyorEgg"):FireServer(child.Name, plotId)
                            break
                        end
                    end
                end)
            end
        end
    end
end)
