-- Script: Drop de Loot do NPC com chance de Tool
-- Localização: dentro do NPC
-- Funcionalidade: ao morrer, dropar Tool(s) com 33% de chance e Coins
-- Estrurura Esperada no NPC : 
-- NPC "pode ter qualquer nome" ( Humanoid , HumanoidRootPart, Tool "pode ter qualquer nome" , Coin "Model de coletable coin" , IA_Script , Drop_Script)
local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local hrp = npc:WaitForChild("HumanoidRootPart")

-- CONFIGURAÇÃO
local coinCount = 5 -- quantidade de coins que o NPC vai dropar
local dropRadius = 5 -- raio máximo para posicionar os drops
local toolDropChance = 0.33 -- 33% de chance de dropar cada Tool

-- Função para pegar todas as Tools do NPC
local function getNPCTools()
	local tools = {}
	for _, obj in ipairs(npc:GetChildren()) do
		if obj:IsA("Tool") then
			table.insert(tools, obj)
		end
	end
	return tools
end

-- Função para pegar o modelo Coin dentro do NPC
local function getCoinModel()
	return npc:FindFirstChild("Coin")
end

-- Função para calcular posição aleatória ao redor do NPC
local function getRandomDropPosition(center, radius)
	local angle = math.random() * 2 * math.pi
	local distance = math.random() * radius
	local x = math.cos(angle) * distance
	local z = math.sin(angle) * distance
	return center + Vector3.new(x, 0, z)
end

-- Evento ao morrer
humanoid.Died:Connect(function()
	local npcPos = hrp.Position

	-- Dropar todas as Tools com chance
	local tools = getNPCTools()
	for _, tool in ipairs(tools) do
		if math.random() < toolDropChance then
			local toolClone = tool:Clone()
			toolClone.Parent = workspace
			local dropPos = getRandomDropPosition(npcPos, dropRadius)
			if toolClone:FindFirstChild("Handle") then
				toolClone.Handle.CFrame = CFrame.new(dropPos)
				toolClone.Handle.CanCollide = true
			end
		end
	end

	-- Dropar Coins
	local coinTemplate = getCoinModel()
	if coinTemplate then
		for i = 1, coinCount do
			local coinClone = coinTemplate:Clone()
			coinClone.Parent = workspace
			local dropPos = getRandomDropPosition(npcPos, dropRadius)
			if coinClone.PrimaryPart then
				coinClone:SetPrimaryPartCFrame(CFrame.new(dropPos))
			end
		end
	end
end)
