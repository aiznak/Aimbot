--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

--// Variables
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
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
gearButton.Image = "rbxassetid://6031091006"
gearButton.Parent = screenGui

-- Settings Menu (Rounded Pill Style)
local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 200, 0, 300)
menuFrame.Position = UDim2.new(0.5, -100, 0.5, -150)
menuFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
menuFrame.Visible = false
menuFrame.ClipsDescendants = true
menuFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 25)
corner.Parent = menuFrame

local uiList = Instance.new("UIListLayout")
uiList.Parent = menuFrame
uiList.Padding = UDim.new(0, 5)
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiList.VerticalAlignment = Enum.VerticalAlignment.Top

local function createToggleButton(text)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 180, 0, 40)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.SourceSansBold
	button.TextSize = 18
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

-- Draggable Function
local function makeDraggable(gui)
	local dragging, dragInput, dragStart, startPos

	gui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = gui.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end

		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

makeDraggable(gearButton)
makeDraggable(menuFrame)

-- Gear Toggle
gearButton.MouseButton1Click:Connect(function()
	menuFrame.Visible = not menuFrame.Visible
end)

-- Button Functions
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

-- ESP Logic
local espFolder = Instance.new("Folder")
espFolder.Name = "ESPFolder"
espFolder.Parent = screenGui

local function createESP(target)
	local box = Instance.new("BoxHandleAdornment")
	box.Size = Vector3.new(4, 6, 2)
	box.Transparency = 0.8
	box.AlwaysOnTop = true
	box.ZIndex = 5
	box.Adornee = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	box.Parent = espFolder
	return box
end

local espObjects = {}

local function updateESP()
	for plr, box in pairs(espObjects) do
		if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			box.Adornee = plr.Character.HumanoidRootPart
			if teamCheck and plr.Team == player.Team then
				box.Color3 = Color3.fromRGB(0, 0, 255)
			elseif plr.Team == nil or player.Team == nil then
				box.Color3 = Color3.fromRGB(255, 255, 0)
			else
				box.Color3 = Color3.fromRGB(255, 0, 0)
			end
		else
			box:Destroy()
			espObjects[plr] = nil
		end
	end
end

RunService.RenderStepped:Connect(function()
	if espEnabled then
		for _, target in ipairs(Players:GetPlayers()) do
			if target ~= player then
				if not espObjects[target] then
					espObjects[target] = createESP(target)
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

-- Get Target
local function getTarget()
	local myChar = player.Character
	if not myChar then return nil end

	local myHumanoid = myChar:FindFirstChild("Humanoid")
	if not myHumanoid or myHumanoid.Health <= 0 then return nil end

	local closest = nil
	local minDist = math.huge

	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character then
			local humanoid = other.Character:FindFirstChild("Humanoid")
			local part = other.Character:FindFirstChild(aimPart)
			if humanoid and humanoid.Health > 0 and part then
				if teamCheck and player.Team == other.Team then
					continue
				end

				if wallCheck then
					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Blacklist
					rayParams.FilterDescendantsInstances = {player.Character}

					local result = Workspace:Raycast(camera.CFrame.Position, (part.Position - camera.CFrame.Position).Unit * 999, rayParams)

					if result and result.Instance and not part:IsDescendantOf(result.Instance.Parent) then
						continue
					end
				end

				local distance = (camera.CFrame.Position - part.Position).Magnitude
				if distance < minDist then
					minDist = distance
					closest = part
				end
			end
		end
	end

	return closest
end

-- Auto Aim
RunService.RenderStepped:Connect(function()
	if aiming then
		local target = getTarget()
		if target then
			camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
		end
	end
end)
