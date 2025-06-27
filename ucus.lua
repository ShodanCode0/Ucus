local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Admin kontrol (kendi adını ekle)
local ADMINS = {["SeninKullaniciAdin"] = true}
if not ADMINS[player.Name] then return end

-- Basit GUI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0, 300, 0, 400)
panel.Position = UDim2.new(0.5, -150, 0.5, -200)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
panel.Visible = false

local openBtn = Instance.new("TextButton", gui)
openBtn.Text = "Admin Panel"
openBtn.Size = UDim2.new(0, 120, 0, 40)
openBtn.Position = UDim2.new(1, -130, 0, 10)
openBtn.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)

local function createButton(text, y, cb)
	local btn = Instance.new("TextButton", panel)
	btn.Size = UDim2.new(1, -20, 0, 35)
	btn.Position = UDim2.new(0, 10, 0, y)
	btn.Text = text
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 18
	btn.MouseButton1Click:Connect(cb)
end

-- Uçma değişkenleri
local flying = false
local flyConn

local function toggleFly()
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	if not hrp or not hum then return end

	flying = not flying
	if flying then
		hum.PlatformStand = true
		flyConn = RunService.RenderStepped:Connect(function()
			hrp.Velocity = workspace.CurrentCamera.CFrame.LookVector * 50
		end)
	else
		if flyConn then flyConn:Disconnect() end
		hum.PlatformStand = false
	end
end

-- Noclip toggle
local noclip = false
local noclipConn

local function toggleNoclip()
	noclip = not noclip
	local char = player.Character
	if not char then return end
	if noclip then
		noclipConn = RunService.Stepped:Connect(function()
			for _, p in pairs(char:GetChildren()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end)
	else
		if noclipConn then noclipConn:Disconnect() end
		for _, p in pairs(char:GetChildren()) do
			if p:IsA("BasePart") then p.CanCollide = true end
		end
	end
end

-- ESP Basit
local ESPFolder = Instance.new("Folder", gui)
ESPFolder.Name = "ESPFolder"
local ESPOn = false

local function createESP(plr)
	local char = plr.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	if not hrp or not hum then return end

	local billboard = Instance.new("BillboardGui", ESPFolder)
	billboard.Adornee = hrp
	billboard.Size = UDim2.new(0,150,0,50)
	billboard.AlwaysOnTop = true

	local label = Instance.new("TextLabel", billboard)
	label.Size = UDim2.new(1,0,1,0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1,0,0)
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = 14
	label.Text = plr.Name .. " | HP: " .. math.floor(hum.Health)

	hum:GetPropertyChangedSignal("Health"):Connect(function()
		label.Text = plr.Name .. " | HP: " .. math.floor(hum.Health)
	end)
end

local function toggleESP()
	ESPOn = not ESPOn
	ESPFolder:ClearAllChildren()
	if ESPOn then
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player then
				createESP(plr)
			end
		end
		Players.PlayerAdded:Connect(function(plr)
			if ESPOn and plr ~= player then
				plr.CharacterAdded:Connect(function()
					wait(1)
					createESP(plr)
				end)
			end
		end)
	end
end

-- Butonlar
createButton("Işınlan (0,10,0)", 10, function()
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.CFrame = CFrame.new(0,10,0)
	end
end)

createButton("Hız = 100", 55, function()
	local hum = player.Character and player.Character:FindFirstChild("Humanoid")
	if hum then hum.WalkSpeed = 100 end
end)

createButton("Zıplama = 150", 100, function()
	local hum = player.Character and player.Character:FindFirstChild("Humanoid")
	if hum then hum.JumpPower = 150 end
end)

createButton("Uçmayı Aç/Kapat", 145, toggleFly)
createButton("NoClip Aç/Kapat", 190, toggleNoclip)
createButton("ESP Aç/Kapat", 235, toggleESP)

createButton("Tüm Oyunculara Işınlan", 280, function()
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(2,0,0)
			wait(1)
		end
	end
end)
