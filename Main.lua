local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Settings
local aiming = false
local teamCheck = false
local wallCheck = false
local aimPart = "Head" -- Head or Torso
local espEnabled = false

-- === UI Setup ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Gear Button
local gearButton = Instance.new("ImageButton")
gearButton.Size = UDim2.new(0, 50, 0, 50)
gearButton.Position = UDim2.new(0, 10, 0, 10)
gearButton.BackgroundTransparency = 1
gearButton.Image = "rbxassetid://6031280882" -- Gear icon
gearButton.Parent = screenGui

-- Menu Frame
local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 200, 0, 300)
menu.Position = UDim2.new(0.5, -100, 0.5, -150)
menu.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
menu.BorderSizePixel = 0
menu.Visible = false
menu.Parent = screenGui

-- Dragging
local dragging, dragInput, dragStart, startPos

gearButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.Touch then
		dragging = true
		dragStart = input.Position
		startPos = gearButton.Position
	end
end)

gearButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

RunService.RenderStepped:Connect(function()
	if dragging and dragInput then
		local delta = dragInput.Position - dragStart
		gearButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- Toggle menu
gearButton.MouseButton1Click:Connect(function()
	menu.Visible = not menu.Visible
end)

-- Button creator
local function createToggleButton(text, posY, toggleVarName)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 40)
	button.Position = UDim2.new(0, 0, 0, posY)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.TextColor3 = Color3.new(1,1,1)
	button.Font = Enum.Font.SourceSansBold
	button.TextSize = 18
	button.Text = text .. ": OFF"
	button.Parent = menu
	
	button.MouseButton1Click:Connect(function()
		_G[toggleVarName] = not _G[toggleVarName]
		button.Text = text .. ": " .. (_G[toggleVarName] and "ON" or "OFF")
	end)
	
	return button
end

-- Toggle Buttons
_G.aiming = false
_G.teamCheck = false
_G.wallCheck = false
_G.espEnabled = false

createToggleButton("Auto Aim", 0, "aiming")
createToggleButton("Team Check", 50, "teamCheck")
createToggleButton("Wall Check", 100, "wallCheck")
createToggleButton("ESP", 150, "espEnabled")

-- Switch Aim Part Button
local aimPartButton = Instance.new("TextButton")
aimPartButton.Size = UDim2.new(1, 0, 0, 40)
aimPartButton.Position = UDim2.new(0, 0, 0, 200)
aimPartButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
aimPartButton.TextColor3 = Color3.new(1,1,1)
aimPartButton.Font = Enum.Font.SourceSansBold
aimPartButton.TextSize = 18
aimPartButton.Text = "Aim Part: Head"
aimPartButton.Parent = menu

aimPartButton.MouseButton1Click:Connect(function()
	aimPart = (aimPart == "Head") and "HumanoidRootPart" or "Head"
	aimPartButton.Text = "Aim Part: " .. (aimPart == "Head" and "Head" or "Torso")
end)

-- ESP Storage
local espFolder = Instance.new("Folder")
espFolder.Name = "ESPFolder"
espFolder.Parent = screenGui

local function clearESP()
	for _, obj in ipairs(espFolder:GetChildren()) do
		obj:Destroy()
	end
end

local function createHighlight(plr)
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.8
	highlight.OutlineTransparency = 0.8
	highlight.Adornee = plr.Character
	highlight.Parent = espFolder
	
	if player.Team and plr.Team then
		if player.Team == plr.Team then
			highlight.FillColor = Color3.fromRGB(0, 0, 255) -- Blue = Ally
		else
			highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Red = Enemy
		end
	else
		highlight.FillColor = Color3.fromRGB(255, 255, 0) -- Yellow = No team
	end
end

-- Wall check helper
local function hasLineOfSight(fromPos, toPos)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.FilterDescendantsInstances = {player.Character}

	local rayResult = workspace:Raycast(fromPos, (toPos - fromPos), rayParams)

	return not rayResult -- Clear if nothing hit
end

-- Helper to get target part safely
local function getTargetPart(character)
	if character then
		if aimPart == "Head" and character:FindFirstChild("Head") then
			return character.Head
		elseif aimPart == "HumanoidRootPart" and character:FindFirstChild("HumanoidRootPart") then
			return character.HumanoidRootPart
		end
	end
	return nil
end

-- Find closest alive enemy
local function getClosestPlayer()
	local myChar = player.Character
	local myHRP = getTargetPart(myChar)
	if not myHRP then return nil end

	local closestPlayer = nil
	local shortestDistance = math.huge

	for _, otherPlr in ipairs(Players:GetPlayers()) do
		if otherPlr ~= player and otherPlr.Character then
			local otherHRP = getTargetPart(otherPlr.Character)
			local humanoid = otherPlr.Character:FindFirstChild("Humanoid")
			if otherHRP and humanoid and humanoid.Health > 0 then
				if _G.teamCheck and player.Team and otherPlr.Team and player.Team == otherPlr.Team then
					continue
				end

				if _G.wallCheck and not hasLineOfSight(camera.CFrame.Position, otherHRP.Position) then
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

-- Main Loops
RunService.RenderStepped:Connect(function()
	-- Aiming
	if _G.aiming then
		local target = getClosestPlayer()
		if target and target.Character then
			local targetPart = getTargetPart(target.Character)
			if targetPart then
				camera.CFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
			end
		end
	end
	
	-- ESP
	clearESP()
	if _G.espEnabled then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character and plr.Character:FindFirstChild("Humanoid") then
				if plr.Character:FindFirstChild("Humanoid").Health > 0 then
					createHighlight(plr)
				end
			end
		end
	end
end)
