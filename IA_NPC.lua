-- Script: IA_NPC
-- Localização: dentro do Model do NPC (junto ao Humanoid e Tool)
-- "Estrutura esperada dentro do Model do seu NPC"
-- "NPC"
-- "├── Animations"
-- "│   ├── Walk (Animation)"
-- "│   ├── Run (Animation)"
-- "│   └── Jump (Animation)"
-- "├── Humanoid"
-- "├── HumanoidRootPart"
-- "├── Tool"
-- "└── IA_NPC (Script)"

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local animations = npc:WaitForChild("Animations")
local tool = nil
for _, obj in ipairs(npc:GetChildren()) do
    if obj:IsA("Tool") then
        tool = obj
        break
    end
end

local hrp = npc:WaitForChild("HumanoidRootPart")

-- Configurações
local patrolSpeed = 8
local chaseSpeed = 16
local detectRange = 80
local loseRange = 100
local jumpChance = 0.1
local patrolDelay = 3
local attackRange = 8
local attackCooldown = 2 -- segundos

-- Carregar animações
local animWalk = humanoid:LoadAnimation(animations:WaitForChild("Walk"))
local animRun = humanoid:LoadAnimation(animations:WaitForChild("Run"))
local animJump = humanoid:LoadAnimation(animations:WaitForChild("Jump"))

local players = game:GetService("Players")
local pathfindingService = game:GetService("PathfindingService")

local chasing = false
local currentTarget = nil
local lastAttackTime = 0

-- Função auxiliar: calcular distância
local function getDistance(a, b)
	return (a.Position - b.Position).Magnitude
end

-- Detectar player mais próximo
local function getNearestPlayer()
	local nearest = nil
	local shortestDist = detectRange + 1
	for _, player in ipairs(players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = getDistance(hrp, player.Character.HumanoidRootPart)
			if dist < shortestDist then
				shortestDist = dist
				nearest = player
			end
		end
	end
	return nearest
end

-- Gerar posição aleatória para patrulha
local function getRandomPatrolPos()
	return hrp.Position + Vector3.new(
		math.random(-60, 60),
		0,
		math.random(-60, 60)
	)
end

-- Função para mover usando Pathfinding
local function moveToPosition(targetPos)
	local path = pathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentJumpHeight = 10,
		AgentMaxSlope = 45,
	})
	path:ComputeAsync(hrp.Position, targetPos)

	if path.Status == Enum.PathStatus.Complete then
		local waypoints = path:GetWaypoints()
		for _, wp in ipairs(waypoints) do
			if wp.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end
			humanoid:MoveTo(wp.Position)
			humanoid.MoveToFinished:Wait()
			if chasing and currentTarget then
				break
			end
		end
	end
end

-- Pular com chance
local function randomJump()
	if math.random() < jumpChance then
		animJump:Play()
		humanoid.Jump = true
	end
end

-- Função para aplicar dano apenas de players
local function setupDamageHandler()
	for _, player in ipairs(players:GetPlayers()) do
		player.CharacterAdded:Connect(function(char)
			-- Conectar todas as ferramentas do player
			for _, tool in ipairs(char:GetChildren()) do
				if tool:IsA("Tool") then
					local handle = tool:FindFirstChild("Handle")
					if handle then
						handle.Touched:Connect(function(hit)
							if hit:IsDescendantOf(npc) then
								local dmg = tool:FindFirstChild("Damage")
								if dmg and dmg.Value then
									humanoid:TakeDamage(dmg.Value)
								end
							end
						end)
					end
				end
			end
			-- Detectar futuras ferramentas equipadas
			char.ChildAdded:Connect(function(c)
				if c:IsA("Tool") then
					local handle = c:WaitForChild("Handle",5)
					if handle then
						handle.Touched:Connect(function(hit)
							if hit:IsDescendantOf(npc) then
								local dmg = c:FindFirstChild("Damage")
								if dmg and dmg.Value then
									humanoid:TakeDamage(dmg.Value)
								end
							end
						end)
					end
				end
			end)
		end)
	end
end

setupDamageHandler()

-- Loop de patrulha
local function patrol()
	chasing = false
	currentTarget = nil
	animRun:Stop()
	animWalk:Play()
	humanoid.WalkSpeed = patrolSpeed

	while not chasing do
		local randomPos = getRandomPatrolPos()
		moveToPosition(randomPos)
		randomJump()

		local startTime = tick()
		while tick() - startTime < patrolDelay do
			local target = getNearestPlayer()
			if target then
				chasing = true
				currentTarget = target
				break
			end
			task.wait(0.1)
		end
	end
end

-- Loop de perseguição com mira contínua e cooldown
local function chase()
	if not currentTarget then return end
	animWalk:Stop()
	animRun:Play()
	humanoid.WalkSpeed = chaseSpeed
	tool.Parent = npc
	humanoid:EquipTool(tool)

	while chasing do
		if not currentTarget.Character or not currentTarget.Character:FindFirstChild("HumanoidRootPart") then
			chasing = false
			break
		end

		local targetHRP = currentTarget.Character.HumanoidRootPart
		local dist = getDistance(hrp, targetHRP)

		if dist > loseRange then
			chasing = false
			break
		end

		-- Rotacionar NPC continuamente para o jogador
		local lookVector = (targetHRP.Position - hrp.Position).Unit
		hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(lookVector.X, 0, lookVector.Z))

		-- Mover usando Pathfinding
		moveToPosition(targetHRP.Position)

		-- Atacar se estiver próximo e cooldown expirou
		if dist <= attackRange and tick() - lastAttackTime >= attackCooldown then
			tool:Activate()
			lastAttackTime = tick()
		end

		task.wait(0.05)
	end

	animRun:Stop()
	humanoid:UnequipTools()
end

-- Loop principal
task.spawn(function()
	while true do
		patrol()
		if currentTarget then
			chase()
		end
		task.wait(0.1)
	end
end)
