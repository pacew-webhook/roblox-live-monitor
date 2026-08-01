-- Konfigurasi Koneksi Cloud
local BIN_ID = "6a6b4a70f5f4af5e29d5a623"
local API_KEY = "$2a$10$SQCp/OkqnUEFvNA1EYKrwuRqqrZIxzO7G1tJuDos7XgY1l1cySG4y"
local URL = "https://api.jsonbin.io/v3/b/" .. BIN_ID

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local AccountKey = LocalPlayer.Name 

local httpRequest = (syn and syn.request) or (fluxus and fluxus.request) or request or http_request
if not httpRequest then return end

local function getAutomaticPackageName()
    local detectedPackage = "com.roblox.client"
    pcall(function()
        local execName = ""
        if identifyexecutor then
            local name, version = identifyexecutor()
            execName = tostring(name or ""):lower()
        elseif getexecutorname then
            local name, version = getexecutorname()
            execName = tostring(name or ""):lower()
        end
        if execName:find("delta") then
            detectedPackage = "com.roblox.client"
        end
    end)
    return detectedPackage
end

-- === GUI DI GAME ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MultiAccountSyncGUI"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 140)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 27, 46)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -70, 0, 35)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🌱 " .. LocalPlayer.Name
Title.TextColor3 = Color3.fromRGB(74, 222, 128)
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold

local MinBtn = Instance.new("TextButton", MainFrame)
MinBtn.Size = UDim2.new(0, 25, 0, 25)
MinBtn.Position = UDim2.new(1, -60, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 12
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, -20, 0, 30)
StatusLabel.Position = UDim2.new(0, 10, 0, 40)
StatusLabel.BackgroundColor3 = Color3.fromRGB(15, 18, 30)
StatusLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Code
StatusLabel.Text = "Status: Menghubungkan..."
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 6)

local ToggleBtn = Instance.new("TextButton", MainFrame)
ToggleBtn.Size = UDim2.new(1, -20, 0, 35)
ToggleBtn.Position = UDim2.new(0, 10, 0, 85)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
ToggleBtn.TextColor3 = Color3.fromRGB(15, 18, 30)
ToggleBtn.TextSize = 12
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "Status: AKTIF (ON)"
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

local isSyncActive = true

local function getItemCount(item)
    local count = 1
    pcall(function()
        for _, attrName in ipairs({"Count", "Amount", "Quantity", "Value", "Stack"}) do
            local val = item:GetAttribute(attrName)
            if type(val) == "number" and val > 0 then
                count = val
                return
            end
        end
        for _, child in ipairs(item:GetChildren()) do
            if (child:IsA("IntValue") or child:IsA("NumberValue")) and child.Value > 0 then
                count = child.Value
                return
            end
        end
    end)
    return count
end

local function sendDataToCloud()
    task.spawn(function()
        pcall(function()
            local successGet, response = pcall(function()
                return httpRequest({ Url = URL, Method = "GET", Headers = { ["X-Master-Key"] = API_KEY } })
            end)
            
            local currentAccounts = {}
            local currentCommands = {}
            
            if successGet and response and response.Body then
                local successDecode, decoded = pcall(function() return HttpService:JSONDecode(response.Body) end)
                if successDecode and decoded and decoded.record then
                    currentAccounts = decoded.record.accounts or {}
                    currentCommands = decoded.record.commands or {}
                    
                    -- CEK APAKAH ADA PERINTAH KHUSUS UNTUK AKUN INI
                    if currentCommands[AccountKey] then
                        local cmd = currentCommands[AccountKey]
                        if cmd == "stop" then
                            StatusLabel.Text = "Status: Dimatikan dari Web"
                            isSyncActive = false
                            ToggleBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
                            ToggleBtn.Text = "Status: MATI (OFF)"
                            
                            -- Hapus akun dari list cloud saat di-stop
                            currentAccounts[AccountKey] = nil
                            currentCommands[AccountKey] = nil -- Bersihkan command
                            
                            httpRequest({
                                Url = URL,
                                Method = "PUT",
                                Headers = { ["Content-Type"] = "application/json", ["X-Master-Key"] = API_KEY },
                                Body = HttpService:JSONEncode({ accounts = currentAccounts, commands = currentCommands })
                            })
                            
                            task.wait(1)
                            ScreenGui:Destroy()
                            return
                        end
                    end
                end
            end
            
            local sheklesValue = 0
            pcall(function()
                local ls = LocalPlayer:FindFirstChild("leaderstats")
                if ls then
                    for _, s in ipairs(ls:GetChildren()) do
                        local sName = s.Name:lower()
                        if sName:find("shekle") or sName:find("money") or sName:find("cash") or sName:find("coin") then
                            sheklesValue = s.Value
                            break
                        end
                    end
                end
            end)

            local inventoryData = {}
            pcall(function()
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    for _, item in ipairs(backpack:GetChildren()) do
                        local name = item.Name
                        inventoryData[name] = { count = getItemCount(item) }
                    end
                end
            end)
            
            currentAccounts[AccountKey] = {
                LastUpdate = os.time(),
                package = getAutomaticPackageName(),
                shekles = sheklesValue,
                items = inventoryData,
                metrics = { fps = 60, ping = 45 }
            }
            
            httpRequest({
                Url = URL,
                Method = "PUT",
                Headers = { ["Content-Type"] = "application/json", ["X-Master-Key"] = API_KEY },
                Body = HttpService:JSONEncode({ accounts = currentAccounts, commands = currentCommands })
            })
            
            StatusLabel.Text = "Terupdate: " + os.date("%H:%M:%S")
        end)
    end)
end

local function removeDataFromCloud()
    task.spawn(function()
        pcall(function()
            local successGet, response = pcall(function()
                return httpRequest({ Url = URL, Method = "GET", Headers = { ["X-Master-Key"] = API_KEY } })
            end)
            if successGet and response and response.Body then
                local successDecode, decoded = pcall(function() return HttpService:JSONDecode(response.Body) end)
                if successDecode and decoded and decoded.record then
                    local currentAccounts = decoded.record.accounts or {}
                    local currentCommands = decoded.record.commands or {}
                    currentAccounts[AccountKey] = nil
                    httpRequest({
                        Url = URL,
                        Method = "PUT",
                        Headers = { ["Content-Type"] = "application/json", ["X-Master-Key"] = API_KEY },
                        Body = HttpService:JSONEncode({ accounts = currentAccounts, commands = currentCommands })
                    })
                end
            end
        end)
    end)
end

CloseBtn.MouseButton1Click:Connect(function()
    removeDataFromCloud()
    task.wait(0.5)
    ScreenGui:Destroy()
end)

local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 220, 0, 35)
        StatusLabel.Visible = false
        ToggleBtn.Visible = false
        MinBtn.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, 220, 0, 140)
        StatusLabel.Visible = true
        ToggleBtn.Visible = true
        MinBtn.Text = "-"
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    isSyncActive = not isSyncActive
    if isSyncActive then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
        ToggleBtn.Text = "Status: AKTIF (ON)"
        sendDataToCloud()
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
        ToggleBtn.Text = "Status: MATI (OFF)"
        removeDataFromCloud()
    end
end)

sendDataToCloud()
task.spawn(function()
    while true do
        if isSyncActive then
            sendDataToCloud()
        end
        task.wait(2)
    end
end)
