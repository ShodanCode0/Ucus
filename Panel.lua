--!strict

-- Core Roblox Servisleri
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Yerel Oyuncu ve Karakter Bilgileri
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Varsayılan Değerler
local defaultWalkSpeed = humanoid.WalkSpeed
local defaultJumpPower = humanoid.JumpPower
local defaultGravity = Workspace.Gravity

-- Özellik Durumları
local isFlying = false
local isNoclipping = false
local canFirlat = false
local isAutoDriving = false
local currentVehicleSeat: VehicleSeat? = nil

-- Aktif Bağlantılar (temizlik için)
local touchConnection: RBXScriptConnection? = nil
local driveConnection: RBXScriptConnection? = nil
local diedConnection: RBXScriptConnection? = nil
local seatedConnection: RBXScriptConnection? = nil
local characterAddedConnection: RBXScriptConnection? = nil

--- Panel Oluşturma ---

-- Ana ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ShodanCodeFeaturePanel"
ScreenGui.Parent = playerGui

-- Ana Çerçeve (Ana Panel)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainPanel"
MainFrame.Size = UDim2.new(0.3, 0, 0.7, 0) -- Ekranın %30 genişliği, %70 yüksekliği
MainFrame.Position = UDim2.new(0.35, 0, 0.15, 0) -- Ekranın ortasına yakın konumlandır
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
MainFrame.Active = true -- Sürüklemek için gerekli
MainFrame.Draggable = true -- Sürüklenebilir yap
MainFrame.Parent = ScreenGui

-- UI Corner (köşeleri yumuşatma)
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Başlık Çubuğu
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0.1, 0)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TitleBar.Parent = MainFrame

-- Başlık Metni
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0.85, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 22
TitleLabel.Text = "ShodanCode Özellik Paneli"
TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
TitleLabel.Parent = TitleBar

-- Kapatma Butonu
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0.15, 0, 1, 0)
CloseButton.Position = UDim2.new(0.85, 0, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 20
CloseButton.Text = "X"
CloseButton.Parent = TitleBar

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    -- Panel kapatıldığında tüm özellikleri varsayılana döndür
    humanoid.WalkSpeed = defaultWalkSpeed
    humanoid.JumpPower = defaultJumpPower
    if isFlying then toggleFly() end
    if isNoclipping then toggleNoclip() end
    if canFirlat then toggleFirlat() end
    if isAutoDriving then toggleAutoDrive() end
end)

-- Özellikler için ScrollFrame (Kaydırılabilir Alan)
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "FeaturesScrollFrame"
ScrollFrame.Size = UDim2.new(1, 0, 0.9, 0)
ScrollFrame.Position = UDim2.new(0, 0, 0.1, 0)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- İçerik eklendikçe otomatik ayarlanacak
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.Parent = MainFrame

-- Özellik Butonlarını düzenlemek için UIListLayout
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollFrame
UIListLayout.Padding = UDim.new(0, 8) -- Butonlar arası boşluk
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Her özellik için fonksiyon ve buton oluşturma şablonu
local function createToggleButton(name: string, defaultText: string, activeText: string, color: Color3, callback: (boolean) -> ())
    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Size = UDim2.new(0.9, 0, 0.09, 0) -- Sabit boyut
    button.BackgroundColor3 = color
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 18
    button.Text = defaultText
    button.Parent = ScrollFrame

    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, 6)
    uic.Parent = button

    local isActive = false
    button.MouseButton1Click:Connect(function()
        isActive = not isActive
        button.Text = isActive and activeText or defaultText
        callback(isActive)
    end)
    return button, isActive
end

local function createCycleButton(name: string, prefix: string, states: {any}, initialIndex: number, color: Color3, callback: (any) -> ())
    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Size = UDim2.new(0.9, 0, 0.09, 0)
    button.BackgroundColor3 = color
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 18
    button.Text = prefix .. states[initialIndex]
    button.Parent = ScrollFrame

    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, 6)
    uic.Parent = button

    local currentIndex = initialIndex
    button.MouseButton1Click:Connect(function()
        currentIndex = (currentIndex % #states) + 1
        local value = states[currentIndex]
        button.Text = prefix .. value
        callback(value)
    end)
    callback(states[initialIndex]) -- Başlangıç değerini ayarla
    return button
end

--- Özellik Fonksiyonları ---

-- Karakter Yeniden Doğduğunda Durumları Sıfırlama
local function resetFeaturesOnSpawn()
    -- Önceki bağlantıları temizle
    if diedConnection then diedConnection:Disconnect() end
    if seatedConnection then seatedConnection:Disconnect() end
    if touchConnection then touchConnection:Disconnect() end
    if driveConnection then driveConnection:Disconnect() end

    -- Yeni karakteri bekle
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    humanoid.WalkSpeed = defaultWalkSpeed
    humanoid.JumpPower = defaultJumpPower
    Workspace.Gravity = defaultGravity

    -- Uçma ve Noclip durumlarını sıfırla ve UI'ı güncelle
    if isFlying then toggleFly(false) end
    if isNoclipping then toggleNoclip(false) end
    if canFirlat then toggleFirlat(false) end
    if isAutoDriving then toggleAutoDrive(false) end
    currentVehicleSeat = nil

    -- Yeniden doğduktan sonra yeni bağlantıları kur
    diedConnection = humanoid.Died:Connect(resetFeaturesOnSpawn)
    seatedConnection = humanoid.Seated:Connect(onCharacterSeated)
end

characterAddedConnection = player.CharacterAdded:Connect(resetFeaturesOnSpawn)
diedConnection = humanoid.Died:Connect(resetFeaturesOnSpawn) -- İlk bağlantıyı kur

-- Hız Ayarı
local speedStates = {defaultWalkSpeed, 30, 50, 80, 120} -- Varsayılan hız da dahil
local function setWalkSpeed(speed: number)
    humanoid.WalkSpeed = speed
end
local speedButton = createCycleButton("Speed", "Hız: ", speedStates, 1, Color3.fromRGB(70, 130, 180), setWalkSpeed)

-- Zıplama Yüksekliği Ayarı
local jumpStates = {defaultJumpPower, 100, 200, 500, 1000} -- Varsayılan zıplama gücü de dahil
local function setJumpPower(power: number)
    humanoid.JumpPower = power
end
local jumpButton = createCycleButton("Jump", "Zıplama: ", jumpStates, 1, Color3.fromRGB(70, 130, 180), setJumpPower)

-- Uçma (Fly) Özelliği
local function toggleFly(active: boolean)
    isFlying = active
    if isFlying then
        humanoid.PlatformStand = true
        humanoidRootPart.Anchored = true
        Workspace.Gravity = 0
    else
        humanoidRootPart.Anchored = false
        humanoid.PlatformStand = false
        Workspace.Gravity = defaultGravity
    end
end
local flyButton, initialFlyState = createToggleButton("Fly", "Uçma: Kapalı", "Uçma: Açık", Color3.fromRGB(70, 130, 180), toggleFly)

-- Noclip Özelliği
local function toggleNoclip(active: boolean)
    isNoclipping = active
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            task.spawn(function() -- Her parçayı ayrı bir iş parçacığında işle
                pcall(function()
                    part.CanCollide = not isNoclipping
                end)
            end)
        end
    end
end
local noclipButton, initialNoclipState = createToggleButton("Noclip", "Noclip: Kapalı", "Noclip: Açık", Color3.fromRGB(70, 130, 180), toggleNoclip)

-- Anchor'u Olmayan Objeleri Fırlatma
local function onPartTouched(otherPart: BasePart)
    if canFirlat and otherPart and otherPart.Parent ~= character and otherPart.Parent ~= Workspace.Terrain then
        if otherPart:IsA("BasePart") and not otherPart.Anchored then
            local direction = humanoidRootPart.CFrame.lookVector * 150 -- İtme yönü ve gücü
            -- Eğer obje çok ağırsa daha fazla güç uygulayabilirsin
            otherPart:ApplyImpulse(direction * otherPart:GetMass() * 0.1) -- Kütleye göre itme gücü, çarpanı ayarla
        end
    end
end

local function toggleFirlat(active: boolean)
    canFirlat = active
    if canFirlat then
        if not touchConnection then
            touchConnection = humanoidRootPart.Touched:Connect(onPartTouched)
        end
    else
        if touchConnection then
            touchConnection:Disconnect()
            touchConnection = nil
        end
    end
end
local firlatmaButton, initialFirlatState = createToggleButton("Firlatma", "Objeleri Fırlat: Kapalı", "Objeleri Fırlat: Açık", Color3.fromRGB(70, 130, 180), toggleFirlat)

-- Araçları Otomatik Sürme
local function startAutoDrive(seat: VehicleSeat)
    if driveConnection then driveConnection:Disconnect() end -- Önceki bağlantıyı kes
    driveConnection = RunService.Heartbeat:Connect(function()
        if seat and seat.Occupant == humanoid then
            seat.Throttle = 1 -- Sürekli ileri git
            seat.Steer = 0 -- Direksiyonu düz tut
            -- Daha gelişmiş otomatik sürüş algoritmaları burada eklenebilir.
            -- Örneğin, bir hedef noktasına yönelme veya bir patikayı takip etme.
        else
            -- Koltuktan kalkarsa otomatik sürüşü durdur
            toggleAutoDrive(false)
            autoDriveButton.Text = "Otomatik Sürüş: Kapalı"
        end
    end)
    print("Otomatik sürüş başladı!")
end

local function stopAutoDrive()
    if driveConnection then
        driveConnection:Disconnect()
        driveConnection = nil
    end
    if currentVehicleSeat then
        currentVehicleSeat.Throttle = 0
        currentVehicleSeat.Steer = 0
    end
    print("Otomatik sürüş durdu.")
end

local function toggleAutoDrive(active: boolean)
    isAutoDriving = active
    if isAutoDriving then
        if currentVehicleSeat and currentVehicleSeat.Occupant == humanoid then
            startAutoDrive(currentVehicleSeat)
        else
            -- Eğer araçta değilse, özelliği aktif et ama hemen sürme
            warn("Otomatik sürüş açıldı, ancak bir araçta değilsiniz. Araca bindiğinizde başlayacaktır.")
        end
    else
        stopAutoDrive()
    end
end

-- Oyuncu bir koltuğa oturduğunda kontrol
seatedConnection = humanoid.Seated:Connect(function(seated: boolean, seat: Seat?)
    if seated and seat:IsA("VehicleSeat") then
        currentVehicleSeat = seat
        if isAutoDriving then
            startAutoDrive(currentVehicleSeat)
        end
    else
        if isAutoDriving then
            stopAutoDrive()
        end
        currentVehicleSeat = nil
    end
end)

local autoDriveButton, initialAutoDriveState = createToggleButton("AutoDrive", "Otomatik Sürüş: Kapalı", "Otomatik Sürüş: Açık", Color3.fromRGB(70, 130, 180), toggleAutoDrive)


-- CanvasSize'ı tüm elemanlar yerleştirildikten sonra ayarla
local function updateCanvasSize()
    local contentHeight = UIListLayout.AbsoluteContentSize.Y
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight + UIListLayout.Padding.Offset)
end

-- Tüm UI elemanları eklendikten sonra bir kez güncelle
task.wait(0.1) -- UI elemanlarının oluşturulması için kısa bir bekleme
updateCanvasSize()

-- UI elemanları eklendiğinde veya çıkarıldığında CanvasSize'ı güncelle
UIListLayout.ChildAdded:Connect(updateCanvasSize)
UIListLayout.ChildRemoved:Connect(updateCanvasSize)

-- Panel gizleme/gösterme için bir tuş bağlama (örneğin 'P' tuşu)
local UserInputService = game:GetService("UserInputService")
local isPanelVisible = true

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if input.KeyCode == Enum.KeyCode.P and not gameProcessedEvent then
        isPanelVisible = not isPanelVisible
        MainFrame.Visible = isPanelVisible
    end
end)
