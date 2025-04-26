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
gearButton.Size = UDim2.new(0, 50, 0, 50)
gearButton.Position = UDim2.new(0.5, -25, 0.05, 0)
gearButton.BackgroundTransparency = 1
gearButton.Image = "rbxassetid://6031091006" -- Gear icon
gearButton.Parent = screenGui

-- Settings Menu
local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 250, 0, 300)
menuFrame.Position = UDim2.new(0.5, -125, 0.5, -150)
menuFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
menuFrame.Visible = false
menuFrame.Parent = screenGui

local uiList = Instance.new("UIListLayout")
uiList.Parent = menuFrame
uiList.Padding = UDim.new(0, 5)
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiList.VerticalAlignment = Enum.VerticalAlignment.Top

local function createToggleButton(text)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 200, 0, 40)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.SourceSansBold
	button.TextSize = 20
	button.Text = text .. ": OFF"
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

--// Drag Function
local function makeDraggable(guiElement)
	local dragging = false
	local dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		guiElement.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

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
			update(input)
		end
	end)
end

makeDraggable(gearButton)
makeDraggable(menuFrame)

--// Gear Toggle
gearButton.MouseButton1Click:Connect(function()
	menuFrame.Visible = not menuFrame.Visible
end)

--// Button Toggles
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

--// ESP
local espFolder = Instance.new("Folder")
espFolder.Name = "ESPFolder"
espFolder.Parent = screenGui

local function createESP(playerTarget)
	local box = Instance.new("BoxHandleAdornment")
	box.Size = Vector3.new(4, 6, 2)
	box.Color3 = Color3.new(1, 1, 0)
	box.Transparency = 0.8
	box.AlwaysOnTop = true
	box.ZIndex = 5
	box.Adornee = playerTarget.Character and playerTarget.Character:FindFirstChild("HumanoidRootPart")
	box.Parent = espFolder
	return box
end

local espObjects = {}

local function updateESP()
	for playerTarget, box in pairs(espObjects) do
		if playerTarget and playerTarget.Character and playerTarget.Character:FindFirstChild("HumanoidRootPart") then
			box.Adornee = playerTarget.Character.HumanoidRootPart
			if playerTarget.Team and player.Team then
				if teamCheck and playerTarget.Team == player.Team then
					box.Color3 = Color3.fromRGB(0, 0, 255)
				else
					box.Color3 = Color3.fromRGB(255, 0, 0)
				end
			else
				box.Color3 = Color3.fromRGB(255, 255, 0)
			end
		else
			box:Destroy()
			espObjects[playerTarget] = nil
		end
	end
end

RunService.RenderStepped:Connect(function()
	if espEnabled then
		for _, targetPlayer in ipairs(Players:GetPlayers()) do
			if targetPlayer ~= player then
				if not espObjects[targetPlayer] then
					espObjects[targetPlayer] = createESP(targetPlayer)
				end
			end
		end
		updateESP()
	else
		for _, box in pairs(espObjects) do
			box:Destroy()
		end
		espObjects = {}
	end
end)

--// Helper Functions
local function getTarget()
	local myChar = player.Character
	if not myChar then return nil end
	local myHumanoid = myChar:FindFirstChild("Humanoid")
	if not myHumanoid or myHumanoid.Health <= 0 then return nil end

	local closestPlayer = nil
	local shortestDistance = math.huge

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local humanoid = otherPlayer.Character:FindFirstChild("Humanoid")
			local part = otherPlayer.Character:FindFirstChild(aimPart)
			if humanoid and humanoid.Health > 0 and part then
				if teamCheck and player.Team == otherPlayer.Team then
					continue
				end

				if wallCheck then
					local ray = workspace:Raycast(camera.CFrame.Position, (part.Position - camera.CFrame.Position).Unit * 999, {player.Character})
					if ray and ray.Instance and not part:IsDescendantOf(ray.Instance.Parent) then
						continue
					end
				end

				local distance = (camera.CFrame.Position - part.Position).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					closestPlayer = part
				end
			end
		end
	end
	return closestPlayer
end

--// Aiming
RunService.RenderStepped:Connect(function()
	if aiming then
		local targetPart = getTarget()
		if targetPart then
			camera.CFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
		end
	end
end)
