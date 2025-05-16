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
local lockToCenter = false
local drawLines = false

--// UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Enabled = true
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
menuFrame.Size = UDim2.new(0, 220, 0, 360)
menuFrame.Position = UDim2.new(0.5, -110, 0.5, -180)
menuFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.ClipsDescendants = true
menuFrame.Parent = screenGui

local uiList = Instance.new("UIListLayout")
uiList.Parent = menuFrame
uiList.Padding = UDim.new(0, 6)
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiList.VerticalAlignment = Enum.VerticalAlignment.Top

local function createToggleButton(text)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 200, 0, 30)
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
local lockCenterToggle = createToggleButton("Lock To Screen Center")
local drawLinesToggle = createToggleButton("Draw Lines")

aimToggle.Parent = menuFrame
espToggle.Parent = menuFrame
teamCheckToggle.Parent = menuFrame
wallCheckToggle.Parent = menuFrame
aimPartToggle.Parent = menuFrame
lockCenterToggle.Parent = menuFrame
drawLinesToggle.Parent = menuFrame

-- Dragging Support
local function makeDraggable(guiElement)
	local dragging = false
	local dragInput, dragStart, startPos

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

-- Gear Toggle
gearButton.MouseButton1Click:Connect(function()
	menuFrame.Visible = not menuFrame.Visible
end)

-- Toggle Button Events
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
	aimPart = aimPart == "Head" and "HumanoidRootPart" or "Head"
	aimPartToggle.Text = "Aim Part: " .. (aimPart == "Head" and "Head" or "Torso")
end)

lockCenterToggle.MouseButton1Click:Connect(function()
	lockToCenter = not lockToCenter
	lockCenterToggle.Text = "Lock To Screen Center: " .. (lockToCenter and "ON" or "OFF")
end)

drawLinesToggle.MouseButton1Click:Connect(function()
	drawLines = not drawLines
	drawLinesToggle.Text = "Draw Lines: " .. (drawLines and "ON" or "OFF")
end)

-- ESP
local espFolder = Instance.new("Folder")
espFolder.Name = "ESPFolder"
espFolder.Parent = screenGui

local espBoxes = {}

local function createESP(playerTarget)
	local box = Instance.new("BoxHandleAdornment")
	box.Size = Vector3.new(4, 6, 2)
	box.Transparency = 0.8
	box.Color3 = Color3.new(1, 1, 0)
	box.AlwaysOnTop = true
	box.ZIndex = 5
	box.Adornee = playerTarget.Character and playerTarget.Character:FindFirstChild("HumanoidRootPart")
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

-- Lines Drawing
local lineDrawer = Drawing.new("Line")
lineDrawer.Color = Color3.new(1, 0, 0)
lineDrawer.Thickness = 2
lineDrawer.Transparency = 1
lineDrawer.Visible = false

-- Improved Wall Check
local function canSeeTarget(part)
	if not wallCheck then return true end
	local origin = camera.CFrame.Position
	local direction = (part.Position - origin)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {player.Character}
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	local raycastResult = Workspace:Raycast(origin, direction.Unit * direction.Magnitude, rayParams)
	if raycastResult and raycastResult.Instance and not part:IsDescendantOf(raycastResult.Instance.Parent) then
		return false
	end
	return true
end

-- Team Check based on damageability (simplified: consider same team if can't damage)
local function isTeammate(target)
	if not teamCheck then return false end
	-- You can customize damage check here if you have a damage API
	-- For now, use team equality
	if player.Team and target.Team and player.Team == target.Team then
		return true
	end
	return false
end

-- Get Target closest to center of screen
local function getTarget()
	local myChar = player.Character
	if not myChar then return nil end
	local myHum = myChar:FindFirstChild("Humanoid")
	if not myHum or myHum.Health <= 0 then return nil end

	local closest = nil
	local shortestDist = math.huge
	local center2d = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)

	for _, target in pairs(Players:GetPlayers()) do
		if target ~= player and target.Character and target.Character:FindFirstChild(aimPart) then
			local part = target.Character[aimPart]
			local hum = target.Character:FindFirstChild("Humanoid")
			if hum and hum.Health > 0 then
				if isTeammate(target) then
					continue
				end
				if not canSeeTarget(part) then
					continue
				end

				local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
				if not onScreen then
					continue
				end

				local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - center2d).Magnitude
				if distFromCenter < shortestDist then
					shortestDist = distFromCenter
					closest = part
				end
			end
		end
	end

	return closest
end

-- Aim at target part
local function aimAt(targetPart)
	if targetPart then
		camera.CFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
	end
end

-- Main loop
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

	local targetPart = nil
	if aiming then
		if lockToCenter then
			targetPart = getTarget()
			if targetPart then
				aimAt(targetPart)
			end
		else
			-- normal auto aim: closest target by distance from player
			local myPos = camera.CFrame.Position
			local closest = nil
			local shortest = math.huge
			for _, target in pairs(Players:GetPlayers()) do
				if target ~= player and target.Character and target.Character:FindFirstChild(aimPart) then
					local part = target.Character[aimPart]
					local hum = target.Character:FindFirstChild("Humanoid")
					if hum and hum.Health > 0 and not isTeammate(target) and canSeeTarget(part) then
						local dist = (part.Position - myPos).Magnitude
						if dist < shortest then
							shortest = dist
							closest = part
						end
					end
				end
			end
			if closest then
				aimAt(closest)
			end
		end
	end

	-- Draw lines if enabled
	if drawLines and aiming and targetPart then
		local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
		if onScreen then
			lineDrawer.From = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
			lineDrawer.To = Vector2.new(screenPos.X, screenPos.Y)
			lineDrawer.Visible = true
		else
			lineDrawer.Visible = false
		end
	else
		lineDrawer.Visible = false
	end
end)
