local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- === Settings ===
local aiming = false
local aimForHead = false
local teamCheck = false
local wallCheck = false
local espEnabled = false
local espBoxes = {}

-- === UI Setup ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimSettingsUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Gear Button
local gearButton = Instance.new("ImageButton")
gearButton.Size = UDim2.new(0, 50, 0, 50)
gearButton.Position = UDim2.new(1, -60, 1, -60)
gearButton.Image = "rbxassetid://6031094678"
gearButton.BackgroundTransparency = 1
gearButton.Parent = screenGui

-- Settings Frame
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(0, 220, 0, 200)
settingsFrame.Position = UDim2.new(1, -230, 1, -270)
settingsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
settingsFrame.BorderSizePixel = 0
settingsFrame.Visible = false
settingsFrame.Parent = screenGui

local function makeToggle(name, yPosition, default, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 40)
	btn.Position = UDim2.new(0, 10, 0, yPosition)
	btn.Text = name .. ": OFF"
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 18
	btn.Parent = settingsFrame

	local state = default
	local function update()
		state = not state
		btn.Text = name .. ": " .. (state and "ON" or "OFF")
		callback(state)
	end

	btn.MouseButton1Click:Connect(update)
	update()
end

-- Toggle gear menu
gearButton.MouseButton1Click:Connect(function()
	settingsFrame.Visible = not settingsFrame.Visible
end)

-- Settings toggles
makeToggle("Auto Aim", 10, false, function(val) aiming = val end)
makeToggle("Aim for Head", 55, false, function(val) aimForHead = val end)
makeToggle("Team Check", 100, false, function(val) teamCheck = val end)
makeToggle("Wall Check", 145, false, function(val) wallCheck = val end)
makeToggle("ESP", 190, false, function(val)
	espEnabled = val
	if not espEnabled then
		for _, box in pairs(espBoxes) do box:Destroy() end
		espBoxes = {}
	end
end)

-- === ESP Logic ===
local function updateESP()
	for _, box in pairs(espBoxes) do
		if box and box.Parent then box:Destroy() end
	end
	espBoxes = {}

	if not espEnabled then return end

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character then
			local part = plr.Character:FindFirstChild("HumanoidRootPart")
			if part then
				local box = Instance.new("BillboardGui")
				box.Adornee = part
				box.Size = UDim2.new(0, 60, 0, 20)
				box.StudsOffset = Vector3.new(0, 3, 0)
				box.AlwaysOnTop = true
				box.Parent = screenGui

				local label = Instance.new("Frame")
				label.Size = UDim2.new(1, 0, 1, 0)
				label.BackgroundTransparency = 0.3
				label.BorderSizePixel = 0
				label.Parent = box

				-- Color based on team
				if teamCheck and player.Team and plr.Team then
					if player.Team == plr.Team then
						label.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
					else
						label.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
					end
				else
					label.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
				end

				table.insert(espBoxes, box)
			end
		end
	end
end

-- === Targeting Helpers ===
local function isVisible(targetPart)
	if not wallCheck then return true end
	local origin = camera.CFrame.Position
	local direction = (targetPart.Position - origin)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local result = Workspace:Raycast(origin, direction, raycastParams)
	return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function getTargetPart(char)
	if not char then return nil end
	if aimForHead and char:FindFirstChild("Head") then
		return char.Head
	elseif char:FindFirstChild("HumanoidRootPart") then
		return char.HumanoidRootPart
	end
	return nil
end

local function getHRPAndHealth(char)
	if char and char:FindFirstChild("Humanoid") then
		local hrp = getTargetPart(char)
		if hrp and char.Humanoid.Health > 0 then
			return hrp
		end
	end
	return nil
end

local function getClosestPlayer()
	local myChar = player.Character
	if not myChar then return nil end

	local myPart = getTargetPart(myChar)
	if not myPart then return nil end

	local closest = nil
	local shortest = math.huge

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character then
			if teamCheck and player.Team and plr.Team and player.Team == plr.Team then
				continue
			end
			local otherPart = getHRPAndHealth(plr.Character)
			if otherPart and isVisible(otherPart) then
				local dist = (myPart.Position - otherPart.Position).Magnitude
				if dist < shortest then
					shortest = dist
					closest = plr
				end
			end
		end
	end

	return closest
end

-- === Draggable UI Logic ===
local dragging, dragInput, dragStart, startPos

-- Function to handle dragging
local function onDragInputBegan(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = gearButton.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end

local function onDragInputChanged(input)
	if dragging then
		local delta = input.Position - dragStart
		gearButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end

gearButton.InputBegan:Connect(onDragInputBegan)
gearButton.InputChanged:Connect(onDragInputChanged)

-- === Main Loop ===
RunService.RenderStepped:Connect(function()
	if aiming then
		local target = getClosestPlayer()
		if target and target.Character then
			local targetPart = getHRPAndHealth(target.Character)
			if targetPart then
				camera.CFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
			end
		end
	end

	if espEnabled then updateESP() end
end)
