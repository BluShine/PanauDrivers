-- Panau Runners (server)
-- 0.1.0
-- A delivery gamemode in the style of "Crazy Taxi"
-- BluShine
-- released 1/12/2014
-- updated 1/12/2014

class 'PanauDrivers'

---------------------------config stuff------------------------------------
--chat messages, easy access for translation
local locationHelp = "give a vehicle type and name: /location H-mhc"
local locationNotInVehicle = "you must be in a vehicle to set a location"
local giveHelp = "type '/give 0 1' where 0 is a player ID and 1 is the $ amount. Use f6 to find player IDs"
--vehicle type tables
--not included in a table: dlc vehicles, tractor
local groundVehicles = {66, 12, 54, 23, 33, 68, 78, 8, 35, 44, 2, 7, 29, 70, 55, 15, 91, 21, 83, 32, 79, 22, 9, 22, 9, 4, 41, 49, 71, 42, 76, 31}
local offroadVehicles = {11, 36, 72, 73, 26, 63, 86, 77, 48, 84, 46, 10, 52, 13, 60, 87, 74, 43, 89, 90, 61, 47, 18, 56, 40}
local waterVehicles = {80, 38, 88, 45, 6, 19, 5, 27, 28, 25, 69, 16, 50}
local heliVehicles = {64, 65, 14, 67, 3, 37, 57, 62}
local jetVehicles = {39, 85, 34}
local planeVehicles = {51, 59, 81, 30}
--vehicle "difficulty" tables
local easyVehicles = {81, 64, 14, 67, 3, 37, 57, 62, 80, 88, 27, 54, 72, 73, 23, 33, 63, 26, 68, 78, 86, 35, 77, 2, 84, 46, 7, 10, 52, 29, 70, 55, 15, 13, 91, 60, 87, 74, 21, 43, 89, 90, 61, 18, 56, 76, 31}
local mediumVehicles = {51, 34, 30, 65, 45, 6, 19, 28, 69, 16, 11, 36, 44, 48, 83, 32, 47, 79, 22, 9, 4, 41, 49, 71, 42}
local hardVehicles = {59, 38, 5, 25, 66, 12, 8, 1, 40}
local harderVehicles = {39, 75, 85, 50}
--"difficulty" multipliers
local easy = 1
local medium = 1.2
local hard = 1.4
local harder = 1.6
--distance multiplier for rewards
local rewardMultiplier = 0.05

----------------------------utility functions------------------------
--simple function to check if a string starts with a string
function string.starts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end

--simple function to get the start of a string up to (excluding) the end string
--for example, string.upto("monkey", "e") => "monk"
function string.upto(String,End)
	return string.sub(String, 1, string.find(String,End) - 1)
end

---------------------init-----------------------
function PanauDrivers:__init()
	math.randomseed(os.time())
	--variables
	--table of locations, value has .name(string) .type(string) .position(vector3) .angle(vector3)
	self.locations = {}
	--tables for each type of location, numbers that are keys for the location table
	self.gLocs = {}
	self.oLocs = {}
	self.wLocs = {}
	self.hLocs = {}
	self.jLocs = {}
	self.pLocs = {}
	--table that stores a job for each location, value has .start, .destination(num index in locations), .reward(num), .vehicle(num ID), .direction(vector3)
	self.availableJobs = {}
	--table indexed by playerIDs (contains all players)
	--value is either nil or has .start(num index in locations) .destination, .vehicle(vehicle), .reward(num)
	self.playerJobs = {}
	--table of timers for player job cooldowns
	self.playerJobTimers = {}
	--timer and table for cancelling jobs
	self.jobCancelTimer = Timer()
	self.jobsToCancel = {}
	
	--load vehicles locations
	self:LoadLocations( "locations.txt" )
	
	--generates jobs for each location
	self:GenerateJobs()
	
	--events
	Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad )
	Events:Subscribe("PlayerQuit", self, self.PlayerQuit )
	Events:Subscribe("PlayerChat", self, self.OnPlayerChat)
	Events:Subscribe("PlayerExitVehicle", self, self.OnPlayerExitV )
	Events:Subscribe("PlayerDeath", self, self.OnPlayerDeath )
	Events:Subscribe("PreTick", self, self.PreTick)
	Network:Subscribe("TakeJob", self, self.PlayerTakeJob)
	Network:Subscribe("CompleteJob", self, self.PlayerCompleteJob)
end

function PanauDrivers:LoadLocations( filename )
	--open file
	print("now opening " .. filename)
	local file = io.open( filename, "r" )
	if file == nil then
		print(filename .. " is missing, can't load spawns")
		return
	end
	--process lines
	for line in file:lines() do 
		if line:sub(1,1) == "L" then
			self:ParseVehicleLocation(line:sub(3))
		end
	end
	file:close()
	
	for key,location in pairs(self.locations) do
		if location.type == "G" then
			table.insert(self.gLocs, key)
		elseif location.type == "O" then
			table.insert(self.oLocs, key)
		elseif location.type == "W" then
			table.insert(self.wLocs, key)
		elseif location.type == "H" then
			table.insert(self.hLocs, key)
		elseif location.type == "J" then
			table.insert(self.jLocs, key)
		elseif location.type == "P" then
			table.insert(self.pLocs, key)
		end
	end
end

function PanauDrivers:ParseVehicleLocation( line )
	--get the type
	local vehicleType = string.sub(line, 1, 1)
	--divide up using the ","s
	local tokens = line:split(",")
	
	local locName = tokens[1]
	
	local locPos = { tokens[2]:gsub(" ",""), tokens[3]:gsub(" ",""), tokens[4]:gsub(" ","")}
	local locAngle = {tokens[5]:gsub(" ",""), tokens[6]:gsub(" ",""), tokens[7]:gsub(" ","")}
	
	local locArgs = {}
	locArgs.name = locName
	locArgs.type = vehicleType
	locArgs.position = Vector3(tonumber(locPos[1]),tonumber(locPos[2]),tonumber(locPos[3]))
	locArgs.angle = Angle(tonumber(locAngle[1]),tonumber(locAngle[2]),tonumber(locAngle[3]))
	
	table.insert(self.locations, locArgs)
	--self.locations[locName] = vehicleArgs
	
end

function PanauDrivers:GenerateJobs()
	print("generating jobs")
	for key,location in pairs(self.locations) do
		self.availableJobs[key] = self:MakeJob(key)
	end
end

function PanauDrivers:MakeJob(key)
	local location = self.locations[key]
	local job = {}
	job.start = key
	--set a destination (and make sure it's not the same as the start)
	--watch out, this will go forever if there's not at least 2 of each type of destination.
	local destKey = self:GetRandomDestination(location.type, key)
	job.destination = destKey
	--set a vehicle
	local dest = self.locations[job.destination]
	if dest.type == "O" or location.type == "O" then
		job.vehicle = self:GetRandomVehicleOfType("O")
	else
		job.vehicle = self:GetRandomVehicleOfType(dest.type)
	end
	--set the direction between the start and destination
	local startPoint = location.position
	local destPoint = dest.position
	local direction = startPoint - destPoint
	direction = direction:Normalized()
	job.direction = direction
	--calculate a reward
	local distance = startPoint:Distance(destPoint)
	local multiplier = self:GetVehicleRewardMultiplier(job.vehicle)
	job.reward = math.floor(multiplier * distance * rewardMultiplier)
	job.description = "deliver to " .. dest.name
	return job
end

function PanauDrivers:GetVehicleRewardMultiplier(vehicleType)
	for k,v in pairs(easyVehicles) do
		if v == vehicleType then
			return easy
		end
	end
	for k,v in pairs(mediumVehicles) do
		if v == vehicleType then
			return medium
		end
	end
	for k,v in pairs(hardVehicles) do
		if v == vehicleType then
			return hard
		end
	end
	for k,v in pairs(harderVehicles) do
		if v == vehicleType then
			return harder
		end
	end
	return easy
end

function PanauDrivers:GetRandomVehicleOfType(vehicleType)
	--do the sacred ritual to make math.random numbers actually probably kinda random
	math.randomseed(os.time())
	--sacrifice a few random numbers to the luck gods, pray for them to grant us a truly random number
	math.random()
	math.random()
	math.random()
	if (vehicleType == "G") then
		return groundVehicles[math.random(#groundVehicles)]
	elseif (vehicleType == "O") then
		return offroadVehicles[math.random(#offroadVehicles)]	
	elseif (vehicleType == "W") then
		return waterVehicles[math.random(#waterVehicles)]
	elseif (vehicleType == "H") then
		return heliVehicles[math.random(#heliVehicles)]
	elseif (vehicleType == "J") then
		return jetVehicles[math.random(#jetVehicles)]
	elseif (vehicleType == "P") then
		return planeVehicles[math.random(#planeVehicles)]
	else 
		print("tried to spawn invalid vehicle type. Made tractor instead")
		return 1
	end
end

function PanauDrivers:GetRandomDestination(startType, key)
	--do the sacred ritual to make math.random numbers actually probably kinda random
	math.randomseed(os.time())
	--sacrifice a few random numbers to the luck gods, pray for them to grant us a truly random number
	math.random()
	math.random()
	math.random()
	local i = 1
	local r = 1
	if (startType == "G") or (startType == "O") then
		if math.random(2) == 1 then
			i = math.random(#self.oLocs)
			r = self.oLocs[i]
			if r == key then
				if i < #self.oLocs then
					i = i + 1
					r = self.oLocs[i]
				elseif i > #self.oLocs then
					i = i - 1
					r = self.oLocs[i]
				end
			end
		else
			i = math.random(#self.gLocs)
			r = self.gLocs[i]
			if r == key then
				if i < #self.gLocs then
					i = i + 1
					r = self.gLocs[i]
				elseif i > #self.gLocs then
					i = i - 1
					r = self.gLocs[i]
				end
			end
		end
	elseif (startType == "W") then
		i = math.random(#self.wLocs)
			r = self.wLocs[i]
			if r == key then
				if i < #self.wLocs then
					i = i + 1
					r = self.wLocs[i]
				elseif i > #self.wLocs then
					i = i - 1
					r = self.wLocs[i]
				end
			end
	elseif (startType == "H") then
		i = math.random(#self.hLocs)
			r = self.hLocs[i]
			if r == key then
				if i < #self.hLocs then
					i = i + 1
					r = self.hLocs[i]
				elseif i > #self.hLocs then
					i = i - 1
					r = self.hLocs[i]
				end
			end
	elseif (startType == "J") then
		i = math.random(#self.jLocs)
			r = self.jLocs[i]
			if r == key then
				if i < #self.jLocs then
					i = i + 1
					r = self.jLocs[i]
				elseif i > #self.jLocs then
					i = i - 1
					r = self.jLocs[i]
				end
			end
	elseif (startType == "P") then
		i = math.random(#self.pLocs)
			r = self.pLocs[i]
			if r == key then
				if i < #self.pLocs then
					i = i + 1
					r = self.pLocs[i]
				elseif i > #self.pLocs then
					i = i - 1
					r = self.pLocs[i]
				end
			end
	else
		print("tried to create job with invalid type")
		return locations[1]
	end
	return r
end

--events-----------------

function PanauDrivers:OnPlayerChat(args)

	--/l outputs a location to locationlog.txt. You can paste it into locations.txt to use it in the game
	--adding location requires a name and a type (G/O/W/H/P/J ground/offroad/water/heli/plane/jet)
	--not reccomended for public servers, you might want to limit this to admins somehow
	--example: "/l J-Panau International Airport"
	--[[
	if string.starts(args.text, "/l") and string.len(args.text) <= 5 or string == "/l help" then
		args.player:SendChatMessage(locationHelp, Color(255,0,0))
		return false
	elseif string.starts(args.text,"/l ") then
		--subtract the /l
		local locname = string.gsub(args.text, "/l ", "\nL:")
		--open the text file in append mode
		local locationlog=io.open("locationlog.txt","a+")
		local pVehicle = args.player:GetVehicle()
		if pVehicle == nil then
			args.player:SendChatMessage(locationNotInVehicle, Color(255,0,0))
			return false
		else
			local vPos = pVehicle:GetPosition()
			local vAngle = pVehicle:GetAngle()
			args.player:SendChatMessage(locname..tostring(vPos)..", "..tostring(vAngle), Color(0,255,0))
			--write and close the text file
			locationlog:write(locname..", "..tostring(vPos)..", "..tostring(vAngle))
			locationlog:close()
			return false
		end
		return false
	else
		return true
	end
	--]]--
end

function PanauDrivers:PreTick( args )

	if self.jobCancelTimer:GetSeconds() > 1 then
		self.jobCancelTimer:Restart()
		
		for player in Server:GetPlayers() do
			pId = player:GetId()
			if self.jobsToCancel[pId] == true then
				self.playerJobTimers[pId]:Restart()
				if self.playerJobs[pId] != nil then
					self.playerJobs[pId].vehiclePointer:Remove()
					self.playerJobs[pId] = nil
				end
				Network:Send( player, "JobCancel", true )
				self.jobsToCancel[pId] = false
			end
		end
	end
end

function PanauDrivers:OnPlayerExitV( args )
	self.jobsToCancel[args.player:GetId()] = true
end

function PanauDrivers:OnPlayerDeath( args )
	self.jobsToCancel[args.player:GetId()] = true
end

function PanauDrivers:PlayerTakeJob( args, player )
	if player:GetState() == PlayerState.InVehiclePassenger or player:GetVehicle() != nil then
		player:SendChatMessage("can't start a job when you're in a vehicle", Color( 255, 0, 0 ))
        return false
    end
	
	if self.playerJobTimers[player:GetId()]:GetSeconds() < 15 then
		player:SendChatMessage("slow down, wait a bit before starting a new job!", Color( 255, 0, 0 ))
		return false
	end
	
	local thatJob = self.availableJobs[args.job]
	if thatJob == nil then
		player:SendChatMessage("you tried to accept a job that doesn't exist!", Color( 255, 0, 0 ) )
		return false
	end
	if type(thatJob.vehicle) != "number" then
		player:SendChatMessage("job does not have a valid vehicle, something is broken", Color( 255, 0, 0 ) )
		return false
	end
	local jobDist = self.locations[thatJob.start].position:Distance(player:GetPosition())
	if jobDist < 20 then
		--restart timer
		self.playerJobTimers[player:GetId()]:Restart()
		--spawn vehicle
		local vArgs = {}
		vArgs.model_id = thatJob.vehicle
		vArgs.position = self.locations[thatJob.start].position
		vArgs.angle = self.locations[thatJob.start].angle
		vArgs.enabled = true
		vArgs.world = player:GetWorld()
		vArgs.tone1 = Color(255, 225, 0)
		vArgs.tone2 = Color(255, 238, 0)
		local veh = Vehicle.Create( vArgs )
		veh:SetUnoccupiedRemove(true)
		veh:SetDeathRemove(true)
		veh:SetUnoccupiedRespawnTime(nil)
		veh:SetDeathRespawnTime(nil)
		player:EnterVehicle( veh, VehicleSeat.Driver )
		thatJob.vehiclePointer = veh
		--tell the player that they got the job!
		Network:Send( player, "JobStart", thatJob)
		player:SendChatMessage("job accepted", Color( 0, 255, 0 ) )
		--put job in table
		self.playerJobs[player:GetId()] = thatJob
		--generate a new job for that location, and tell the clients about it
		self.availableJobs[args.job] = self:MakeJob( args.job )
		jUpdate = {args.job, self.availableJobs[args.job]}
		Network:Broadcast("JobsUpdate", jUpdate)
	else
		player:SendChatMessage("get closer to take the job", Color( 255, 0, 0 ) )
	end
end

function PanauDrivers:PlayerCompleteJob( args, player )
	local thatJob = self.playerJobs[player:GetId()]
	if thatJob == nil then
		print("player tried to completely a nil job, something went horribly wrong")
		return
	end
	local destDist = self.locations[thatJob.destination].position:Distance(player:GetPosition())
	local pVehicle = player:GetVehicle()
	if pVehicle == nil then
		return
	end
	local vVel = pVehicle:GetLinearVelocity()
	if vVel.x < 0.1 and vVel.x > -0.1 and vVel.y < 0.1 and vVel.y > -0.1 and vVel.z < 0.1 and vVel.z > -0.1 then
		stopped = true
	end
	if destDist < 20 and pVehicle == thatJob.vehiclePointer and stopped then
		player:GetVehicle():Remove()
		local reward = thatJob.reward
		player:SetMoney(player:GetMoney() + reward)
		self.playerJobs[player:GetId()] = nil
		Network:Send( player, "JobFinish", reward)
		player:SendChatMessage("job completed! Reward $" .. reward, Color( 0, 255, 0 ) )
		self.playerJobTimers[player:GetId()]:Restart()
	end
	
end

function PanauDrivers:ClientModuleLoad( args )
	--send the locations table and jobs table to players
    Network:Send( args.player, "Locations", self.locations )
	Network:Send( args.player, "Jobs", self.availableJobs)
	self.playerJobTimers[args.player:GetId()] = Timer()
end

function PanauDrivers:PlayerQuit( args )
	self.playerJobs[args.player:GetId()] = nil
end

PanauDrivers = PanauDrivers()