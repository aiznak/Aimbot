--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Variables
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local aiming = false
local espEnabled = false
local teamCheck = false
local wallCheck = false
local aimPart = "Head"

--// UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Gear Button
local gearButton = Instance.new("ImageButton")
gearButton.Size = UDim2.new(0, 40, 0, 40)
gearButton.Position = UDim2.new(0.5, -20, 0.05, 0)
gearButton.BackgroundTransparency = 1
gearButton.Image = "rbxassetid://6031091006"
gearButton.Parent = screenGui

-- Settings Menu
local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 200, 0, 250)
menuFrame.Position = UDim2.new(0.5, -100, 0.5, -125)
menuFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.ClipsDescendants = true
menuFrame.Parent = screenGui

local uiList = Instance.new("UIListLayout")
uiList.Parent = menuFrame
uiList.Padding = UDim.new(0, 4)
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiList.VerticalAlignment = Enum.VerticalAlignment.Top

local function createToggleButton(text)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 180, 0, 30)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.SourceSans
	button.TextSize = 18
	button.Text = text .. ": OFF"
	button.AutoButtonColor = true
	return button
end

-- Toggle Buttons
local aimToggle = createToggleButton("Auto Aim")
local espToggle = createToggleButton("ESP")
local teamCheckToggle = createToggleButton("Team Check")
local wallCheckToggle = createToggleButton("Wall Check")
local aimPartToggle = createToggleButton("Aim Part: Head")

aimToggle.Parent = menuFrame
espToggle.Parent = menuFrame
teamCheckToggle.Parent = menuFrame
wallCheckToggle.Parent = menuFrame
aimPartToggle.Parent = menuFrame

-- Dragging
local function makeDraggable(guiElement)
	local dragging, dragStart, startPos, dragInput

	guiElement.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = guiElement.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	guiElement.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			guiElement.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

makeDraggable(gearButton)
makeDraggable(menuFrame)

-- Gear Button Toggle
gearButton.MouseButton1Click:Connect(function()
	menuFrame.Visible = not menuFrame.Visible
end)

-- Toggle Events
aimToggle.MouseButton1Click:Connect(function()
	aiming = not aiming
	aimToggle.Text = "Auto Aim: " .. (aiming and "ON" or "OFF")
end)

espToggle.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	espToggle.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
end)

teamCheckToggle.MouseButton1Click:Connect(function()
	teamCheck = not teamCheck
	teamCheckToggle.Text = "Team Check: " .. (teamCheck and "ON" or "OFF")
end)

wallCheckToggle.MouseButton1Click:Connect(function()
	wallCheck = not wallCheck
	wallCheckToggle.Text = "Wall Check: " .. (wallCheck and "ON" or "OFF")
end)

aimPartToggle.MouseButton1Click:Connect(function()
	aimPart = (aimPart == "Head") and "HumanoidRootPart" or "Head"
	aimPartToggle.Text = "Aim Part: " .. (aimPart == "Head" and "Head" or "Torso")
end)

-- ESP Setup
local espFolder = Instance.new("Folder")
espFolder.Name = "ESPFolder"
espFolder.Parent = screenGui

local espBoxes = {}

local function createESP(plr)
	local box = Instance.new("BoxHandleAdornment")
	box.Size = Vector3.new(4, 6, 2)
	box.Transparency = 0.8
	box.AlwaysOnTop = true
	box.ZIndex = 5
	box.Color3 = Color3.new(1, 1, 0)
	box.Adornee = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	box.Parent = espFolder
	return box
end

local function updateESP()
	for plr, box in pairs(espBoxes) do
		if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			box.Adornee = plr.Character.HumanoidRootPart
			if teamCheck and player.Team and plr.Team then
				box.Color3 = (plr.Team == player.Team) and Color3.new(0, 0, 1) or Color3.new(1, 0, 0)
			else
				box.Color3 = Color3.new(1, 1, 0)
			end
		else
			box:Destroy()
			espBoxes[plr] = nil
		end
	end
end

RunService.RenderStepped:Connect(function()
	if espEnabled then
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player and not espBoxes[plr] then
				espBoxes[plr] = createESP(plr)
			end
		end
		updateESP()
	else
		for _, box in pairs(espBoxes) do
			box:Destroy()
		end
		espBoxes = {}
	end
end)

-- Wall Check Setup
local function isVisible(part)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {player.Character}
	params.IgnoreWater = true

	local result = workspace:Raycast(camera.CFrame.Position, (part.Position - camera.CFrame.Position).Unit * 500, params)

	if not result then
		return true
	end

	return result.Instance:IsDescendantOf(part.Parent)
end

-- Targeting
local function getTarget()
	local myChar = player.Character
	if not myChar then return nil end
	local myHum = myChar:FindFirstChild("Humanoid")
	if not myHum or myHum.Health <= 0 then return nil end

	local closest, shortest = nil, math.huge

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild(aimPart) then
			local part = plr.Character[aimPart]
			local hum = plr.Character:FindFirstChild("Humanoid")
			if hum and hum.Health > 0 then
				if teamCheck and player.Team == plr.Team then continue end
				if wallCheck and not isVisible(part) then continue end

				local dist = (camera.CFrame.Position - part.Position).Magnitude
				if dist < shortest then
					shortest = dist
					closest = part
				end
			end
		end
	end

	return closest
end

-- Aiming Logic
RunService.RenderStepped:Connect(function()
	if aiming then
		local target = getTarget()
		if target then
			camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
		end
	end
end)
