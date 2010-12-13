local function dump_table(t)
	for key,value in pairs(t) do
		print(key .. '=' .. value)
	end
end
local surveys = {}
local last_survey = {}
function kashi_chatframe_onload(x)
	--x.flashTimer = 0
	x:Show()
	--x:SetWidth(300)
	--x:SetHeight(300)
	x:SetClampedToScreen(true)
	--x:SetBackdrop(GameTooltip:GetBackdrop())
	x:SetFontObject(GameFontNormal)
	myprint("chatframe2 loaded")
end
local function clear_binds()
	local self = kashi_env.main_frame
	SetOverrideBinding(self,false,"1")
	SetOverrideBinding(self,false,"2")
	SetOverrideBinding(self,false,"3")
end
local function distance(a,b)
	local x = a.x - b.x
	local y = a.y - b.y
	local foo = x*x + y*y
	return math.sqrt(foo)
end
local min_dist = { 0.001, 0.011, 0.024 }
local max_dist = { 0.012, 0.039, 0.121 }
local function frame_update()
	local x
	local y
	x,y = GetPlayerMapPosition("player")
	local self = {}
	self.x = x
	self.y = y
	--kashi_env.fs:SetText(x..","..y)
	local text = {}
	for key,value in pairs(surveys) do
		if value.x == nil then
			return
		end
		local dist = distance(self,value)
		local line = (math.floor(dist*1000)/1000).." "..value.answer
		if min_dist[value.answer] > dist then
			line = line .. " too close to survey"
		elseif max_dist[value.answer] < dist then
			line = line .. " too far?"
		end
		table.insert(text,line)
	end
	kashi_env.fs:SetText(table.concat(text,"\n"))
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
function kashi_chatframe_onevent(self,event,...)
	--myprint(event)
	if event == "PLAYER_ENTERING_WORLD" then
		self:SetPoint("CENTER",0,0)
		self:Show()
		myprint('entering world')
		unhook_update()
		kashi_env.fs:SetText("zone changed")
		surveys = {}
		--myprint(self:IsVisible())
		--self:SetBackdropColor(1,0,0)
		--self:AddMessage("work damn you!!!",1,1,1,53,5);
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local caster,spell_name,arg3,arg4,spellid = ...
		if spellid == 80451 and caster == "player" then
			myprint('surveying')
			if not InCombatLockdown() then
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
	elseif event == "CHAT_MSG_ADDON" then
		--print(...)
	else
		return false
	end
	return true
end
function CA_answer(answer)
	clear_binds()
	if last_survey.x == nil then
		print('something went wrong?')
		return
	end
	print(answer)
	last_survey.answer = answer
	table.insert(surveys,last_survey)
	last_survey = {}
	hook_update()
	PlaySoundFile("Interface\\AddOns\\TomTom\\Media\\ping.mp3")
end
local function interact_lag()
	local npc_name = GameTooltipLeftText1:GetText()
	local macroid = GetMacroIndexByName("hover_target")
	-- /run ChatFrameEditBox:SetText("/target " .. GameTooltipLeftText1:GetText())
end
local function update_spellbar()
	--print("doing fake spellbar update")
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
end
local function fix_target(arg1)
	if kashi_env.target[arg1] == nil then
		kashi_env.target[arg1] = {}
		kashi_env.target[arg1].death_time = 0
		kashi_env.target[arg1].name = selected_name
		kashi_env.target[arg1].health = UnitHealth(arg1)
		kashi_env.target[arg1].time = GetTime()
		kashi_env.target[arg1].avg_rate = 0
	end
end
local function post_process(new_entry)
	for key,value in pairs(new_entry.surveys) do
		if value.x == nil then
			return
		end
		value.dist = distance(new_entry,value)
		local rounded = math.floor(value.dist * 1000)/1000
		if kashi_data.dists[value.answer][rounded] == nil then
			kashi_data.dists[value.answer][rounded] = 1
		else
			kashi_data.dists[value.answer][rounded] = kashi_data.dists[value.answer][rounded] + 1
		end
	end
	table.sort(kashi_data.dists[1])
	table.sort(kashi_data.dists[2])
	table.sort(kashi_data.dists[3])
end
local function eventHandler(self,event,...)
	local handled = kashi_chatframe_onevent(self,event,...)
	local arg1,arg2,arg3 = ...
	if event == "PLAYER_TARGET_CHANGED" then
		local selected_name = UnitName("target")
		if selected_name ~= nil then 
			--myprint("you selected '" .. selected_name .. "'")
			if kashi_env.target['target'] == nil then
				kashi_env.target['target'] = {}
				kashi_env.target['target'].death_time = 0
			end
			kashi_env.target['target'].name = selected_name
			kashi_env.target['target'].health = UnitHealth('target')
			kashi_env.target['target'].time = GetTime()
		else
			--print("you unselected the target");
			kashi_env.target['target'] = {}
			kashi_env.target['target'].death_time = 0;
		end
		update_spellbar()
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
			sanitize_data()
			post_process(new_entry)
			unhook_update()
			kashi_env.fs:SetText("item found")
			surveys = {}

			if kashi_data.zones[new_entry.zone] == nil then
				kashi_data.zones[new_entry.zone] = {}
			end
			table.insert(kashi_data.zones[new_entry.zone],new_entry)
			--myprint("logged creation of '"..clean_name.."'")
		end
	elseif event == "ADDON_LOADED" then
		if arg1 == "kashikoi" then
			sanitize_data()
			myprint("kashikoi's addon is fully loaded")
		end
	elseif handled == false then
		print("event handler for event '" .. event .. "'")
		--print(self,event,arg1,arg2,arg3)
	end
end
local function make_resizeable(frame)
	-- taken from http://forums.worldofwarcraft.com/thread.html?topicId=16903635905&sid=1
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
	frame:RegisterEvent("MINIMAP_PING") -- , unitid,x,y
	frame:RegisterEvent("PLAYER_TARGET_CHANGED") -- arg1
	frame:RegisterEvent("CHAT_MSG_LOOT")
	frame:RegisterEvent("ADDON_LOADED")
	frame:RegisterForDrag("LeftButton")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
	frame:RegisterEvent("CHAT_MSG_ADDON")
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:SetScript("OnDragStart", function(frame)
			frame:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(frame)
			frame:StopMovingOrSizing()
	end)
	kashi_env = {}
	kashi_env.target = {}
	kashi_env.main_frame = frame
	kashi_env.debug_frame = frame
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
	

	local font_string = frame:CreateFontString('my_output')
	font_string:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE, MONOCHROME") 
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
