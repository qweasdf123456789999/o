local Player = game:GetService("Players")
local allPlayers = Player:GetPlayers()
local LocalPlayer = Player.LocalPlayer

local function Raycast(pos1, pos2, range)
	local raycastparams = RaycastParams.new()
	raycastparams.FilterDescendantsInstances = {LocalPlayer.Character}
	raycastparams.FilterType = Enum.RaycastFilterType.Exclude

	local dir = (pos2 - pos1).Unit * range

	local rayresult = workspace:Raycast(pos1, dir, raycastparams)

	if rayresult then
		return rayresult.Instance, rayresult.Position
	else
		return nil, nil
	end
end

local function findmixtarget()
	local target = nil
	local mixrange = math.huge
	for _,plr in pairs(game.Players:GetPlayers()) do
		if plr.Team and plr.Team ~= LocalPlayer.Team then
			if plr.Character then
				local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp then 
					if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
						local Playerhrppos = hrp.Position
						local LocalPlayerhrppos = LocalPlayer.Character.HumanoidRootPart.Position
						local range = (Playerhrppos - LocalPlayerhrppos).Magnitude
						if range < mixrange then
							mixrange = range
							target = plr
						end
					end
				end
			end
		end
	end
	return target
end

local function FindGun()
	local Gun
	local Char = LocalPlayer.Character
	if Char then
		local Tool = Char:FindFirstChildOfClass("Tool")
		if Tool then
			local Attri = Tool:GetAttributes()
			if Attri.ToolType == "Gun" then
				Gun = Tool
			end
		end
	end
	return Gun
end

local function AutoReload(Gun)
	local reloadSession = Gun:GetAttribute("Local_ReloadSession")
	if reloadSession and reloadSession > 0 then
		return
	end
	local ReloadTime = Gun:GetAttribute("ReloadTime")
	Gun:SetAttribute("Local_ReloadSession", tick())
	local FuncReload = game:GetService("ReplicatedStorage"):WaitForChild("GunRemotes"):WaitForChild("FuncReload")
	local success = pcall(function()
		FuncReload:InvokeServer()
	end)
	if not success then
		pcall(function()
			FuncReload:FireServer()
		end)
	end
	
	task.wait(ReloadTime)
	
	Gun:SetAttribute("Local_ReloadSession", 0)
end

task.spawn(function()
	while LocalPlayer.Character do
		local Gun = FindGun()
		if Gun then
			local Attri = Gun:GetAttributes()
			local ammo = Attri.CurrentAmmo or Attri.Local_CurrentAmmo or Attri.LocalCurrentAmmo or 0
			if ammo <= 0 then
				AutoReload(Gun)
				task.wait(0.5)
				continue
			end
			local Range = Gun:GetAttribute("AccurateRange")
			if Range then
				local target = findmixtarget()
				if target and target.Character then
					local targetpos = target.Character.HumanoidRootPart.Position
					if Gun.Handle then
						local gunpos = Gun.Handle.AssemblyCenterOfMass
						local hitInstance, hitPosition = Raycast(gunpos, targetpos, Range)
						local finalPosition = hitPosition or targetpos
						local finalInstance = hitInstance or target.Character.HumanoidRootPart
						local Event = game:GetService("ReplicatedStorage"):WaitForChild("GunRemotes"):WaitForChild("ShootEvent")
						Event:FireServer({{
							LocalPlayer.Character.Head.Position,
							finalPosition,
							finalInstance
						}})
					end
				end
			end
		end

		task.wait()
	end
end)
