-- Script: Spawn de NPC
-- Localização: dentro do modelo Spawn_NPC
-- Estrutura esperada: 
-- Spawn_NPC
-- ├── Spawn (Part)
-- ├── Spawn_Script (Script)
-- ├── NPC_1, NPC_2, NPC_3 ... (Modelos de NPC)

local spawnModel = script.Parent
local spawnPart = spawnModel:WaitForChild("Spawn") -- Part que marca o ponto de spawn

-- Função para pegar um NPC aleatório dentro do Spawn_NPC
local function getRandomNPC()
	local npcOptions = {}
	for _, obj in ipairs(spawnModel:GetChildren()) do
		if obj:IsA("Model") and obj.Name ~= "Spawn" then
			table.insert(npcOptions, obj)
		end
	end
	if #npcOptions == 0 then
		warn("Nenhum NPC encontrado para spawnar!")
		return nil
	end
	local index = math.random(1, #npcOptions)
	return npcOptions[index]
end

-- Função para spawnar o NPC
local function spawnNPC()
	local npcTemplate = getRandomNPC()
	if not npcTemplate then return end

	local npcClone = npcTemplate:Clone()
	npcClone.Parent = workspace
	-- Posicionar o NPC em cima da Spawn Part
	local spawnCFrame = spawnPart.CFrame + Vector3.new(0, spawnPart.Size.Y/2 + (npcClone.PrimaryPart and npcClone.PrimaryPart.Size.Y/2 or 0), 0)
	if npcClone.PrimaryPart then
		npcClone:SetPrimaryPartCFrame(spawnCFrame)
	else
		-- Se não tiver PrimaryPart, mover todos os filhos
		for _, part in ipairs(npcClone:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CFrame = part.CFrame + spawnCFrame.Position
			end
		end
	end

	-- Monitorar NPC: quando morrer, spawnar outro
	local humanoid = npcClone:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			task.wait(1) -- pequeno delay antes do respawn
			spawnNPC()
		end)
	end
end

-- Spawn inicial
spawnNPC()
