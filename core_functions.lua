kashi_cmds = {}
local function reset_unit(name)
	kashi_env.target[name] = {}
end
function kashi_cmds.is_ally(name)
	if name == "player" then return false
	elseif name == 'target' then return false
	elseif name == "pet" then return true
	elseif name == "raid1" then return true
	elseif name == "raidpet1" then return true
	elseif name == "raid2" then return true
	elseif name == "raidpet2" then return true
	elseif name == "raid3" then return true
	elseif name == "raidpet3" then return true
	elseif name == "raid4" then return true
	elseif name == "raidpet4" then return true
	elseif name == "raid5" then return true
	elseif name == "raidpet5" then return true
	elseif name == "raid6" then return true
	elseif name == "raidpet6" then return true
	elseif name == "raid7" then return true
	elseif name == "raidpet7" then return true
	elseif name == "raid8" then return true
	elseif name == "raidpet8" then return true
	elseif name == "raid9" then return true
	elseif name == "raidpet9" then return true
	elseif name == "party1" then return true
	else
		myprint("|cFFFF0000"..name.." isnt known")
		return false
	end
end
function myprint(...)
	print(...)
end
function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

