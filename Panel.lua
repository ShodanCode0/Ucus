-- Simple Fly Script V2
-- Çalıştırmak için executor gerekir (Arceus X, Hydrogen, vb.)

local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local humanoidRootPart = char:WaitForChild("HumanoidRootPart")

local UIS = game:GetService("UserInputService")
local flying = false
local speed = 50
local bodyGyro, bodyVelocity

function startFly()
    flying = true
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.P = 9e4
    bodyGyro.Parent = humanoidRootPart
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0,0,0)
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Parent = humanoidRootPart
    
    game:GetService("RunService").RenderStepped:Connect(function()
        if flying then
            bodyGyro.CFrame = workspace.CurrentCamera.CFrame
            local direction = Vector3.new()
            if UIS:IsKeyDown(Enum.KeyCode.W) then direction += workspace.CurrentCamera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then direction -= workspace.CurrentCamera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then direction -= workspace.CurrentCamera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then direction += workspace.CurrentCamera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then direction -= Vector3.new(0, 1, 0) end
            bodyVelocity.Velocity = direction.Unit * speed
        end
    end)
end

function stopFly()
    flying = false
    if bodyGyro then bodyGyro:Destroy() end
    if bodyVelocity then bodyVelocity:Destroy() end
end

-- Aktif/pasif tuşu: F
UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F then
        if flying then
            stopFly()
        else
            startFly()
        end
    end
end)
