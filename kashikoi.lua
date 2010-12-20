local Astrolabe = DongleStub("Astrolabe-1.0")
local function dump_table(t)
	for key,value in pairs(t) do
		print(key .. '=' .. value)
	end
end
local surveys, last_survey = {},{}
local survey_count = 0
local search_area_width,search_area_height = 20,20
local search_frames = {}
local asking = false
local function get_search_frame(x,y)
	if search_frames[x] == nil then
		search_frames[x] = {}
	end
	if search_frames[x][y] == nil then
		local spot = CreateFrame("Frame", nil, nil)
		spot:SetWidth(15)
		spot:SetHeight(15)
		local t = spot:CreateTexture(nil,"BACKGROUND")
		local foo = [[Interface\AddOns\clever_archaelogy\X.tga]]
		--local foo = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp"
		t:SetTexture(foo)
		t:SetAllPoints(spot)
		spot.texture = t
		search_frames[x][y] = spot
	end
	--search_frames[x][y]:Show()
	return search_frames[x][y]
end
local rings = {}
local function get_ring(x,y)
	if rings[x] == nil then
		rings[x] = {}
	end
	if rings[x][y] == nil then
		local t = kashi_env.main_frame:CreateTexture(nil,"BACKGROUND")
		local circle = [[Interface\AddOns\clever_archaelogy\circle.tga]]
		t:SetTexture(circle)
		t:SetWidth(200)
		t:SetHeight(200)
		t:SetPoint("CENTER",0,0)
		rings[x][y] = t
	end
	return rings[x][y]
end
local function hide_search_frames()
	local x,y
	for x = 0,search_area_width do
		for y = 0,search_area_height do
			local spot = get_search_frame(x,y)
			if spot.placed then
					result = Astrolabe:RemoveIconFromMinimap( search_frames[x][y] )
					search_frames[x][y].placed = false
			end
			search_frames[x][y]:Hide()
		end
	end
end
local function clear_binds()
	asking = false
	local t = kashi_env.main_frame
	SetOverrideBinding(t,false,"1")
	SetOverrideBinding(t,false,"2")
	SetOverrideBinding(t,false,"3")
end
local function reset_surveys()
	for key,value in pairs(surveys) do
		if value.texture then
			value.texture:Hide()
		end
	end
	surveys = {}
	last_survey = {}
	survey_count = 0
	clear_binds()
	hide_search_frames()
	survey_count = 0
end
local function distance(a,b)
	--local x = a.x - b.x
	--local y = a.y - b.y
	local c1,z1 = GetCurrentMapContinent(),GetCurrentMapZone()
	c1,z1 = GetCurrentMapAreaID(), GetCurrentMapDungeonLevel()
	local dist,xdelta,ydelta = Astrolabe:ComputeDistance(c1,z1,a.x,a.y, c1,z1,b.x,b.y)
	--print(a.x.." "..a.y.." "..b.x.." "..b.y.." "..(dist*10).." "..xdelta.." "..ydelta)
	return dist,xdelta,ydelta
	--return math.sqrt(x*x + y*y)
end
local min_dist = {  5, 40,  80 }
local max_dist = { 41, 78, 608 }
local widths = { 25,50,100 }
local function frame_update()
	local self,text = {},{}
	local line
	local good,bad = 0,0
	self.x,self.y = GetPlayerMapPosition("player")
	for key,value in pairs(surveys) do
		local min,max = min_dist[value.answer],max_dist[value.answer]
		local range = max - min
		if value.x == nil then
			return
		end
		local dist = distance(self,value)
		line = math.floor(dist).." "..value.answer
		if min_dist[value.answer] > dist then
			line = line .. " too close to survey"
			bad = bad + 1
		elseif max_dist[value.answer] < dist then
			line = line .. " too far?"
			bad = bad +1
		else
			good = good + 1
		end
		local percent = ((dist - min) / (max - min)) - 0.5 -- should land in the range of -0.5 to 0.5 if your at the right distance
		local width = widths[value.answer]
		local x,y = (percent - 0.5) * width,-13*key
		line = line .. " " .. (math.floor(percent*1000)/1000) --.." "..min.." "..max .. " "..(math.floor(x*1000)/1000)
		x = x  + (kashi_env.main_frame:GetWidth()/2)
		

		value.texture:SetPoint("LEFT",kashi_env.main_frame,x,y)
		value.texture:SetSize(width,10)
		table.insert(text,line)
	end
	table.insert(text,"good/bad: "..good.."/"..bad)
	kashi_env.fs:SetText(table.concat(text,"\n"))

	for key,value in pairs(surveys) do
		local dist,xdelta,ydelta = distance(self,value)
		for key,ring in pairs(value.rings) do
			ring:SetPoint("CENTER",xdelta,ydelta)
		end
	end
end
local function update_all_icons()
	hide_search_frames()
	local spots = 1
	local self = {}
	local x,y
	local c1,z1 = GetCurrentMapAreaID(), GetCurrentMapDungeonLevel()
	self.x,self.y = GetPlayerMapPosition("player")
	for x = 0,search_area_width do
		for y = 0,search_area_height do
			local spot = get_search_frame(x,y)
			spot.OK = true
			--spot:Hide()
		end
	end
	local offset = 0.003
	for x = 0,search_area_width do
		for y = 0,search_area_height do
			local spot2 = {}
			spot2.x,spot2.y = self.x + ((x-(search_area_width/2))*offset),self.y + ((y-(search_area_height/2))*offset)
			for key,value in pairs(surveys) do
				local OK = true
				local min,max = min_dist[value.answer],max_dist[value.answer]
				local dist = distance(spot2,value)
				if min > dist then
					OK = false
				elseif max < dist then
					OK = false
				else
					OK = true
				end
				local spot = get_search_frame(x,y)
				if OK == false then
					spot.OK = false
					if spot.placed then
						result = Astrolabe:RemoveIconFromMinimap( spot )
						spot.placed = false
					end
					spot:Hide()
				end
				spots = spots + 1
			end
		end
	end
	for x = 0,search_area_width do
		for y = 0,search_area_height do
			local spot = get_search_frame(x,y)
			local spot2 = {}
			spot2.x,spot2.y = self.x + ((x-(search_area_width/2))*offset),self.y + ((y-(search_area_height/2))*offset)
			if spot.OK then
				result = Astrolabe:PlaceIconOnMinimap( spot, c1, z1, spot2.x,spot2.y )
				spot:Show()
				spot.placed = true
			end
		end
	end
	print("did "..spots.." spots")
end
local update_hooked = false
local function hook_update()
	if not update_hooked then
		kashi_env.main_frame:SetScript("OnUpdate",frame_update)
		update_hooked = true
	end
end
local function unhook_update()
	if update_hooked then
		kashi_env.main_frame:SetScript("OnUpdate",nil)
		update_hooked = false
	end
end
local textures = {}
local function show_new_rings(red,green,blue,answer,survey_count)
	local rings = {}
	for dist1,count in pairs(kashi_data.dists[answer]) do
		local ring = get_ring(survey_count,dist1)
		ring:SetWidth(dist1/2)
		ring:SetHeight(dist1/2)
		ring:SetVertextColor(red,green,blue,count/kashi_data.max_count[answer])
		ring:Show()
		table.insert(rings,ring)
	end
	return rings
end
function CA_answer(answer)
	clear_binds()
	if not asking then
		print("something else went wrong")
		return
	end
	if last_survey.x == nil then
		print('something went wrong?')
		return
	end
	print(answer)
	last_survey.answer = answer
	PlaySoundFile("Interface\\AddOns\\TomTom\\Media\\ping.mp3")
	if textures[survey_count] == nil then
		textures[survey_count] = kashi_env.main_frame:CreateTexture(nil,"ARTWORK")
	end
	last_survey.texture = textures[survey_count]
	last_survey.texture:Show()
	local red,green,blue
	red=0
	green=0
	blue=0
	if answer == 1 then
		green = 0.8
	elseif answer == 2 then
		green = 0.8
		red = 0.8
	elseif answer == 3 then
		red = 0.8
	end
	last_survey.texture:SetPoint("TOP",kashi_env.main_frame,10,-13*survey_count)
	last_survey.texture:SetSize(50,10)
	last_survey.texture:SetTexture(red,green,blue)
	last_survey.rings = show_new_rings(red,green,blue,answer,survey_count)
	survey_count = survey_count + 1
	
	hook_update()
	table.insert(surveys,last_survey)
	last_survey = {}
	update_all_icons()
end
local function interact_lag()
	local npc_name = GameTooltipLeftText1:GetText()
	local macroid = GetMacroIndexByName("hover_target")
	-- /run ChatFrameEditBox:SetText("/target " .. GameTooltipLeftText1:GetText())
end
local function sanitize_data()
	if kashi_data == nil then
		kashi_data = {}
	end
	if kashi_data.zones == nil then
		kashi_data.zones = {}
	end
	if kashi_data.dists == nil then
		kashi_data.dists = {}
		kashi_data.dists[1] = {}
		kashi_data.dists[2] = {}
		kashi_data.dists[3] = {}
	end
	kashi_data.max_count = {}
	for key1,value1 in pairs(kashi_data.dists) do
		local max = 0
		for dist,count in pairs(value1) do
			print(dist)
			print(count)
			if count > max then
				max = count
			end
		end
		kashi_data.max_count[key1] = max
	end
end
local function post_process(new_entry)
	for key,value in pairs(new_entry.surveys) do
		if value.x == nil then
			return
		end
		value.dist = distance(new_entry,value)
		local rounded = math.floor(value.dist)
		if rounded then
			if kashi_data.dists[value.answer][rounded] == nil then
				kashi_data.dists[value.answer][rounded] = 1
			else
				kashi_data.dists[value.answer][rounded] = kashi_data.dists[value.answer][rounded] + 1
			end
		end
	end
	table.sort(kashi_data.dists[1])
	table.sort(kashi_data.dists[2])
	table.sort(kashi_data.dists[3])
end
local function handle_spell_finished(self,event,...)
	local caster,spell_name,arg3,arg4,spellid = ...
	if spellid == 80451 and caster == "player" then
		myprint('surveying')
		self:Show()
		if not InCombatLockdown() then
			asking = true
			SetOverrideBinding(self,false,"1","CA_1")
			SetOverrideBinding(self,false,"2","CA_2")
			SetOverrideBinding(self,false,"3","CA_3")
			RaidNotice_AddMessage(RaidBossEmoteFrame, ("hit 1 for green, 2 for yellow, 3 for red"), ChatTypeInfo["RAID_WARNING"])
			last_survey.x,last_survey.y = GetPlayerMapPosition("player")
		end
	elseif spellid == 73979 then
		myprint('finding artifact')
		clear_binds()
	elseif spellid == 75543 then
		RaidNotice_AddMessage(RaidBossEmoteFrame, ("skullcrush over, safe to melee"), ChatTypeInfo["RAID_WARNING"])
	else
		--myprint(caster.." "..spell_name.." "..spellid)
	end
end
local function eventHandler(self,event,...)
	local arg1,arg2,arg3 = ...
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		handle_spell_finished(self,event,...)
	elseif event == "CHAT_MSG_ADDON" then
	elseif event == "PLAYER_ENTERING_WORLD" then
		self:SetPoint("CENTER",0,0)
		self:Show()
		myprint('entering world')
		unhook_update()
		kashi_env.fs:SetText("zone changed")
		reset_surveys()
	elseif event == "CHAT_MSG_LOOT" then
		--myprint("'"..arg1.."'"..arg2.."'"..arg3.."'")
		local log_event = 0
		if string.find(arg1,"You create") then
			log_event = 0
		elseif string.find(arg1,"You receive loot") then
			log_event = 0
		elseif string.find(arg1,"You receive currency") then
			log_event = 1
		end
		if log_event == 1 then
			--local clean_name = arg1:match("|h%[(.-)%]|h")
			local new_entry = {}
			new_entry.raw_text = arg1
			--new_entry.text = clean_name
			new_entry.x,new_entry.y = GetPlayerMapPosition("player")
			new_entry.zone = GetZoneText()
			new_entry.subzone = GetSubZoneText()
			new_entry.surveys = surveys
			--sanitize_data()
			unhook_update()
			reset_surveys()
			post_process(new_entry)
			kashi_env.fs:SetText("item found")
			for key,value in pairs(surveys) do
				value.texture:Hide()
				value.texture = nil
			end

			if kashi_data.zones[new_entry.zone] == nil then
				kashi_data.zones[new_entry.zone] = {}
			end
			table.insert(kashi_data.zones[new_entry.zone],new_entry)
			--myprint("logged creation of '"..clean_name.."'")
			self:Hide()
		end
	elseif event == "ADDON_LOADED" then
		if arg1 == "clever_archaelogy" then
			sanitize_data()
			print("Clever Archaeologist is fully loaded")
		end
	elseif event == "GUILD_XP_UPDATE" then
		local currentXP, remainingXP, dailyXP, maxDailyXP = UnitGetGuildXP("player");
		print('guild exp: '..(currentXP/1000)..'/'..(remainingXP/1000)..' '..(dailyXP/1000)..'/'..(maxDailyXP/1000))
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		reset_surveys()
		kashi_env.fs:SetText("zone changed")
		print(GetZoneText())
	else
		print("event handler for event '" .. event .. "'")
		--print(self,event,arg1,arg2,arg3)
	end
end
local function make_resizeable(frame)
	-- taken from http://forums.worldofwarcraft.com/thread.html?topicId=16903635905&sid=1
	-- via google's cache (forum rework broke all links)
	local grip = CreateFrame("Frame", nil, frame)
	grip:EnableMouse(true)
	
	local tex = grip:CreateTexture()
	grip.tex = tex
	tex:SetTexture([[Interface\BUTTONS\UI-AutoCastableOverlay]])
	tex:SetTexCoord(0.619, 0.760, 0.612, 0.762)
	tex:SetDesaturated(true)
	tex:ClearAllPoints()
	tex:SetPoint("TOPLEFT")
	tex:SetPoint("BOTTOMRIGHT", grip, "TOPLEFT", 12, -12)

	grip:SetWidth(22)
	grip:SetHeight(21)
	grip:SetScript("OnMouseDown", function(self)
			self:GetParent():StartSizing()
		end)
	grip:SetScript("OnMouseUp", function(self)
			self:GetParent():StopMovingOrSizing()
		end)

	grip:ClearAllPoints()
	grip:SetPoint("BOTTOMRIGHT")
	grip:SetScript("OnEnter", function(self)
			self.tex:SetDesaturated(false)
		end)
	grip:SetScript("OnLeave", function(self)
			self.tex:SetDesaturated(true)
		end) 
end
local function kashi_init()
	local frame = CreateFrame("FRAME", "KashiAddonFrame")
	--frame:RegisterEvent("MINIMAP_PING") -- , unitid,x,y
	frame:RegisterEvent("CHAT_MSG_LOOT")
	frame:RegisterEvent("ADDON_LOADED")
	frame:RegisterForDrag("LeftButton")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	frame:RegisterEvent("GUILD_XP_UPDATE")
	--frame:RegisterEvent("ARCHAEOLOGY_CLOSED")
	--frame:RegisterEvent("ARCHAEOLOGY_TOGGLE")
	--frame:RegisterEvent("ARTIFACT_COMPLETE")
	--frame:RegisterEvent("ARTIFACT_DIG_SITE_UPDATED")
	--frame:RegisterEvent("ARTIFACT_HISTORY_READY")
	--frame:RegisterEvent("ARTIFACT_UPDATE")
	--frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
	--frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	--frame:RegisterEvent("CHAT_MSG_ADDON")
	frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	frame:RegisterEvent("PLAYER_ENTER_COMBAT") -- might not work
	frame:RegisterEvent("PLAYER_LEAVE_COMBAT")
	frame:RegisterEvent("PLAYER_REGEN_DISABLED")
	frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	frame:SetMovable(true)
	--frame:SetClampedToScreen(true)
	frame:SetScript("OnDragStart", function(frame)
			frame:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(frame)
			frame:StopMovingOrSizing()
	end)
	kashi_env = {}
	kashi_env.main_frame = frame
	--kashi_env.debug_frame = CreateFrame("ScrollingMessageFrame")
	--kashi_env.debug_frame:SetAllPoints()
	--kashi_env.debug_frame:SetPoint("CENTER",0,0)
	--kashi_env.debug_frame:SetWidth(50)
	--kashi_env.debug_frame:SetHeight(50)
	--kashi_env.debug_frame:SetMaxLines(8)

	frame:SetFrameStrata("BACKGROUND")
	frame:SetWidth(250)
	frame:SetHeight(100)

	local t = frame:CreateTexture(nil,"BACKGROUND")
	local foo = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp"
	--foo = "Interface\\WorldMap\\Stormwind City\\Stormwind City1.blp"
	t:SetTexture(foo)
	t:SetAllPoints(frame)
	frame.texture = t
	

	local font_string = frame:CreateFontString('my_output',"OVERLAY", "GameFontNormal")
	--font_string:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE, MONOCHROME") 
	font_string:SetAllPoints(frame)
	font_string:SetText('ready for survey')
	kashi_env.fs = font_string

	frame:SetPoint("CENTER",0,0)
	frame:EnableMouse()
	frame:SetResizable(true)
	make_resizeable(frame)
	frame:Show()
	--kashi_env.debug_frame:Show()
	frame:SetScript("OnEvent",eventHandler)
	--kashi_env.debug_frame:AddMessage('foo')

end
kashi_init()
print("kashikoi's addon done loading")
--print(GetArchaeologyInfo())
