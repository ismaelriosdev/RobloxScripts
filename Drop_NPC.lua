-- Script: Drop de Loot do NPC com chance de Tool e auto-desaparecimento
-- Localização: dentro do NPC
-- Funcionalidade: ao morrer, dropar Tool(s) com 33% de chance e Coins; desaparecem se não coletados em 2 minutos
-- Estrutura esperada no NPC: 
-- NPC "pode ter qualquer nome" ( Humanoid, HumanoidRootPart, Tool "qualquer nome", Coin "Model de coletável", IA_Script, Drop_Script )

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local hrp = npc:WaitForChild("HumanoidRootPart")

-- CONFIGURAÇÃO
local coinCount = 5 -- quantidade de coins que o NPC vai dropar
local dropRadius = 5 -- raio máximo para posicionar os drops
local toolDropChance = 0.33 -- 33% de chance de dropar cada Tool
local dropLifetime = 120 -- tempo em segundos antes do drop desaparecer (2 minutos)

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

-- Função para criar drop com auto-desaparecimento
local function createDrop(item, position)
	item.Parent = workspace
	-- Posicionar corretamente
	if item:IsA("Tool") and item:FindFirstChild("Handle") then
		item.Handle.CFrame = CFrame.new(position)
		item.Handle.CanCollide = true
	elseif item.PrimaryPart then
		item:SetPrimaryPartCFrame(CFrame.new(position))
	end

	-- Desaparecer após dropLifetime segundos se não coletado
	task.delay(dropLifetime, function()
		if item and item.Parent then
			item:Destroy()
		end
	end)
end

-- Evento ao morrer
humanoid.Died:Connect(function()
	local npcPos = hrp.Position

	-- Dropar todas as Tools com chance
	local tools = getNPCTools()
	for _, tool in ipairs(tools) do
		if math.random() < toolDropChance then
			local toolClone = tool:Clone()
			local dropPos = getRandomDropPosition(npcPos, dropRadius)
			createDrop(toolClone, dropPos)
		end
	end

	-- Dropar Coins
	local coinTemplate = getCoinModel()
	if coinTemplate then
		for i = 1, coinCount do
			local coinClone = coinTemplate:Clone()
			local dropPos = getRandomDropPosition(npcPos, dropRadius)
			createDrop(coinClone, dropPos)
		end
	end
end)
