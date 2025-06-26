-- GUI öğelerini oluştur
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "FlyGui"

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 200, 0, 100)
mainFrame.Position = UDim2.new(0, 50, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 25)
topBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

local closeButton = Instance.new("TextButton", topBar)
closeButton.Size = UDim2.new(0, 25, 1, 0)
closeButton.Position = UDim2.new(1, -25, 0, 0)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)

local toggleButton = Instance.new("TextButton", mainFrame)
toggleButton.Size = UDim2.new(1, -20, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 40)
toggleButton.Text = "Aç"
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 24

-- Uçuş değişkenleri
local flying = false
local bodyGyro
local bodyVelocity
local speed = 50

-- Uçuş başlat
local function startFlying()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.P = 9e4
    bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Parent = hrp

    flying = true

    -- Hareketi takip et
    game:GetService("RunService").RenderStepped:Connect(function()
        if flying and character and character:FindFirstChild("Humanoid") then
            local moveDir = character.Humanoid.MoveDirection
            bodyVelocity.Velocity = (moveDir * speed) + Vector3.new(0, 0.5, 0)
            bodyGyro.CFrame = workspace.CurrentCamera.CFrame
        end
    end)
end

-- Uçuşu durdur
local function stopFlying()
    flying = false
    if bodyGyro then bodyGyro:Destroy() end
    if bodyVelocity then bodyVelocity:Destroy() end
end

-- Buton işlevi: Aç/Kapat
toggleButton.MouseButton1Click:Connect(function()
    if flying then
        stopFlying()
        toggleButton.Text = "Aç"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    else
        startFlying()
        toggleButton.Text = "Kapat"
        toggleButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
    end
end)

-- X butonuna basınca GUI'yi yok et
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    stopFlying()
end)