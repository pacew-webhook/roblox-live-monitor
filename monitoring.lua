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
if not httpRequest then
    warn("[Delta Error] Executor tidak mendukung fungsi HTTP request!")
    return
end

-- === MEMBUAT TAMPILAN GUI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MultiAccountSyncGUI"
ScreenGui.ResetOnSpawn = false
pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 140)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 27, 46)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 0, 35)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🌱 " .. LocalPlayer.Name
Title.TextColor3 = Color3.fromRGB(74, 222, 128)
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 25, 0, 25)
MinBtn.Position = UDim2.new(1, -60, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 12
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.Parent = MainFrame
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 30)
StatusLabel.Position = UDim2.new(0, 10, 0, 40)
StatusLabel.BackgroundColor3 = Color3.fromRGB(15, 18, 30)
StatusLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Code
StatusLabel.Text = "Status: Terhubung"
StatusLabel.Parent = MainFrame
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 6)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 35)
ToggleBtn.Position = UDim2.new(0, 10, 0, 85)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
ToggleBtn.TextColor3 = Color3.fromRGB(15, 18, 30)
ToggleBtn.TextSize = 12
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "Status: AKTIF (ON)"
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

-- === FUNGSI SINKRONISASI CLOUD DENGAN SCANNER MENYELURUH ===
local isSyncActive = true

local function updateCloud(removeAccount)
    task.spawn(function()
        pcall(function()
            local successGet, response = pcall(function()
                return httpRequest({
                    Url = URL,
                    Method = "GET",
                    Headers = { ["X-Master-Key"] = API_KEY }
                })
            end)
            
            local currentAccounts = {}
            
            if successGet and response and response.Body then
                local successDecode, decoded = pcall(function()
                    return HttpService:JSONDecode(response.Body)
                end)
                if successDecode and decoded and decoded.record then
                    currentAccounts = decoded.record.accounts or {}
                end
            end
            
            if removeAccount then
                currentAccounts[AccountKey] = nil
            else
                local leaderstatsData = {}
                local ls = LocalPlayer:FindFirstChild("leaderstats")
                if ls then
                    for _, s in ipairs(ls:GetChildren()) do
                        if s:IsA("IntValue") or s:IsA("NumberValue") or s:IsA("StringValue") then
                            leaderstatsData[s.Name] = s.Value
                        end
                    end
                end
                
                -- Simpan data akun ke tabel cloud
                currentAccounts[AccountKey] = {
                    LastUpdate = os.time(),
                    Stats = leaderstatsData
                }
            end
            
            -- Kirim pembaruan ke JSONBin
            httpRequest({
                Url = URL,
                Method = "PUT",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["X-Master-Key"] = API_KEY
                },
                Body = HttpService:JSONEncode({ accounts = currentAccounts })
            })
        end)
    end)
end

-- === INTERAKSI TOMBOL GUI (FIX TOMBOL BERFUNGSI) ===

-- Tombol Close (Menutup GUI dan menghapus data sesi dari Cloud)
CloseBtn.MouseButton1Click:Connect(function()
    updateCloud(true) -- Hapus akun dari cloud saat ditutup
    ScreenGui:Destroy()
end)

-- Tombol Minimize (Mengecilkan/Membesarkan Tampilan Panel)
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

-- Tombol Toggle Status (ON / OFF Sinkronisasi)
ToggleBtn.MouseButton1Click:Connect(function()
    isSyncActive = not isSyncActive
    if isSyncActive then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94) -- Hijau
        ToggleBtn.Text = "Status: AKTIF (ON)"
        StatusLabel.Text = "Status: Terhubung"
        updateCloud(false)
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68) -- Merah
        ToggleBtn.Text = "Status: MATI (OFF)"
        StatusLabel.Text = "Status: Dijeda"
    end
end)

-- Jalankan sinkronisasi awal saat script pertama kali dimuat
updateCloud(false)
