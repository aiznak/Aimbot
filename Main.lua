local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Settings
local aiming = false
local aimPart = "Head" -- or "HumanoidRootPart"
local teamCheck = false
local wallCheck = false
local espEnabled = false

local espBoxes = {}

-- UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Gear Button
local gearButton = Instance.new("ImageButton")
gearButton.Size = UDim2.new(0, 50, 0, 50)
gearButton.Position = UDim2.new(0.05, 0, 0.05, 0)
gearButton.Image = "rbxassetid://6031280882" -- gear icon
gearButton.BackgroundTransparency = 1
gearButton.Parent = screenGui

-- Menu Frame (Centered)
local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 220, 0, 260)
menu.Position = UDim2.new(0.5, -110, 0.5, -130) -- Center of screen
menu.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
menu.Visible = false
menu.Parent = screenGui

-- Make gear button draggable
local dragging = false
local dragInput, dragStart, startPos

gearButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = gearButton.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

gearButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		gearButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Toggle menu
gearButton.MouseButton1Click:Connect(function()
	menu.Visible = not menu.Visible
end)

-- Helper to create toggle buttons
local function createToggleButton(text, yPos, toggleFunction)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 40)
	button.Position = UDim2.new(0, 0, 0, yPos)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.TextColor3 = Color3.new(1,1,1)
	button.Font = Enum.Font.SourceSansBold
	button.TextSize = 18
	button.Text = text
	button.Parent = menu
	button.MouseButton1Click:Connect(toggleFunction)
end

-- Create buttons
createToggleButton("Toggle Aimbot", 0, function() aiming = not aiming end)
createToggleButton("Aim for Head/Torso", 40, function()
	if aimPart == "Head" then
		aimPart = "HumanoidRootPart"
	else
		aimPart = "Head"
	end
end)
createToggleButton("Team Check", 80, function() teamCheck = not teamCheck end)
createToggleButton("Wall Check", 120, function() wallCheck = not wallCheck end)
createToggleButton("Toggle ESP", 160, function()
	espEnabled = not espEnabled
	updateESP()
end)

-- ESP creation
local function createHighlight(playerCharacter, color)
	local highlight = Instance.new("Highlight")
	highlight.Adornee = playerCharacter
	highlight.FillColor = color
	highlight.FillTransparency = 0.2
	highlight.OutlineColor = Color3.new(1,1,1)
	highlight.OutlineTransparency = 0.5
	highlight.Parent = screenGui
	return highlight
end

local function getHRPAndHealth(char)
	if char and char:FindFirstChild(aimPart) and char:FindFirstChild("Humanoid") then
		if char.Humanoid.Health > 0 then
			return char[aimPart]
		end
	end
	return nil
end

local function getClosestPlayer()
	local myChar = player.Character
	local myHRP = getHRPAndHealth(myChar)
	if not myHRP then return nil end

	local closestPlayer = nil
	local shortestDistance = math.huge

	for _, otherPlr in ipairs(Players:GetPlayers()) do
		if otherPlr ~= player and otherPlr.Character then
			local otherHRP = getHRPAndHealth(otherPlr.Character)
			if otherHRP then
				if teamCheck and player.Team and otherPlr.Team and player.Team == otherPlr.Team then
					continue
				end

				local dist = (otherHRP.Position - myHRP.Position).Magnitude
				if dist < shortestDistance then
					shortestDistance = dist
					closestPlayer = otherPlr
				end
			end
		end
	end

	return closestPlayer
end

function updateESP()
	for _, v in ipairs(espBoxes) do
		v:Destroy()
	end
	espBoxes = {}

	if not espEnabled then return end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local color
			if teamCheck and player.Team and plr.Team then
				color = (player.Team == plr.Team) and Color3.fromRGB(0,170,255) or Color3.fromRGB(255,0,0)
			else
				color = Color3.fromRGB(255,255,0)
			end

			local highlight = createHighlight(plr.Character, color)
			table.insert(espBoxes, highlight)
		end
	end
end

-- Main Loop
local lastESPUpdate = 0
RunService.RenderStepped:Connect(function(dt)
	if aiming then
		local target = getClosestPlayer()
		if target and target.Character then
			local targetPart = getHRPAndHealth(target.Character)
			if targetPart then
				camera.CFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
			end
		end
	end

	lastESPUpdate += dt
	if lastESPUpdate >= 1 then
		lastESPUpdate = 0
		if espEnabled then
			updateESP()
		end
	end
end)
