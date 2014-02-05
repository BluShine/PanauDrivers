-- Panau Runners (server)
-- 0.2.1_beta
-- A delivery gamemode in the style of "Crazy Taxi"
-- BluShine
-- released 1/12/2014
-- updated 1/30/2014

class 'PanauDrivers'

---------------------------config stuff------------------------------------
--chat messages, easy access for translation
local locationHelpText = "give a vehicle type and name: /location H-mhc"
local locationNotInVehicleText = "you must be in a vehicle to set a location"
local jobNotInVehicleText = "can't start a job when you're in a vehicle"
local jobWaitText = "slow down, wait a bit before starting a new job!"
local jobDoesntExistText = "you tried to accept a job that doesn't exist!"
local jobInvalidVehicleText = "job does not have a valid vehicle, something is broken"
local jobAcceptText = "job accepted"
local jobGetCloserText = "get closer to take the job"
local jobRewardText = "job completed! Reward $"
local companyHelpCommandText = "/co help - lists company commands"
local companyInfoText = "you are in company: "
local companyHelpText1 = "/co create companyname - creates a company"
local companyHelpText2 = "/co join companyname - join a company"
local companyHelpText3 = "/co players - lists players in your company"
local companyHelpText4 = "/co leave - leave your company"
local companyHelpText5 = "/co kick playerID - kick a player (press f6 for IDs)"
local companyHelpText6 = "/co say - send a message only to people in your company"
local companyNoNameText = "you need a name for your company"
local companyAlreadyExistsText = "this company already exists"
local companyCreateInJobText = "can't create a company if you're on a job"
local companyCreateText = "created your company, "
local companyLeaveNilText = "you can't leave a company, you're not in one!"
local companyLeaveText = "you left the company"
local companyDisbandText = "you were the last employee, the company was disbanded"
local companyJoinNilText = "type \"/co join companyname\" where companyname is the company to join"
local companyJoinDoesntExistText = "the company you're trying to join doesn't exist"
local companyRequestToJoinText = "you have requested to join the company"
local companyRequestAgainText = "your request is still waiting for approval"
local companyRequestAlreadyInText = "you're already in the company!"
local companyJoinRequestText = " has requested to join your company. /co y or /co n"
local companyNotBossText = "you can't do that, you aren't the boss"
local companyNotInText = "you can't do that, you aren't in a company"
local companyNoRequestsText = "no players in the company request queue"
local companyAcceptPlayerText = " has joined the company"
local companyDenyPlayerText = " has been denied from your company"
local companyInvalidArgText = "invalid command"
local companyKickPlayerText = " has been kicked from the company"
local companyPlayerDoesntExist = "that player does not exist"
local jobTakeNotBossText = "you can't take a job if you're not the company boss"
local companyDeniedText = "you have been denied from the company"
local companyAlreadyOnJobText = "players in your company are still on a job"
local compJobAcceptText = "company job accepted, please move away to let other employees spawn"
local compFinishJobText = "company job finished, bonus: $"
local companyJoinInAnotherText = "can't join a company, you're already in one!"
local companyJoinOnJob = "can't join a company, you're on a job!"

--"/co join <name>" to join a company
	--"/co leave" to leave
	--"/co kick <ID>" to kick a player
	--"/co boss <ID>" to make someone else the boss
	--"/co leave" to leave company

--vehicle type tables
--not included in a table: dlc vehicles, tractor
local groundVehicles = {66, 12, 54, 23, 33, 68, 78, 8, 35, 44, 2, 7, 29, 70, 55, 15, 91, 21, 83, 32, 79, 22, 9, 4, 41, 49, 71, 42, 76, 31}
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
local medium = 1.33
local hard = 1.66
local harder = 2
--number of jobs it will generate before choosing the shortest one
--WARNING: the higher you set this, the longer job generation will take. 
--Large values could create lag when generating new jobs.
--Also, if you set this really high, you might start getting lots of similar jobs.
local shortJobBias = 2
--distance multiplier for rewards
local rewardMultiplier = 0.2
--bonus multiplier per player completing a company job, default is 10%
local companyBonusMultiplier = 0.1
--cooldown time for jobs, don't set this too low or players could spam jobs and lag the server
--default: 15 (seconds), recommended minimum: 5
local jobCooldownTime = 15

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
	--table of companies
	--each company .employees (table of player ids), .boss (ID of boss), .job, .jobStatus (table of .player (ID), .status "waiting" "driving" "finished" "cancelled")
	self.companies = {}
	--table, key=playerId value=company name
	self.playerComps = {}
	
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
		local job = self:MakeJob(key)
		--search for shorter jobs
		for i = 1,shortJobBias do
			job2 = self:MakeJob(key)
			if job2.distance < job.distance and job2.distance > 100 then
				job = job2
			end
		end
		self.availableJobs[key] = job
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
	job.distance = distance
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

function PanauDrivers:getComp(str)
	for k,v in ipairs(self.companies) do
		if v.name == str then
			return k
		end
	end
	return false
end

function PanauDrivers:compByPId(id)
	return self.companies[self:getComp(self.playerComps[id])]
end

--events-----------------

function PanauDrivers:OnPlayerChat(args)

	--/l outputs a location to locationlog.txt. You can paste it into locations.txt to use it in the game
	--adding location requires a name and a type (G/O/W/H/P/J ground/offroad/water/heli/plane/jet)
	--not reccomended for public servers, you might want to limit this to admins somehow
	--example: "/l J-Panau International Airport"
	--[[
	if string.starts(args.text, "/l") and string.len(args.text) <= 5 or string == "/l help" then
		args.player:SendChatMessage(locationHelpText, Color(255,0,0))
		return false
	elseif string.starts(args.text,"/l ") then
		--subtract the /l
		local locname = string.gsub(args.text, "/l ", "\nL:")
		--open the text file in append mode
		local locationlog=io.open("locationlog.txt","a+")
		local pVehicle = args.player:GetVehicle()
		if pVehicle == nil then
			args.player:SendChatMessage(locationNotInVehicleText, Color(255,0,0))
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
	
	--companies let a group of people work together on jobs.
	--"/co" or "/company"
	--"/co create <name>" to create a company
	--"/co join <name>" to join a company
	--"/co leave" to leave
	--"/co kick <ID>" to kick a player
	--"/co boss <ID>" to make someone else the boss
	
	--each company .name .employees (table of player ids), .requests (player ids of players who want to join), .boss (ID of boss), .job, .jobStatus (table of .player (ID), .status "waiting" "driving" "finished" "cancelled")
	
	if string.starts(args.text, "/co") then
		local inputSlices = string.Split( args.text )
		if #inputSlices == 1 then
			if self.playerComps[args.player:GetId()] != nil then
				args.player:SendChatMessage( companyInfoText .. self.playerComps[args.player:GetId()] , Color(255,255,0))
			end
			args.player:SendChatMessage( companyHelpCommandText , Color(255,255,0))
			return false
		end
		
		if inputSlices[2] == "help" then
			args.player:SendChatMessage( companyHelpText1 , Color(255,255,0))
			args.player:SendChatMessage( companyHelpText2 , Color(255,255,0))
			args.player:SendChatMessage( companyHelpText3 , Color(255,255,0))
			args.player:SendChatMessage( companyHelpText4 , Color(255,255,0))
			args.player:SendChatMessage( companyHelpText5 , Color(255,255,0))
			args.player:SendChatMessage( companyHelpText6 , Color(255,255,0))
			return false
		end
		
		if inputSlices[2] == "create" then
			if inputSlices[3] == nil then
				args.player:SendChatMessage( companyNoNameText , Color(255,0,0))
				return false
			end
			if self:getComp(inputSlices[3]) != false then
				args.player:SendChatMessage( companyAlreadyExistsText , Color(255,0,0))
				return false
			end
			if self.playerComps[args.player:GetId()] != nil then
				args.player:SendChatMessage( companyJoinInAnotherText, Color(255,0,0))
				return false
			end
			if self.playerJobs[args.player:GetId()] != nil then
				args.player:SendChatMessage( companyCreateInJobText , Color(255,0,0))
				return false
			end
			
			local comp = {}
			comp.name = inputSlices[3]
			comp.employees = {}
			comp.employees[1] = args.player:GetId()
			comp.requests = {}
			comp.boss = args.player:GetId()
			comp.job = nil
			comp.employeesWaitJobs = {}
			comp.employeesOnJobs = {}
			comp.employeesDoneJobs = {}
			
			self.playerComps[args.player:GetId()] = comp.name
			table.insert(self.companies, comp)
			args.player:SendChatMessage( companyCreateText .. comp.name, Color(0,255,0))
			return false
		end
		
		if inputSlices[2] == "leave" then
			if self.playerComps[args.player:GetId()] == nil then
				args.player:SendChatMessage( companyLeaveNilText, Color(255,0,0))
				return false
			end
			--[[
			comp = self:compByPId(args.player:GetId())
			for k, v in ipairs(comp.employees) do
				if v == args.player:GetId() then
					table.remove( comp.employees, k )
				end
			end
			
			--delete company if there's no employees left.
			--else if the boss left, pass on leadership
			if #comp.employees == 0 then
				table.remove(self.companies, self:getComp(self.playerComps[args.player:GetId()]))
			elseif comp.boss == args.player:GetId() then
				comp.boss = comp.employees[1]
			end
			
			self.playerComps[args.player:GetId()] = nil]]
			
			self:RemovePlayerFromCompany( args.player:GetId())
			
			args.player:SendChatMessage( companyLeaveText, Color(0,255,0))
			
			return false
		end
		
		if inputSlices[2] == "join" then
			if self.playerComps[args.player:GetId()] != nil then
				args.player:SendChatMessage( companyJoinInAnotherText, Color(255,0,0))
				return false
			end
			if self.playerJobs[args.player:GetId()] != nil then
				args.player:SendChatMessage( companyJoinOnJob, Color(255,0,0))
				return false
			end
			if inputSlices[3] == nil then
				args.player:SendChatMessage( companyJoinNilText, Color(255,0,0))
				return false
			end
			if self:getComp(inputSlices[3]) == false then
				args.player:SendChatMessage( companyJoinDoesntExistText, Color(255,0,0))
				return false
			end

			comp = self.companies[self:getComp(inputSlices[3])]
			
			for k, v in ipairs(comp.requests) do
				if v == args.player:GetId() then
					args.player:SendChatMessage( companyRequestAgainText, Color(255,0,0))
					return false
				end
			end
			
			for k, v in ipairs(comp.employees) do
				if v == args.player:GetId() then
					args.player:SendChatMessage( companyRequestAlreadyInText, Color(255,0,0))
					return false
				end
			end
			
			table.insert( comp.requests, args.player:GetId() )
			Player.GetById( comp.boss ):SendChatMessage( args.player:GetName() .. companyJoinRequestText, Color(0, 255, 255))
			args.player:SendChatMessage( companyRequestToJoinText, Color(0,255,0))
			return false
		end
		
		if inputSlices[2] == "y" then
			comp = self:compByPId(args.player:GetId())
			if comp == nil then return false end
			if comp.boss != args.player:GetId() then
				args.player:SendChatMessage( companyNotBossText, Color(255,0,0))
				return false
			end
			if #comp.requests == 0 then
				args.player:SendChatMessage( companyNoRequestsText, Color(255,0,0))
				return false
			end
			
			local p = comp.requests[1]
			comp.employees[#comp.employees + 1] = p
			self.playerComps[p] = comp.name
			table.remove(comp.requests, 1)
			
			self:CompanyBroadcast( comp, Player.GetById(p):GetName() .. companyAcceptPlayerText, Color(0,255,255) )
			return false
		end
		
		if inputSlices[2] == "n" then
			comp = self:compByPId(args.player:GetId())
			if comp == nil then return false end
			if comp.boss != args.player:GetId() then
				args.player:SendChatMessage( companyNotBossText, Color(255,0,0))
				return false
			end
			if #comp.requests == 0 then
				args.player:SendChatMessage( companyNoRequestsText, Color(255,0,0))
				return false
			end
			
			local p = comp.requests[1]
			table.remove(comp.requests, 1)
			args.player:SendChatMessage(Player.GetById(p):GetName() .. companyDenyPlayerText, Color(0,255,0))
			Player.GetById(p):SendChatMessage( companyDeniedText, Color(0, 255, 255))
			return false
		end
		
		if inputSlices[2] == "players" then
			comp = self:compByPId(args.player:GetId())
			if comp == nil then 
				args.player:SendChatMessage(companyNotInText, Color(255,0,0))
				return false 
			end
			local playerList = "players:"
			for k, v in ipairs(comp.employees) do
				playerList = playerList .. " " .. Player.GetById(v):GetName()
			end
			args.player:SendChatMessage(playerList, Color(255,255,0))
			
			return false
		end
		
		if inputSlices[2] == "kick" then
			comp = self:compByPId(args.player:GetId())
			if comp == nil then 
				args.player:SendChatMessage(companyNotInText, Color(255,0,0))
				return false 
			end
			if comp.boss != args.player:GetId() then
				args.player:SendChatMessage( companyNotBossText, Color(255,0,0))
				return false
			end
			if inputSlices[3] == nil then
				args.player:SendChatMessage( companyInvalidArgText, Color(255,0,0)) 
				return false
			end
			if tonumber(inputSlices[3]) == nil then
				args.player:SendChatMessage( companyInvalidArgText, Color(255,0,0)) 
				return false
			end
			if math.floor(tonumber(inputSlices[3])) != tonumber(inputSlices[3]) or 
				tonumber(inputSlices[3]) < 0 then
				args.player:SendChatMessage( companyInvalidArgText, Color(255,0,0)) 
				return false
			end
			if Player.GetById(tonumber(inputSlices[3])) == nil then
				args.player:SendChatMessage( companyPlayerDoesntExist, Color(255,0,0))
				return false
			end
			
			local p = tonumber(inputSlices[3])
			
			--tell everyone about kicking the player
			self:CompanyBroadcast( comp, Player.GetById(p):GetName() .. companyKickPlayerText, Color(0,255,255))
			
			--[[
			--kick the player
			comp = self:compByPId(args.player:GetId())
			for k, v in ipairs(comp.employees) do
				if v == p then
					table.remove( comp.employees, k )
				end
			end
			
			--delete company if there's no employees left.
			--else if the boss left, pass on leadership
			if #comp.employees == 0 then
				--args.player:SendChatMessage( companyDisbandText, Color(0,255,0))
				for k, v in ipairs( self.companies ) do
					if v.name == comp.name then
						table.remove( self.companies, k)
						args.player:SendChatMessage( companyDisbandText .. " " .. k, Color(0,255,0))
					end
				end
			elseif comp.boss == args.player:GetId() then
				comp.boss = comp.employees[1]
			end
			
			self.playerComps[p] = nil]]
			
			self:RemovePlayerFromCompany(p)
			
			return false
		end
		
		if inputSlices[2] == "say" then
			comp = self:compByPId(args.player:GetId())
			if comp == nil then 
				args.player:SendChatMessage(companyNotInText, Color(255,0,0))
				return false 
			end
			--comment this out if you only want the boss to be able to use /say
			--[[
			if comp.boss != args.player:GetId() then
				args.player:SendChatMessage( companyNotBossText, Color(255,0,0))
				return false
			end]]--
			if inputSlices[3] == nil then
				args.player:SendChatMessage( companyInvalidArgText, Color(255,0,0)) 
				return false
			end
			
			saytext = string.gsub(args.text, "/co say", "")
			saytext = string.gsub(saytext, "/company say", "")
			saytext = "[" .. comp.name .. "]" .. Player.GetName(args.player) .. ": " .. saytext
			
			self:CompanyBroadcast( comp, saytext, Color(255, 255, 0))
			
			return false
		end
		
		
		
		
	end
end

--simple function to split up a string where there are spaces
function string.Split( str )
	tab = {}
	for s in str:gmatch("%S+") do 
		table.insert(tab,s)
	end
	return tab
end



--send message with color to everyone in company
function PanauDrivers:CompanyBroadcast( comp, message, color )
	--local comp = self.companies[company]
	for k, v in ipairs(comp.employees) do
		Player.GetById(v):SendChatMessage( message, color )
	end
end

function PanauDrivers:RemovePlayerFromCompany( playerId )
	comp = self.companies[self:getComp(self.playerComps[playerId])]
	player = Player.GetById( playerId )
	
	self.playerJobs[playerId] = nil
	
	--remove from company tables
	for k, v in ipairs(comp.employees) do
		if v == playerId then
			table.remove( comp.employees, k )
		end
	end
	
	--cancel any job and remove vehicles
	if comp.job != nil then
		for k, v in ipairs(comp.employeesOnJobs) do
			if v == playerId then
				table.remove(comp.employeesOnJobs, k)
				comp.vehicles[playerId]:Remove()
			end
		end
		for k, v in ipairs(comp.employeesWaitJobs) do
			if v == playerId then
				table.remove(comp.employeesWaitJobs, k)
			end
		end
		for k, v in ipairs(comp.employeesDoneJobs) do
			if v == playerId then
				table.remove(comp.employeesDoneJobs, k)
			end
		end
		
		if player != nil then
			Network:Send( player, "JobCancel", true )
		end
	end
	
	--delete company if there's no employees left.
	--else if the boss left, pass on leadership
	if #comp.employees == 0 then
		table.remove(self.companies, self:getComp(self.playerComps[playerId]))
	elseif comp.boss == playerId then
		comp.boss = comp.employees[1]
	end
	
	--remove from player company
	self.playerComps[playerId] = nil
	
end

function PanauDrivers:PreTick( args )

	if self.jobCancelTimer:GetSeconds() > 1 then
		self.jobCancelTimer:Restart()
		--cancel jobs in queue
		for player in Server:GetPlayers() do
			pId = player:GetId()
			if self.jobsToCancel[pId] == true then
				self.playerJobTimers[pId]:Restart()
				if self.playerJobs[pId] != nil then
					if self.playerComps[pId] == nil then
						self.playerJobs[pId].vehiclePointer:Remove()
					end
					self.playerJobs[pId] = nil
				end
				Network:Send( player, "JobCancel", true )
				self.jobsToCancel[pId] = false
				
				--if player was in a company, remove them frome the company job list
				if self.playerComps[pId] != nil then
					comp = self.companies[self:getComp(self.playerComps[pId])]
					for k, v in ipairs(comp.employeesOnJobs) do
						if v == pId then
							table.remove(comp.employeesOnJobs, k)
							comp.vehicles[pId]:Remove()
						end
					end
				end
			end
		end
		
		--process company jobs
		for k, comp in ipairs(self.companies) do
			if comp.job != nil then
				if #comp.employeesOnJobs == 0 and #comp.employeesWaitJobs == 0 then
					--remove company job and distribute bonuses if everyone is done
					comp.job.bonus = math.floor((comp.job.bonus - 1) * companyBonusMultiplier * comp.job.reward)
					if comp.job.bonus < 0 then comp.job.bonus = 0 end
					self:CompanyBroadcast( comp, compFinishJobText .. tostring(comp.job.bonus), Color(0, 255, 0) )
					for k, p in ipairs(comp.employeesDoneJobs) do
						Player.GetById(p):SetMoney(Player.GetById(p):GetMoney() + comp.job.bonus)
					end
					comp.job = nil
					
				elseif #comp.employeesOnJobs == 0 then
					--start the first employee's job
					playerToStart = comp.employeesWaitJobs[1]
					table.insert(comp.employeesOnJobs, playerToStart)
					table.remove(comp.employeesWaitJobs, 1)
					
					actualPlayer = Player.GetById(playerToStart)
					--spawn vehicle
					local vArgs = {}
					vArgs.model_id = comp.job.vehicle
					--if it's the H-62 Quapaw, spawn it a bit higher up or else it'll sometimes randomly explode
					if vArgs.model_id == 65 then
						vArgs.position = self.locations[comp.job.start].position + Vector3(0, 2.5, 0)
					else
						vArgs.position = self.locations[comp.job.start].position
					end
					vArgs.angle = self.locations[comp.job.start].angle
					vArgs.enabled = true
					vArgs.world = actualPlayer:GetWorld()
					vArgs.tone1 = Color(255, 225, 0)
					vArgs.tone2 = Color(255, 238, 0)
					local veh = Vehicle.Create( vArgs )
					veh:SetUnoccupiedRemove(true)
					veh:SetDeathRemove(true)
					veh:SetUnoccupiedRespawnTime(nil)
					veh:SetDeathRespawnTime(nil)
					actualPlayer:EnterVehicle( veh, VehicleSeat.Driver )
					comp.vehicles[playerToStart] = veh
					--tell the player that they got the job!
					Network:Send( actualPlayer, "JobStart", comp.job)
					actualPlayer:SendChatMessage( compJobAcceptText , Color( 0, 255, 0 ) )
					--put job in table
					self.playerJobs[actualPlayer:GetId()] = comp.job
					--generate a new job for that location, and tell the clients about it
					self.availableJobs[comp.job.start] = self:MakeJob( comp.job.start )
					jUpdate = {comp.job.start, self.availableJobs[comp.job.start]}
					Network:Broadcast("JobsUpdate", jUpdate)
				elseif #comp.employeesWaitJobs != 0 then
					--start more employees on the job
					--check if most recent player is far enough from the start
					lastPlayer = Player.GetById(comp.employeesOnJobs[1])
					distFromStart = Vector3.Distance(Player.GetPosition(lastPlayer), self.locations[comp.job.start].position)
					if distFromStart > 30 then
						
						playerToStart = comp.employeesWaitJobs[1]
						table.insert(comp.employeesOnJobs, playerToStart)
						table.remove(comp.employeesWaitJobs, 1)
						
						actualPlayer = Player.GetById(playerToStart)
						Player.SetPosition(actualPlayer, self.locations[comp.job.start].position)
						--spawn vehicle
						local vArgs = {}
						vArgs.model_id = comp.job.vehicle
						--if it's the H-62 Quapaw, spawn it a bit higher up or else it'll sometimes randomly explode
						if vArgs.model_id == 65 then
							vArgs.position = self.locations[comp.job.start].position + Vector3(0, 2.5, 0)
						else
							vArgs.position = self.locations[comp.job.start].position
						end
						vArgs.angle = self.locations[comp.job.start].angle
						vArgs.enabled = true
						vArgs.world = actualPlayer:GetWorld()
						vArgs.tone1 = Color(255, 225, 0)
						vArgs.tone2 = Color(255, 238, 0)
						local veh = Vehicle.Create( vArgs )
						veh:SetUnoccupiedRemove(true)
						veh:SetDeathRemove(true)
						veh:SetUnoccupiedRespawnTime(nil)
						veh:SetDeathRespawnTime(nil)
						actualPlayer:EnterVehicle( veh, VehicleSeat.Driver )
						comp.vehicles[playerToStart] = veh
						--tell the player that they got the job!
						Network:Send( actualPlayer, "JobStart", comp.job)
						actualPlayer:SendChatMessage( compJobAcceptText , Color( 0, 255, 0 ) )
						--put job in table
						self.playerJobs[actualPlayer:GetId()] = comp.job						
					end
				end
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
	--check if they're in a vehicle
	if player:GetState() == PlayerState.InVehiclePassenger or player:GetVehicle() != nil then
		player:SendChatMessage( jobNotInVehicleText , Color( 255, 0, 0 ))
        return false
    end
	--cooldown timer
	if self.playerJobTimers[player:GetId()]:GetSeconds() < jobCooldownTime then
		player:SendChatMessage( jobWaitText, Color( 255, 0, 0 ))
		return false
	end
	--make sure the job is valid
	local thatJob = self.availableJobs[args.job]
	if thatJob == nil then
		player:SendChatMessage( jobDoesntExistText , Color( 255, 0, 0 ) )
		return false
	end
	if type(thatJob.vehicle) != "number" then
		player:SendChatMessage( jobInvalidVehicleText , Color( 255, 0, 0 ) )
		return false
	end
	--do special stuff for players in companies
	if self.playerComps[player:GetId()] != nil then
		comp = self.companies[self:getComp(self.playerComps[player:GetId()])]
		if comp != nil then
			if comp.boss != player:GetId() then
				player:SendChatMessage( jobTakeNotBossText, Color( 255, 0, 0))
				return false
			end
			if comp.job != nil then
				player:SendChatMessage( companyAlreadyOnJobText, Color( 255, 0, 0))
				return false
			end
			--start the company job
			comp.job = thatJob
			comp.job.bonus = 0
			--add all current employees to table of employees waiting to start
			for k, v in ipairs( comp.employees ) do
				table.insert( comp.employeesWaitJobs, v)
			end
			comp.employeesOnJobs = {}
			comp.employeesDoneJobs = {}
			comp.vehicles = {}
		
			self:CompanyBroadcast( comp, comp.name .. " started job: " .. thatJob.description, Color( 0, 255, 0))
			return false
		end
	end
	
	local jobDist = self.locations[thatJob.start].position:Distance(player:GetPosition())
	if jobDist < 20 then
		--restart timer
		self.playerJobTimers[player:GetId()]:Restart()
		--spawn vehicle
		local vArgs = {}
		vArgs.model_id = thatJob.vehicle
		--if it's the H-62 Quapaw, spawn it a bit higher up or else it'll sometimes randomly explode
		if vArgs.model_id == 65 then
			vArgs.position = self.locations[thatJob.start].position + Vector3(0, 2.5, 0)
		else
			vArgs.position = self.locations[thatJob.start].position
		end
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
		player:SendChatMessage( jobAcceptText , Color( 0, 255, 0 ) )
		--put job in table
		self.playerJobs[player:GetId()] = thatJob
		--generate a new job for that location, and tell the clients about it
		self.availableJobs[args.job] = self:MakeJob( args.job )
		jUpdate = {args.job, self.availableJobs[args.job]}
		Network:Broadcast("JobsUpdate", jUpdate)
	else
		player:SendChatMessage( jobGetCloserText , Color( 255, 0, 0 ) )
	end
end

function PanauDrivers:PlayerCompleteJob( args, player )
	local thatJob = self.playerJobs[player:GetId()]
	if thatJob == nil then
		print("player tried to complete a nil job, something went horribly wrong")
		return
	end
	local destDist = self.locations[thatJob.destination].position:Distance(player:GetPosition())
	local pVehicle = player:GetVehicle()
	if pVehicle == nil then
		return
	end
	local vVel = pVehicle:GetLinearVelocity():Length()
	stopped = false
	if vVel < 1 then
		stopped = true
	end
	
	playerId = player:GetId()
	
	--if player is in a company
	if destDist < 20 and self.playerComps[playerId] != nil and 
		pVehicle == comp.vehicles[playerId] and stopped then
		
		player:GetVehicle():Remove()
		local reward = thatJob.reward
		player:SetMoney(player:GetMoney() + reward)
		self.playerJobs[playerId] = nil
		Network:Send( player, "JobFinish", reward)
		player:SendChatMessage( jobRewardText .. reward, Color( 0, 255, 0 ) )
		self.playerJobTimers[playerId]:Restart()
		comp = self.companies[self:getComp(self.playerComps[playerId])]
		table.insert(comp.employeesDoneJobs, playerId)
		for k, v in ipairs(comp.employeesOnJobs) do
			if v == playerId then
				table.remove(comp.employeesOnJobs, k)
			end
		end
		comp.job.bonus = comp.job.bonus + 1
		
	end
	
	--if player isn't in a company
	if destDist < 20 and self.playerComps[playerId] == nil and pVehicle == thatJob.vehiclePointer and stopped then
		
		player:GetVehicle():Remove()
		local reward = thatJob.reward
		player:SetMoney(player:GetMoney() + reward)
		self.playerJobs[playerId] = nil
		Network:Send( player, "JobFinish", reward)
		player:SendChatMessage( jobRewardText .. reward, Color( 0, 255, 0 ) )
		self.playerJobTimers[playerId]:Restart()
	end
	
end

function PanauDrivers:ClientModuleLoad( args )
	--send the locations table and jobs table to players
    Network:Send( args.player, "Locations", self.locations )
	Network:Send( args.player, "Jobs", self.availableJobs)
	self.playerJobTimers[args.player:GetId()] = Timer()
end

function PanauDrivers:PlayerQuit( args )
	pId = args.player:GetId()
	self.playerJobs[pId] = nil
	if self.playerComps[pId] != nil then
		self:RemovePlayerFromCompany(pId)
	end
end

PanauDrivers = PanauDrivers()