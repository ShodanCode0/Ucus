--!strict

-- Core Roblox Servisleri
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TextChatService = game:GetService("TextChatService")

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
local flySpeed = 50
local flyKeys = {
    Forward = Enum.KeyCode.W,
    Backward = Enum.KeyCode.S,
    Left = Enum.KeyCode.A,
    Right = Enum.KeyCode.D,
    Up = Enum.KeyCode.Space,
    Down = Enum.KeyCode.LeftShift
}

-- Mobil kontroller için
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local touchControlsFrame: Frame? = nil
local touchJoystick: Frame? = nil
local touchJumpButton: TextButton? = nil
local touchFlyUpButton: TextButton? = nil
local touchFlyDownButton: TextButton? = nil

-- Aktif Bağlantılar (temizlik için)
local touchConnection: RBXScriptConnection? = nil
local driveConnection: RBXScriptConnection? = nil
local diedConnection: RBXScriptConnection? = nil
local seatedConnection: RBXScriptConnection? = nil
local characterAddedConnection: RBXScriptConnection? = nil
local flyConnection: RBXScriptConnection? = nil
local chatConnection: RBXScriptConnection? = nil

--- Panel Oluşturma ---

-- Ana ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ShodanCodeFeaturePanel"
ScreenGui.Parent = playerGui

-- Ana Çerçeve (Ana Panel)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainPanel"
MainFrame.Size = UDim2.new(0.3, 0, 0.7, 0)
MainFrame.Position = UDim2.new(0.35, 0, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
MainFrame.Active = true
MainFrame.Draggable = true
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
    if isFlying then toggleFly(false) end
    if isNoclipping then toggleNoclip(false) end
    if canFirlat then toggleFirlat(false) end
    if isAutoDriving then toggleAutoDrive(false) end
    if chatConnection then chatConnection:Disconnect() end
end)

-- Özellikler için ScrollFrame (Kaydırılabilir Alan)
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "FeaturesScrollFrame"
ScrollFrame.Size = UDim2.new(1, 0, 0.9, 0)
ScrollFrame.Position = UDim2.new(0, 0, 0.1, 0)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.Parent = MainFrame

-- Özellik Butonlarını düzenlemek için UIListLayout
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollFrame
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Her özellik için fonksiyon ve buton oluşturma şablonu
local function createToggleButton(name: string, defaultText: string, activeText: string, color: Color3, callback: (boolean) -> ())
    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Size = UDim2.new(0.9, 0, 0.09, 0)
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

-- Mobil kontrolleri oluştur
local function createMobileControls()
    if not isMobile then return end
    
    -- Ana kontrol çerçevesi
    touchControlsFrame = Instance.new("Frame")
    touchControlsFrame.Name = "MobileControls"
    touchControlsFrame.Size = UDim2.new(1, 0, 0.3, 0)
    touchControlsFrame.Position = UDim2.new(0, 0, 0.7, 0)
    touchControlsFrame.BackgroundTransparency = 1
    touchControlsFrame.Parent = ScreenGui

    -- Joystick (hareket kontrolü)
    touchJoystick = Instance.new("Frame")
    touchJoystick.Name = "Joystick"
    touchJoystick.Size = UDim2.new(0.2, 0, 0.2, 0)
    touchJoystick.Position = UDim2.new(0.05, 0, 0.5, 0)
    touchJoystick.AnchorPoint = Vector2.new(0, 0.5)
    touchJoystick.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    touchJoystick.BackgroundTransparency = 0.7
    touchJoystick.Parent = touchControlsFrame

    local joystickUICorner = Instance.new("UICorner")
    joystickUICorner.CornerRadius = UDim.new(0.5, 0)
    joystickUICorner.Parent = touchJoystick

    -- Zıplama butonu
    touchJumpButton = Instance.new("TextButton")
    touchJumpButton.Name = "JumpButton"
    touchJumpButton.Size = UDim2.new(0.15, 0, 0.15, 0)
    touchJumpButton.Position = UDim2.new(0.8, 0, 0.7, 0)
    touchJumpButton.Text = "Zıpla"
    touchJumpButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    touchJumpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    touchJumpButton.Font = Enum.Font.SourceSansBold
    touchJumpButton.TextSize = 16
    touchJumpButton.Parent = touchControlsFrame

    local jumpUICorner = Instance.new("UICorner")
    jumpUICorner.CornerRadius = UDim.new(0.5, 0)
    jumpUICorner.Parent = touchJumpButton

    -- Uçuş kontrolleri (sadece uçma aktifse görünür)
    touchFlyUpButton = Instance.new("TextButton")
    touchFlyUpButton.Name = "FlyUpButton"
    touchFlyUpButton.Size = UDim2.new(0.15, 0, 0.15, 0)
    touchFlyUpButton.Position = UDim2.new(0.8, 0, 0.5, 0)
    touchFlyUpButton.Text = "Yukarı"
    touchFlyUpButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    touchFlyUpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    touchFlyUpButton.Font = Enum.Font.SourceSansBold
    touchFlyUpButton.TextSize = 16
    touchFlyUpButton.Visible = false
    touchFlyUpButton.Parent = touchControlsFrame

    local flyUpUICorner = Instance.new("UICorner")
    flyUpUICorner.CornerRadius = UDim.new(0.5, 0)
    flyUpUICorner.Parent = touchFlyUpButton

    touchFlyDownButton = Instance.new("TextButton")
    touchFlyDownButton.Name = "FlyDownButton"
    touchFlyDownButton.Size = UDim2.new(0.15, 0, 0.15, 0)
    touchFlyDownButton.Position = UDim2.new(0.8, 0, 0.8, 0)
    touchFlyDownButton.Text = "Aşağı"
    touchFlyDownButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    touchFlyDownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    touchFlyDownButton.Font = Enum.Font.SourceSansBold
    touchFlyDownButton.TextSize = 16
    touchFlyDownButton.Visible = false
    touchFlyDownButton.Parent = touchControlsFrame

    local flyDownUICorner = Instance.new("UICorner")
    flyDownUICorner.CornerRadius = UDim.new(0.5, 0)
    flyDownUICorner.Parent = touchFlyDownButton

    -- Joystick hareketi için bağlantılar
    local joystickActive = false
    local joystickPosition = Vector2.new(0, 0)
    local joystickStartPosition = Vector2.new(0, 0)

    touchJoystick.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            joystickActive = true
            joystickStartPosition = Vector2.new(input.Position.X, input.Position.Y)
        end
    end)

    touchJoystick.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            joystickActive = false
            joystickPosition = Vector2.new(0, 0)
        end
    end)

    UserInputService.TouchMoved:Connect(function(input, processed)
        if not processed and joystickActive then
            local currentPosition = Vector2.new(input.Position.X, input.Position.Y)
            joystickPosition = (currentPosition - joystickStartPosition) * 0.01 -- Duyarlılık ayarı
        end
    end)

    -- Zıplama butonu
    touchJumpButton.MouseButton1Down:Connect(function()
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end)

    -- Uçuş butonları
    touchFlyUpButton.MouseButton1Down:Connect(function()
        flyKeys.Up = Enum.KeyCode.Space -- Yukarı uçma
    end)

    touchFlyUpButton.MouseButton1Up:Connect(function()
        flyKeys.Up = nil
    end)

    touchFlyDownButton.MouseButton1Down:Connect(function()
        flyKeys.Down = Enum.KeyCode.LeftShift -- Aşağı uçma
    end)

    touchFlyDownButton.MouseButton1Up:Connect(function()
        flyKeys.Down = nil
    end)
end

-- Karakter Yeniden Doğduğunda Durumları Sıfırlama
local function resetFeaturesOnSpawn()
    -- Önceki bağlantıları temizle
    if diedConnection then diedConnection:Disconnect() end
    if seatedConnection then seatedConnection:Disconnect() end
    if touchConnection then touchConnection:Disconnect() end
    if driveConnection then driveConnection:Disconnect() end
    if flyConnection then flyConnection:Disconnect() end

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
    
    -- Mobil kontrolleri yeniden oluştur
    if isMobile then
        createMobileControls()
    end
end

characterAddedConnection = player.CharacterAdded:Connect(resetFeaturesOnSpawn)
diedConnection = humanoid.Died:Connect(resetFeaturesOnSpawn) -- İlk bağlantıyı kur

-- Hız Ayarı
local speedStates = {defaultWalkSpeed, 30, 50, 80, 120}
local function setWalkSpeed(speed: number)
    humanoid.WalkSpeed = speed
end
local speedButton = createCycleButton("Speed", "Hız: ", speedStates, 1, Color3.fromRGB(70, 130, 180), setWalkSpeed)

-- Zıplama Yüksekliği Ayarı
local jumpStates = {defaultJumpPower, 100, 200, 500, 1000}
local function setJumpPower(power: number)
    humanoid.JumpPower = power
end
local jumpButton = createCycleButton("Jump", "Zıplama: ", jumpStates, 1, Color3.fromRGB(70, 130, 180), setJumpPower)

-- Uçma (Fly) Özelliği
local function handleFly(input: InputObject, gameProcessed: boolean)
    if not isFlying or gameProcessed then return end
    
    local flyDirection = Vector3.new(0, 0, 0)
    
    -- Klavye kontrolleri
    if input.KeyCode == flyKeys.Forward then
        flyDirection = flyDirection + humanoidRootPart.CFrame.LookVector
    elseif input.KeyCode == flyKeys.Backward then
        flyDirection = flyDirection - humanoidRootPart.CFrame.LookVector
    elseif input.KeyCode == flyKeys.Left then
        flyDirection = flyDirection - humanoidRootPart.CFrame.RightVector
    elseif input.KeyCode == flyKeys.Right then
        flyDirection = flyDirection + humanoidRootPart.CFrame.RightVector
    elseif input.KeyCode == flyKeys.Up then
        flyDirection = flyDirection + Vector3.new(0, 1, 0)
    elseif input.KeyCode == flyKeys.Down then
        flyDirection = flyDirection + Vector3.new(0, -1, 0)
    end
    
    -- Mobil kontroller
    if isMobile and joystickPosition ~= Vector2.new(0, 0) then
        flyDirection = flyDirection + 
            (humanoidRootPart.CFrame.LookVector * joystickPosition.Y) +
            (humanoidRootPart.CFrame.RightVector * joystickPosition.X)
    end
    
    if flyDirection.Magnitude > 0 then
        flyDirection = flyDirection.Unit * flySpeed
        humanoidRootPart.Velocity = flyDirection
    else
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    end
end

local function toggleFly(active: boolean)
    isFlying = active
    
    if isFlying then
        humanoid.PlatformStand = true
        Workspace.Gravity = 0
        
        -- Uçuş bağlantısını kur
        flyConnection = RunService.Heartbeat:Connect(function()
            handleFly({KeyCode = Enum.KeyCode.Unknown}, false) -- Sürekli güncelleme için
        end)
        
        -- Mobil kontrolleri göster
        if isMobile and touchFlyUpButton and touchFlyDownButton then
            touchFlyUpButton.Visible = true
            touchFlyDownButton.Visible = true
        end
    else
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        humanoid.PlatformStand = false
        Workspace.Gravity = defaultGravity
        
        -- Mobil kontrolleri gizle
        if isMobile and touchFlyUpButton and touchFlyDownButton then
            touchFlyUpButton.Visible = false
            touchFlyDownButton.Visible = false
        end
    end
end

local flyButton, initialFlyState = createToggleButton("Fly", "Uçma: Kapalı", "Uçma: Açık", Color3.fromRGB(70, 130, 180), toggleFly)

-- Noclip Özelliği
local function toggleNoclip(active: boolean)
    isNoclipping = active
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            task.spawn(function()
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
            local direction = humanoidRootPart.CFrame.lookVector * 150
            otherPart:ApplyImpulse(direction * otherPart:GetMass() * 0.1)
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
    if driveConnection then driveConnection:Disconnect() end
    driveConnection = RunService.Heartbeat:Connect(function()
        if seat and seat.Occupant == humanoid then
            seat.Throttle = 1
            seat.Steer = 0
        else
            toggleAutoDrive(false)
            autoDriveButton.Text = "Otomatik Sürüş: Kapalı"
        end
    end)
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
end

local function toggleAutoDrive(active: boolean)
    isAutoDriving = active
    if isAutoDriving then
        if currentVehicleSeat and currentVehicleSeat.Occupant == humanoid then
            startAutoDrive(currentVehicleSeat)
        end
    else
        stopAutoDrive()
    end
end

local function onCharacterSeated(seated: boolean, seat: Seat?)
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
end

seatedConnection = humanoid.Seated:Connect(onCharacterSeated)

local autoDriveButton, initialAutoDriveState = createToggleButton("AutoDrive", "Otomatik Sürüş: Kapalı", "Otomatik Sürüş: Açık", Color3.fromRGB(70, 130, 180), toggleAutoDrive)

-- Chat komutları
local function handleChatCommands(message: string)
    local args = string.split(string.lower(message), " ")
    local command = args[1]
    
    if command == "/fly" then
        toggleFly(not isFlying)
        return true -- Mesajı gizle
    elseif command == "/speed" and args[2] then
        local speed = tonumber(args[2])
        if speed then
            humanoid.WalkSpeed = speed
            return true
        end
    elseif command == "/jump" and args[2] then
        local power = tonumber(args[2])
        if power then
            humanoid.JumpPower = power
            return true
        end
    elseif command == "/noclip" then
        toggleNoclip(not isNoclipping)
        return true
    end
    
    return false
end

-- Chat bağlantısını kur
if TextChatService then
    chatConnection = TextChatService.OnIncomingMessage:Connect(function(message: TextChatMessage)
        if message.TextSource then
            if message.TextSource.UserId == player.UserId then
                if handleChatCommands(message.Text) then
                    -- Komut işlendi, mesajı gizle
                    task.defer(function()
                        if message:IsDescendantOf(game) then
                            message:Destroy()
                        end
                    end)
                end
            end
        end
    end)
end

-- CanvasSize'ı tüm elemanlar yerleştirildikten sonra ayarla
local function updateCanvasSize()
    local contentHeight = UIListLayout.AbsoluteContentSize.Y
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight + UIListLayout.Padding.Offset)
end

-- Tüm UI elemanları eklendikten sonra bir kez güncelle
task.wait(0.1)
updateCanvasSize()

-- UI elemanları eklendiğinde veya çıkarıldığında CanvasSize'ı güncelle
UIListLayout.ChildAdded:Connect(updateCanvasSize)
UIListLayout.ChildRemoved:Connect(updateCanvasSize)

-- Panel gizleme/gösterme için bir tuş bağlama (örneğin 'P' tuşu)
local isPanelVisible = true

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if input.KeyCode == Enum.KeyCode.P and not gameProcessedEvent then
        isPanelVisible = not isPanelVisible
        MainFrame.Visible = isPanelVisible
    end
end)

-- Mobil kontrolleri oluştur
createMobileControls()
