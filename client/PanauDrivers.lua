-- Panau Runners (client)
-- 0.2.1_beta
-- A delivery gamemode in the style of "Crazy Taxi"
-- BluShine
-- released 1/12/2014
-- updated 1/30/2014

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
	self.isVisible = true
	self.arrowVisible = true
	self.arrowSuper = false
	self.locationsVisible = true
	self.locationsAutoHide = true
	self.locations = {}
	self.availableJob = nil
	availableJobKey = 0
	self.job = nil
	self.jobUpdateTimer = Timer()
	self.jobCompleteTimer = Timer()
	
	--GUI config menu
	self.configW = Window.Create()
	self.configW:SetSize( Vector2( 300, 150 ) )
	self.configW:SetPosition( (Render.Size - self.configW:GetSize())/2 )
	self.configW:SetTitle( "Panau Drivers Settings" )
	self.configW:SetVisible( false )
	
	local visibleCheck = LabeledCheckBox.Create( self.configW )
    visibleCheck:SetSize( Vector2( 300, 20 ) )
    visibleCheck:SetDock( GwenPosition.Top )
    visibleCheck:GetLabel():SetText( "Visible" )
    visibleCheck:GetCheckBox():SetChecked( self.isVisible )
    visibleCheck:GetCheckBox():Subscribe( "CheckChanged", 
        function() self.isVisible = visibleCheck:GetCheckBox():GetChecked() end )

    local arrowCheck = LabeledCheckBox.Create( self.configW )
    arrowCheck:SetSize( Vector2( 300, 20 ) )
    arrowCheck:SetDock( GwenPosition.Top )
    arrowCheck:GetLabel():SetText( "Show green arrow" )
    arrowCheck:GetCheckBox():SetChecked( self.arrowVisible )
    arrowCheck:GetCheckBox():Subscribe( "CheckChanged", 
        function() self.arrowVisible = arrowCheck:GetCheckBox():GetChecked() end )
	
	local arrowAxis = LabeledCheckBox.Create( self.configW )
    arrowAxis:SetSize( Vector2( 300, 20 ) )
    arrowAxis:SetDock( GwenPosition.Top )
    arrowAxis:GetLabel():SetText( "Super arrow mode" )
    arrowAxis:GetCheckBox():SetChecked( self.arrowSuper )
    arrowAxis:GetCheckBox():Subscribe( "CheckChanged", 
        function() self.arrowSuper = arrowAxis:GetCheckBox():GetChecked() end )
		
	local locationCheck = LabeledCheckBox.Create( self.configW )
    locationCheck:SetSize( Vector2( 300, 20 ) )
    locationCheck:SetDock( GwenPosition.Top )
    locationCheck:GetLabel():SetText( "Show locations" )
    locationCheck:GetCheckBox():SetChecked( self.locationsVisible )
    locationCheck:GetCheckBox():Subscribe( "CheckChanged", 
        function() self.locationsVisible = locationCheck:GetCheckBox():GetChecked() end )
		
	local locationAutoCheck = LabeledCheckBox.Create( self.configW )
    locationAutoCheck:SetSize( Vector2( 300, 20 ) )
    locationAutoCheck:SetDock( GwenPosition.Top )
    locationAutoCheck:GetLabel():SetText( "Auto-hide locations on job start" )
    locationAutoCheck:GetCheckBox():SetChecked( self.locationsAutoHide )
    locationAutoCheck:GetCheckBox():Subscribe( "CheckChanged", 
        function() self.locationsAutoHide = locationAutoCheck:GetCheckBox():GetChecked() end )
	
	--GUI button
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
	Events:Subscribe( "LocalPlayerChat", self, self.LocalPlayerChat)
	Events:Subscribe( "ModulesLoad", self, self.ModulesLoad )
    Events:Subscribe( "ModuleUnload", self, self.ModuleUnload )
end

function PanauDrivers:LocalPlayerChat( args )
	local msg = args.text
	if msg == "/help" or msg == "/h" then
		Chat:Print("/panaudrivers to disable or enable Panau Drivers jobs", Color(255,255,0))
		return false
	end
	if msg == "/panaudrivers" or msg == "/drive" then
		if self.configW:GetVisible() == true then
			self.configW:SetVisible( false )
		else 
			self.configW:SetVisible( true )
		end
		return false
	end
end

function PanauDrivers:LocalPlayerInput( args )
    if self.configW:GetVisible() == true and Game:GetState() == GUIState.Game then
        return false
    end
end

function PanauDrivers:ModulesLoad()
    Events:Fire( "HelpAddItem",
        {
            name = "PanauDrivers",
            text = 
                "Panau Drivers is a script that generates delivery " ..
                "jobs all over panau.\n\nTo configure or disable it, " ..
                "type /panaudrivers or /drive in chat to configure UI options.\n\n" ..
				"types /co in chat to create companies and do jobs with other players"
        } )
end

function PanauDrivers:ModuleUnload()
    Events:Fire( "HelpRemoveItem",
        {
            name = "PanauDrivers"
        } )
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
	if self.locationsAutoHide == true then
		self.locationsVisible = false
	end
end

function PanauDrivers:JobFinish( args )
	if self.job != nil then
		Waypoint:Remove()
		self.job = nil
	end
	if self.locationsAutoHide == true then
		self.locationsVisible = true
	end
end

function PanauDrivers:JobCancel( args )
	if self.job != nil then
		Waypoint:Remove()
		self.job = nil
	end
	if self.locationsAutoHide == true then
		self.locationsVisible = true
	end
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

function PanauDrivers:DrawLocation(k, v, dist, dir, jobDistance)
	local pos = v.position + Vector3( 0, 10, 0 )
	local angle = Angle( Camera:GetAngle().yaw, 0, math.pi ) * Angle( math.pi, 0, 0 )
	
	local textSize = 16
	local textScale = 1.0
	local textAlpha = 255
	if dist <= 64 then
		textAlpha = 255
		textScale = 0.1
	elseif dist <= 128 then
		textAlpha = 196
		textScale = 0.2
	elseif dist <= 256 then
		textAlpha = 128
		textScale = 0.3
	else
		textAlpha = 0
	end

	local text = v.name
	local textBoxScale = Render:GetTextSize( text, textSize )

	local t = Transform3()
	t:Translate( pos )
	t:Scale( textScale )
    t:Rotate( angle )
    t:Translate( -Vector3( textBoxScale.x, textBoxScale.y, 0 )/2 )

    Render:SetTransform( t )

	if self.locationsVisible == true then
		self:DrawShadowedText( Vector3( 0, 0, 0 ), text, Color( 255, 255, 255, textAlpha ), textSize ) end
	
	if self.locationsVisible == true then
		t2 = Transform3()
		local upAngle = Angle(0, math.pi/2, 0)
		t2:Translate(v.position):Rotate(upAngle)
		Render:SetTransform(t2)
		Render:FillCircle( Vector3(0,0,0), 20, Color(255, 255, 255, 32))
		--render arrow
		if self.job == nil then
			--color arrow based on distance
			local arrowColor = Color(0,0,0,128)
			if jobDistance < 1000 then
				arrowColor = Color(64, 255, 128, 128)
			elseif jobDistance < 2000 then
				arrowColor = Color(128, 255, 196, 128)
			elseif jobDistance < 4000 then
				arrowColor = Color(128, 255, 0, 128)
			elseif jobDistance < 6000 then
				arrowColor = Color(255, 255, 0, 128)
			elseif jobDistance < 8000 then
				arrowColor = Color(255, 128, 0, 128)
			elseif jobDistance < 10000 then
				arrowColor = Color(255, 128, 0, 128)
			elseif jobDistance < 14000 then
				arrowColor = Color(255, 0, 0, 128)
			else
				arrowColor = Color(128, 0, 255, 128)
			end
			--draw arrow
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
			Render:FillTriangle(arrow1, arrow2, arrow3, arrowColor)
			Render:FillTriangle(shaft1, shaft2, shaft3, arrowColor)
			Render:FillTriangle(shaft2, shaft3, shaft4, arrowColor)
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
	Mouse:SetVisible( self.configW:GetVisible() )
	availableJob = nil
	self.window:SetVisible( false )
	if Game:GetState() ~= GUIState.Game then return end
	if LocalPlayer:GetWorld() ~= DefaultWorld then return end
	if self.isVisible == false then return end
	
	if self.jobsTable != nil then
		for k, v in ipairs(self.locations) do
			local camPos = Camera:GetPosition()
			local jobToRender = self.jobsTable[k]
			if v.position.x > camPos.x - 1028 and v.position.x < camPos.x + 1028 and v.position.z > camPos.z - 1028 and 	v.position.z < camPos.z + 1028 and jobToRender.direction != nil then
				self:DrawLocation(k, v, v.position:Distance2D( Camera:GetPosition()), jobToRender.direction, jobToRender.distance)
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
		--draw destination circle
		destPos = self.locations[self.job.destination].position
		destDist = Vector3.Distance(destPos, LocalPlayer:GetPosition())
		if destDist < 500 then
			t2 = Transform3()
			local upAngle = Angle(0, math.pi/2, 0)
			t2:Translate(destPos):Rotate(upAngle)
			Render:SetTransform(t2)
			Render:FillCircle( Vector3(0,0,0), 15, Color(64, 255, 64, 64))
		end
		--job arrow
		pVehicle = LocalPlayer:GetVehicle()
		if pVehicle != nil and self.arrowVisible == true then
			local multiArrow = 1
			if (self.arrowSuper == true) then
				multiArrow = 3
			end
			while (multiArrow > 0) do
				--calculate arrow direction
				--add -10 to position to make the arrow's origin a bit above the vehicle
				arrowDir = pVehicle:GetPosition() - destPos
				arrowDir:Normalize()
				arrowDir = arrowDir + Vector3(0, .1, 0)
				arrowDir.y = -arrowDir.y
				arrowDir.z = -arrowDir.z
				arrowDir.x = -arrowDir.x
				local arrowAxis = Vector3(0, 1, 0)
				if (multiArrow == 3) then
					arrowAxis = Vector3(0, 0, 1)
				end
				if (multiArrow == 2) then
					arrowAxis = Vector3(1, 0, 0)
				end
				dirCp = arrowDir:Cross( arrowAxis )
				dirCn = arrowAxis:Cross( arrowDir )
				Render:ResetTransform()
				--make the arrow segments
				arrowScale = Render.Height * .05
				arrow1 = dirCp * arrowScale * 2
				arrow2 = dirCn * arrowScale * 2
				arrow3 = Vector3( 0, 0, 0 ) - (arrowDir * arrowScale * 2)
				shaft1 = dirCp * arrowScale
				shaft2 = dirCn * arrowScale
				shaft3 = shaft1 + (arrowDir * arrowScale * 2)
				shaft4 = shaft2 + (arrowDir * arrowScale * 2)
				--multiply by camera angle to flatten everything relative to the camera
				local ang = Camera:GetAngle():Inverse()
				arrow1 = ang * arrow1
				arrow2 = ang * arrow2
				arrow3 = ang * arrow3
				shaft1 = ang * shaft1
				shaft2 = ang * shaft2
				shaft3 = ang * shaft3
				shaft4 = ang * shaft4
				--turn 3d in to 2d
				center = Vector2( Render.Width / 2, Render.Height / 3 )
				arrow1 = Vector2( -arrow1.x, arrow1.y) + center
				arrow2 = Vector2( -arrow2.x, arrow2.y) + center
				arrow3 = Vector2( -arrow3.x, arrow3.y) + center
				shaft1 = Vector2( -shaft1.x, shaft1.y ) + center
				shaft2 = Vector2( -shaft2.x, shaft2.y ) + center
				shaft3 = Vector2( -shaft3.x, shaft3.y ) + center
				shaft4 = Vector2( -shaft4.x, shaft4.y ) + center
				
				--render everything
				local arrowColor = Color(64, 255, 64, 128)
				Render:FillTriangle(arrow1, arrow2, arrow3, arrowColor)
				Render:FillTriangle(shaft1, shaft2, shaft3, arrowColor)
				Render:FillTriangle(shaft2, shaft3, shaft4, arrowColor)
				
				multiArrow = multiArrow - 1
			end
		end
	end
	
end

PanauDrivers = PanauDrivers()