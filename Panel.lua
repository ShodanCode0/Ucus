local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()

-- Temel değişkenler
local flying = false
local noclip = false
local bodyGyro, bodyVelocity
local speedValue = 50
local jumpPowerValue = 100
local runSpeedValue = 16
local physicsPushForce = 500

-- Helper function: newInstance with properties
local function newInstance(className, properties)
    local inst = Instance.new(className)
    for k,v in pairs(properties) do
        inst[k] = v
    end
    return inst
end

-- GUI oluşturma
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = newInstance("ScreenGui", {Name = "ShodanCodePanel", Parent = playerGui})

local mainFrame = newInstance("Frame", {
    Parent = screenGui,
    Size = UDim2.new(0, 350, 0, 400),
    Position = UDim2.new(0, 100, 0, 100),
    BackgroundColor3 = Color3.fromRGB(35, 35, 40),
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
    ClipsDescendants = true,
    ZIndex = 10,
})

local titleBar = newInstance("Frame", {
    Parent = mainFrame,
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(20, 20, 25),
})

local titleLabel = newInstance("TextLabel", {
    Parent = titleBar,
    Size = UDim2.new(1, -50, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    Text = "ShodanCode Panel",
    TextColor3 = Color3.fromRGB(200, 200, 200),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    BackgroundTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local closeButton = newInstance("TextButton", {
    Parent = titleBar,
    Size = UDim2.new(0, 40, 1, 0),
    Position = UDim2.new(1, -45, 0, 0),
    Text = "X",
    TextColor3 = Color3.fromRGB(230, 60, 60),
    Font = Enum.Font.GothamBold,
    TextSize = 22,
    BackgroundColor3 = Color3.fromRGB(35, 35, 40),
    BorderSizePixel = 0,
})

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    stopFlying()
    noclip = false
    setNoclip(false)
    resetCharacterSpeed()
end)

-- Bölme (line) fonksiyonu
local function addDivider(parent, y)
    local line = newInstance("Frame", {
        Parent = parent,
        Size = UDim2.new(1, -20, 0, 1),
        Position = UDim2.new(0, 10, 0, y),
        BackgroundColor3 = Color3.fromRGB(70, 70, 70),
    })
    return line
end

addDivider(mainFrame, 35)

-- Label + Toggle helper
local function addToggle(name, parent, posY, default, callback)
    local lbl = newInstance("TextLabel", {
        Parent = parent,
        Text = name,
        TextColor3 = Color3.fromRGB(210,210,210),
        Font = Enum.Font.Gotham,
        TextSize = 16,
        Size = UDim2.new(0.7, 0, 0, 25),
        Position = UDim2.new(0, 10, 0, posY),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local toggleBtn = newInstance("TextButton", {
        Parent = parent,
        Size = UDim2.new(0, 50, 0, 25),
        Position = UDim2.new(0.75, 0, 0, posY),
        Text = default and "Açık" or "Kapalı",
        BackgroundColor3 = default and Color3.fromRGB(50,200,50) or Color3.fromRGB(180,50,50),
        TextColor3 = Color3.fromRGB(255,255,255),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        BorderSizePixel = 0,
    })

    local toggled = default
    toggleBtn.MouseButton1Click:Connect(function()
        toggled = not toggled
        toggleBtn.Text = toggled and "Açık" or "Kapalı"
        toggleBtn.BackgroundColor3 = toggled and Color3.fromRGB(50,200,50) or Color3.fromRGB(180,50,50)
        callback(toggled)
    end)
end

-- Label + Slider helper
local function addSlider(name, parent, posY, min, max, default, callback)
    local lbl = newInstance("TextLabel", {
        Parent = parent,
        Text = name .. ": " .. tostring(default),
        TextColor3 = Color3.fromRGB(210,210,210),
        Font = Enum.Font.Gotham,
        TextSize = 16,
        Size = UDim2.new(0.7, 0, 0, 25),
        Position = UDim2.new(0, 10, 0, posY),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local slider = newInstance("TextButton", {
        Parent = parent,
        Size = UDim2.new(0.7, 0, 0, 15),
        Position = UDim2.new(0.28, 0, 0, posY + 20),
        BackgroundColor3 = Color3.fromRGB(70,70,70),
        BorderSizePixel = 0,
        Text = "",
    })

    local fill = newInstance("Frame", {
        Parent = slider,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(50, 200, 50),
    })

    local dragging = false

    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    slider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    slider.InputChanged:Connect(function(input)
        if dragging then
            local pos = math.clamp(input.Position.X - slider.AbsolutePosition.X, 0, slider.AbsoluteSize.X)
            local val = (pos / slider.AbsoluteSize.X) * (max - min) + min
            fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
            lbl.Text = name .. ": " .. string.format("%.1f", val)
            callback(val)
        end
    end)
end

-- ** Uçuş fonksiyonları **
local function startFlying()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.P = 9e4
    bodyGyro.maxTorque = Vector3.new(9e9,9e9,9e9)
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0,0,0)
    bodyVelocity.MaxForce = Vector3.new(9e9,9e9,9e9)
    bodyVelocity.Parent = hrp

    flying = true

    local rs = game:GetService("RunService")
    local connection
    connection = rs.RenderStepped:Connect(function()
        if not flying then
            connection:Disconnect()
            return
        end
        if char and char:FindFirstChild("Humanoid") then
            local moveDir = char.Humanoid.MoveDirection
            bodyVelocity.Velocity = (moveDir * speedValue) + Vector3.new(0, 0.5, 0)
            bodyGyro.CFrame = workspace.CurrentCamera.CFrame
        end
    end)
end

local function stopFlying()
    flying = false
    if bodyGyro then bodyGyro:Destroy() end
    if bodyVelocity then bodyVelocity:Destroy() end
end

-- Noclip fonksiyonu
local function setNoclip(enabled)
    local char = player.Character
    if not char then return end

    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = not enabled
        end
    end
end

-- Hız ve Zıplama ayarları
local function setCharacterSpeed(speed)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

local function setCharacterJumpPower(jumpPower)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.JumpPower = jumpPower
    end
end

local function resetCharacterSpeed()
    setCharacterSpeed(16)
    setCharacterJumpPower(50)
end

-- Physics Push: temas eden Anchor olmayan objeleri iter
local