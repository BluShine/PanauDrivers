-- Panau Runners (client)
-- 0.1.0
-- A delivery gamemode in the style of "Crazy Taxi"
-- BluShine
-- released 1/12/2014
-- updated 1/12/2014

class 'PanauDrivers'

--shadowed text function taken from freeroam example script
function PanauDrivers:DrawShadowedText( pos, text, colour, size, scale )
    if scale == nil then scale = 1.0 end
    if size == nil then size = TextSize.Default end

    local shadow_colour = Color( 0, 0, 0, colour.a )
    shadow_colour = shadow_colour * 0.4

    Render:DrawText( pos + Vector3( 1, 1, 0 ), text, shadow_colour, size, scale )
    Render:DrawText( pos, text, colour, size, scale )
end

--init---------------------------------
function PanauDrivers:__init()
	--variables
	self.locations = {}
	self.availableJob = nil
	availableJobKey = 0
	self.job = nil
	self.jobUpdateTimer = Timer()
	self.jobCompleteTimer = Timer()
	--self.jobOpen = false
	
	--GUI
	self.window = Window.Create()
	self.window:SetSize( Vector2( 300, 110 ))
	self.window:SetPositionRel( Vector2( 0.5, 0.8 ) - self.window:GetSizeRel()/2 )
	self.window:SetTitle("Panau Runners Job")
	self.window:SetVisible( false )
	
	self.windowL1 = Label.Create(self.window, "job description")
	self.windowL2 = Label.Create(self.window, "job money")
	self.windowL3 = Label.Create(self.window, "job vehicle")
	self.windowButton = Button.Create(self.window, "job start")
	
	self.windowL1:SetText( "deliver some stuff to a place" )
	self.windowL1:SetSize( Vector2(290, 30))
	self.windowL1:SetPosition( Vector2(0, 50))
	self.windowL2:SetText( "$1337" )
	self.windowL2:SetSize( Vector2(290, 16))
	self.windowL2:SetPosition( Vector2(0, 18))
	self.windowL3:SetText( "Dongtai Agriboss 35" )
	self.windowL3:SetSize( Vector2(290, 16))
	self.windowL3:SetPosition( Vector2(0, 34))
	self.windowButton:SetText( "PRESS J TO START" )
	self.windowButton:SetSize( Vector2(290, 16))
	
	
	--events
	Network:Subscribe( "Locations", self, self.Locations )
	Network:Subscribe( "Jobs", self, self.Jobs)
	Network:Subscribe( "JobStart", self, self.JobStart)
	Network:Subscribe( "JobFinish", self, self.JobFinish)
	Network:Subscribe( "JobsUpdate", self, self.JobsUpdate)
	Network:Subscribe( "JobCancel", self, self.JobCancel)
	Events:Subscribe( "Render", self, self.Render)
	Events:Subscribe( "KeyDown", self, self.KeyDown)
	Events:Subscribe( "PreTick", self, self.PreTick)
end

function PanauDrivers:Locations( args )
	self.locations = args
end

function PanauDrivers:Jobs( args )
	self.jobsTable = args
end

function PanauDrivers:JobsUpdate( args )
	self.jobsTable[args[1]] = args[2]
end

function PanauDrivers:JobStart( args )
	self.job = args
	Waypoint:SetPosition(self.locations[self.job.destination].position)
end

function PanauDrivers:JobFinish( args )
	self.job = nil
	Waypoint:Remove()
end

function PanauDrivers:JobCancel( args )
	self.job = nil
	Waypoint:Remove()
end

function PanauDrivers:PreTick( args )
	if self.jobCompleteTimer:GetSeconds() > 1 and self.job != nil and LocalPlayer:GetVehicle() != nil then
		self.jobCompleteTimer:Restart()
		pVehicle = LocalPlayer:GetVehicle()
		jDist = self.locations[self.job.destination].position:Distance( pVehicle:GetPosition() )
		if jDist < 20 then
			Network:Send( "CompleteJob", nil )
		end
	end
end

function PanauDrivers:KeyDown( a )
	local args = {}
	args.job = self.availableJobKey
	if a.key == string.byte("J") and args.job != 0 then
		Network:Send( "TakeJob", args )
		self.windowButton:SetTextColor(Color(0, 255, 0))
	else
		self.windowButton:SetTextColor(Color(255, 255, 255))
	end
	
end

function PanauDrivers:DrawLocation(k, v, dist, dir)
	local pos = v.position + Vector3( 0, 10, 0 )
	local angle = Angle( Camera:GetAngle().yaw, 0, math.pi ) * Angle( math.pi, 0, 0 )
	
	local textSize = 16
	local textScale = 1.0
	local textAlpha = 255
	if dist <= 64 then
		textAlpha = 0
	elseif dist <= 256 then
		textAlpha = 255
		textScale = 0.2
	elseif dist <= 512 then
		textAlpha = 255
		textScale = 0.5
	else
		textAlpha = 128
	end

	local text = v.name
	local textBoxScale = Render:GetTextSize( text, textSize )

	local t = Transform3()
	t:Translate( pos )
	t:Scale( textScale )
    t:Rotate( angle )
    t:Translate( -Vector3( textBoxScale.x, textBoxScale.y, 0 )/2 )

    Render:SetTransform( t )


	self:DrawShadowedText( Vector3( 0, 0, 0 ), text, Color( 255, 255, 255, textAlpha ), textSize )
	
	if dist <= 256 then
		t2 = Transform3()
		local upAngle = Angle(0, math.pi/2, 0)
		t2:Translate(v.position):Rotate(upAngle)
		Render:SetTransform(t2)
		Render:FillCircle( Vector3(0,0,0), 20, Color(255, 255, 255, 48))
		--render arrow
		if self.job == nil then
			Render:ResetTransform()
			t3 = Transform3()
			t3:Translate(v.position)
			Render:SetTransform(t3)
			arrow1 = Vector3( 0, 3, 0 )
			arrow2 = Vector3( 0, 9, 0 )
			arrow3 = Vector3( 0, 6, 0 ) - (dir * 4)
			shaft1 = Vector3( 0, 5, 0 )
			shaft2 = Vector3( 0, 7, 0 )
			shaft3 = shaft1 + (dir * 4)
			shaft4 = shaft2 + (dir * 4)
			Render:FillTriangle(arrow1, arrow2, arrow3, Color(64, 255, 64, 128))
			Render:FillTriangle(shaft1, shaft2, shaft3, Color(64, 255, 64, 128))
			Render:FillTriangle(shaft2, shaft3, shaft4, Color(64, 255, 64, 128))
		end
	end
	
	Render:ResetTransform()
	
	if dist <= 24 and self.job == nil then
		local theJob = self.jobsTable[k]
		if self.jobUpdateTimer:GetSeconds() > 1 then
			self.windowL1:SetText( theJob.description )
			self.windowL2:SetText( "$" .. tostring(theJob.reward) )
			self.windowL3:SetText( Vehicle.GetNameByModelId(theJob.vehicle) )
			self.jobUpdateTimer:Restart()
		end
		self.window:SetVisible( true )
		self.availableJobKey = k
		self.availableJob = theJob
	end
	
	
end

function PanauDrivers:Render()
	availableJob = nil
	self.window:SetVisible( false )
	if Game:GetState() ~= GUIState.Game then return end
	if LocalPlayer:GetWorld() ~= DefaultWorld then return end
	
	if self.jobsTable != nil then
		for k, v in ipairs(self.locations) do
			local camPos = Camera:GetPosition()
			local jobToRender = self.jobsTable[k]
			if v.position.x > camPos.x - 1028 and v.position.x < camPos.x + 1028 and v.position.z > camPos.z - 1028 and 	v.position.z < camPos.z + 1028 and jobToRender.direction != nil then
				self:DrawLocation(k, v, v.position:Distance2D( Camera:GetPosition()), jobToRender.direction)
			end
		end
	end
	
	if self.job != nil then
		--job text
		local textPos = Vector2( Render.Width / 2, Render.Height * 0.1 )
		local text = "Job: " .. self.job.description
		textPos = textPos - Vector2( Render:GetTextWidth(text) / 2, 0 )
		Render:DrawText( textPos + Vector2( 1, 1 ), text, Color( 0, 0, 0, 80 ) )
		Render:DrawText( textPos, text, Color( 192, 255, 192 ))
		--job arrow
		pVehicle = LocalPlayer:GetVehicle()
		if pVehicle != nil then
			destPos = self.locations[self.job.destination].position
			arrowDir = pVehicle:GetPosition() - destPos
			arrowDir:Normalize()
			dirCp = arrowDir:Cross( Vector3(0, 1, 0) )
			dirCn = Vector3(0, 1, 0):Cross( arrowDir )
			Render:ResetTransform()
			t3 = Transform3()
			t3:Translate(pVehicle:GetPosition() + Vector3( 0, 0, 0 ))
			Render:SetTransform(t3)
			--arrow1 = Vector3( 0, 3, 0 )
			--arrow2 = Vector3( 0, 9, 0 )
			arrow1 = dirCp * 4
			arrow2 = dirCn * 4
			arrow3 = Vector3( 0, 0, 0 ) - (arrowDir * 4)
			shaft1 = dirCp * 2
			shaft2 = dirCn * 2
			shaft3 = shaft1 + (arrowDir * 4)
			shaft4 = shaft2 + (arrowDir * 4)
			Render:FillTriangle(arrow1, arrow2, arrow3, Color(64, 255, 64, 128))
			Render:FillTriangle(shaft1, shaft2, shaft3, Color(64, 255, 64, 128))
			Render:FillTriangle(shaft2, shaft3, shaft4, Color(64, 255, 64, 128))
			Render:ResetTransform()
		end
	end
	
end

PanauDrivers = PanauDrivers()