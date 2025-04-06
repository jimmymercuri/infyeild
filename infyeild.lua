local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure Humanoid & Animator exist
local humanoid = character:FindFirstChildOfClass("Humanoid")
if not humanoid then
    warn("No Humanoid found!")
    return
end

local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then
    animator = Instance.new("Animator")
    animator.Parent = humanoid
end
local function findAnimations()
    local animations = {}

    local function searchForAnimations(parent)
        for _, child in parent:GetChildren() do
            if child:IsA("Animation") then
                animations[child.Name] = child.AnimationId
            elseif child:IsA("Folder") or child:IsA("Model") then
                searchForAnimations(child) -- Recursively search inside folders and models
            end
        end
    end

    -- Check common locations where animations might be stored
    local locationsToCheck = {
        game.ReplicatedStorage,
    }

    for _, location in ipairs(locationsToCheck) do
        if location then
            searchForAnimations(location)
        end
    end

    return animations
end


-- Store animations & key binds
local animations = findAnimations()
local animationTracks = {}
local keyBinds = {}

for name, animId in pairs(animations) do
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    animationTracks[name] = animator:LoadAnimation(anim)
end

-- UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 500)
mainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40) -- Taller bar
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Text = "Animation Binder"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextScaled = true
titleLabel.Parent = titleBar

-- Minimise Button
local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 40, 1, 0)
minimizeButton.Position = UDim2.new(1, -40, 0, 0)
minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
minimizeButton.Text = "-"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextScaled = true
minimizeButton.Parent = titleBar

local notification = Instance.new("TextLabel")
notification.Size = UDim2.new(0, 250, 0, 30)
notification.Position = UDim2.new(0, 10, 1, -40)
notification.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
notification.TextColor3 = Color3.fromRGB(255, 255, 255)
notification.Text = "Binder minimised. Press Tab to reopen."
notification.Font = Enum.Font.Gotham
notification.TextScaled = true
notification.Visible = false
notification.Parent = screenGui

local minimized = false
local lastPosition = mainFrame.Position

minimizeButton.MouseButton1Click:Connect(function()
    minimized = true
    lastPosition = mainFrame.Position
    mainFrame.Visible = false
    notification.Visible = true
end)

userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Tab and minimized then
        minimized = false
        mainFrame.Position = lastPosition
        mainFrame.Visible = true
        notification.Visible = false

    elseif input.KeyCode == Enum.KeyCode.Tab and minimized == false then
        minimized = true
        mainFrame.Position = lastPosition
        mainFrame.Visible = false
        notification.Visible = true
    end
end)

-- Search Bar
local searchBar = Instance.new("TextBox")
searchBar.Size = UDim2.new(1, -10, 0, 30)
searchBar.Position = UDim2.new(0, 5, 0, 45)
searchBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
searchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBar.PlaceholderText = "Search animations..."
searchBar.Font = Enum.Font.Gotham
searchBar.TextScaled = true
searchBar.Parent = mainFrame

-- Scrollable Animation List
local animationList = Instance.new("ScrollingFrame")
animationList.Size = UDim2.new(1, 0, 1, -80)
animationList.Position = UDim2.new(0, 0, 0, 80)
animationList.CanvasSize = UDim2.new(0, 0, 0, #animations * 55)
animationList.ScrollBarThickness = 8
animationList.BackgroundTransparency = 1
animationList.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = animationList

-- Function to create animation buttons
local buttons = {}

local function createAnimationButton(name)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.8, 0, 0, 50)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = name .. " [Bind: None]"
    button.Font = Enum.Font.Gotham
    button.TextScaled = true
    button.Parent = animationList

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 10)
    uiCorner.Parent = button

    buttons[name] = button

    button.MouseButton1Click:Connect(function()
        -- Stop the previous animation if it's playing
        for oldKey, oldAnimation in pairs(keyBinds) do
            if oldAnimation == name then
                local oldTrack = animationTracks[oldKey]
                if oldTrack then
                    oldTrack:Stop()
                end
            end
        end
        
        -- Ask for new key bind
        button.Text = name .. " [Press a Key...]"
        
        local connection
        connection = userInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            local newKey = input.KeyCode.Name
            -- Remove the old keybind if exists
            for oldKey, oldAnimation in pairs(keyBinds) do
                if oldAnimation == name then
                    keyBinds[oldKey] = nil  -- Remove old keybind
                end
            end
            
            -- Update keyBinds with new key
            keyBinds[newKey] = name
            button.Text = name .. " [Bind: " .. newKey .. "]"
            connection:Disconnect()
        end)
    end)
end

-- Create buttons for all animations
for name, _ in pairs(animations) do
    createAnimationButton(name)
end

-- Adjust scrolling dynamically
animationList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    animationList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

-- Search Functionality
searchBar:GetPropertyChangedSignal("Text"):Connect(function()
    local searchText = searchBar.Text:lower()
    for name, button in pairs(buttons) do
        button.Visible = name:lower():find(searchText) ~= nil
    end
end)

-- Detect key presses & play animation
userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    local key = input.KeyCode.Name
    if keyBinds[key] and animationTracks[keyBinds[key]] then
        animationTracks[keyBinds[key]]:Play()
    end
end)

local function stopAllAnimations()
    for _, track in pairs(animationTracks) do
        if track.IsPlaying then
            track:Stop()
        end
    end
end

userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Backspace then
        stopAllAnimations()
    end
end)
