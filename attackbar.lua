pont=0.000
pofft= 0.000
ont = 0.000
offt= 0.000
ons = 0.000
offs= 0.000
offh = 0
onh  = 0
epont=0.000
epofft= 0.000
eont = 0.000
eofft= 0.000
eons = 0.000
eoffs= 0.000
eoffh = 0
eonh  = 0
testvar = 0

local last_auto_hit = 0
local SWINGTIME = 0.65
local autorepeat = false
local reload = false
local L = BearCastBar.L

if not(abar) then abar={} end
-- cast spell by name hook
preabar_csbn = CastSpellByName
function abar_csbn(pass, onSelf)
	preabar_csbn(pass, onSelf)
	abar_spelldir(pass)
end
CastSpellByName = abar_csbn
--use action hook
preabar_useact = UseAction
function abar_useact(p1,p2,p3)
	preabar_useact(p1,p2,p3)
    local a,b = IsUsableAction(p1)
    if a then
    	if UnitCanAttack("player","target" )then
    		if IsActionInRange(p1) == 1 then
			Abar_Tooltip:ClearLines()
			Abar_Tooltip:SetAction(p1)
    	local spellname = Abar_TooltipTextLeft1:GetText()
    	if spellname then abar_spelldir(spellname) end
    	end
    	end
    end
end
UseAction = abar_useact
--castspell hook
preabar_cassple = CastSpell
function abar_casspl(p1,p2)
	preabar_cassple(p1,p2)
	local spell = GetSpellName(p1,p2)
		abar_spelldir(spell)
end
CastSpell = abar_casspl

function Abar_loaded()
	SlashCmdList["ATKBAR"] = Abar_chat;
	SLASH_ATKBAR1 = "/abar";
	SLASH_ATKBAR2 = "/atkbar";
	if BCB_SAVED.abar_is_enabled == false then
		abar.range = false
		abar.h2h = false
		abar.timer = false
		abar_core:UnregisterAllEvents()
	else 
		if abar.range == nil then
			abar.range=true
		end
		if abar.h2h == nil then
			abar.h2h=true
		end
		if abar.timer == nil then
			abar.timer=true
		end
	end 
	Abar_Mhr:SetPoint("LEFT",Abar_Frame,"TOPLEFT",6,-13)
	Abar_Oh:SetPoint("LEFT",Abar_Frame,"TOPLEFT",6,-35)
	Abar_MhrText:SetJustifyH("Left")
	Abar_OhText:SetJustifyH("Left")
	--ebar_VL()
end

function Abar_chat(msg)
	msg = strlower(msg)
	if msg == "fix" then
		Abar_reset()
	elseif msg=="lock" then
		Abar_Frame:Hide()
		--ebar_Frame:Hide()
	elseif msg=="unlock" then
		Abar_Frame:Show()
		--ebar_Frame:Show()
	elseif msg=="disable" then 
		abar_core:UnregisterAllEvents()
		BCB_SAVED.abar_is_enabled = false
		abar.range = false
		abar.h2h = false
		abar.timer = false
	elseif msg=="enable" then
		abar_core:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES");
		abar_core:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS");
		abar_core:RegisterEvent("PLAYER_LEAVE_COMBAT")
		abar_core:RegisterEvent("VARIABLES_LOADED")
		abar_core:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
		
		abar_core:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS");
		abar_core:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES");
		abar_core:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS")
		abar_core:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES")
		abar_core:RegisterEvent("START_AUTOREPEAT_SPELL")
		abar_core:RegisterEvent("STOP_AUTOREPEAT_SPELL")
		abar.range = true
		abar.h2h = true
		abar.timer = true
		BCB_SAVED.abar_is_enabled = true
	elseif msg=="huntoff" then
		BCB_SAVED.hunter_is_enabled = false
	elseif msg=="hunton" then
		BCB_SAVED.hunter_is_enabled = true
	else
		DEFAULT_CHAT_FRAME:AddMessage(L['lock - to lock and hide the anchor']);
		DEFAULT_CHAT_FRAME:AddMessage(L['unlock - to unlock and show the anchor']);
		DEFAULT_CHAT_FRAME:AddMessage(L['disable - to disable the attack bar']);
		DEFAULT_CHAT_FRAME:AddMessage(L['enable - to enable the attack bar']);
		DEFAULT_CHAT_FRAME:AddMessage(L['huntoff - to disable the hunter abilities']);
		DEFAULT_CHAT_FRAME:AddMessage(L['hunton - to enable the hunter abilities']);
	end
end

function Abar_selfhit()
	ons,offs=UnitAttackSpeed("player");
	hd,ld,ohd,old = UnitDamage("player")
	hd,ld= hd-math.mod(hd,1),ld-math.mod(ld,1)
	if old then
		ohd,old = ohd-math.mod(ohd,1),old-math.mod(old,1)
end	

if offs then
	ont,offt=GetTime(),GetTime()
	if ((math.abs((ont-pont)-ons) <= math.abs((offt-pofft)-offs))and not(onh <= offs/ons)) or offh >= ons/offs then
		if pofft == 0 then pofft=offt end
		pont = ont
		tons = ons
		offh = 0
		onh = onh +1
		ons = ons - math.mod(ons,0.01)
		Abar_Mhrs(tons,L["Main"].." "..ons..L["s"],1,.1,.1)
	else
		pofft = offt
		offh = offh+1
		onh = 0
		ohd,old = ohd-math.mod(ohd,1),old-math.mod(old,1)
		offs = offs - math.mod(offs,0.01)
		Abar_Ohs(offs,L["Off"].." "..offs..L["s"],1,.1,.1)
	end
else
	ont=GetTime()
	tons = ons
	ons = ons - math.mod(ons,0.01)
	Abar_Mhrs(tons,L["Main"].." "..ons..L["s"],1,.1,.1)
end

end

function Abar_reset()
	pont=0.000
	pofft= 0.000
	ont=0.000
	offt= 0.000
	onid=0
	offid=0
end

function Abar_event(event)
	if event == "START_AUTOREPEAT_SPELL" then autorepeat = true end
	if event == "STOP_AUTOREPEAT_SPELL" then autorepeat = false	end
	if (event=="CHAT_MSG_COMBAT_SELF_MISSES" or event=="CHAT_MSG_COMBAT_SELF_HITS") and abar.h2h == true then Abar_selfhit() end
	if event=="PLAYER_LEAVE_COMBAT" then Abar_reset() end
	if event == "VARIABLES_LOADED" then Abar_loaded() end
	if event == "CHAT_MSG_SPELL_SELF_DAMAGE" then Abar_spellhit(arg1) end
	if event == "VARIABLES_LOADED" then Abar_loaded() end
end

function Abar_spellhit(arg1)
	a,b,spell=string.find (arg1, L["Your (.+) hits"])
	if not spell then 	a,b,spell=string.find (arg1, L["Your (.+) crits"]) end
	if not spell then 	a,b,spell=string.find (arg1, L["Your (.+) is"]) end
	if not spell then	a,b,spell=string.find (arg1, L["Your (.+) misses"]) end
	
	rs,rhd,rld =UnitRangedDamage("player");
	rhd,rld= rhd-math.mod(rhd,1),rld-math.mod(rld,1)
	if spell == L["Auto Shot"] and abar.range == true and BCB_SAVED.hunter_is_enabled then
		last_auto_hit = GetTime()
		trs=rs-SWINGTIME
		rs = rs-math.mod(rs,0.01)-SWINGTIME
		Abar_Mhrs(trs,L["Auto Shot"].." "..rs..L["s"],1,.1,.1)
	elseif spell == L["Shoot"] and abar.range==true then
		trs=rs
		rs = rs-math.mod(rs,0.01)
		Abar_Mhrs(trs,L["Wand"].." "..ons..L["s"],.7,.1,1)
	elseif (spell == L["Raptor Strike"] or spell == L["Heroic Strike"] or
	spell == L["Maul"] or spell == L["Cleave"]) and abar.h2h==true then
		hd,ld,ohd,lhd = UnitDamage("player")
		hd,ld= hd-math.mod(hd,1),ld-math.mod(ld,1)
		if pofft == 0 then pofft=offt end
		pont = ont
		tons = ons
		ons = ons - math.mod(ons,0.01)
		Abar_Mhrs(tons,L["Maul"].." "..ons..L["s"],1,.1,.1)
	end
end

function abar_spelldir(spellname)
	if abar.range then
	local a,b,sparse = string.find (spellname, "(.+)%(")
	if sparse then spellname = sparse end

	rs,rhd,rld =UnitRangedDamage("player");
	rhd,rld= rhd-math.mod(rhd,1),rld-math.mod(rld,1)
	if spellname == L["Throw"] then
		trs=rs
		rs = rs-math.mod(rs,0.01)
		Abar_Mhrs(trs-1,L["Throw"].." "..(rs)..L["s"],1,.1,.1)
	elseif spellname == L["Shoot"] then
		rs =UnitRangedDamage("player")
		trs=rs
		rs = rs-math.mod(rs,0.01)
		Abar_Mhrs(trs-1,L["Wand"].." "..(rs)..L["s"],.7,.1,1)
	elseif spellname == L["Shoot Bow"] then
		trs = rs
		rs = rs-math.mod(rs,0.01)
		Abar_Mhrs(trs-1,L["Bow"].." "..(rs)..L["s"],1,.1,.1)
	elseif spellname == L["Shoot Gun"] then
		trs = rs
		rs = rs-math.mod(rs,0.01)
		Abar_Mhrs(trs-1,L["Gun"].." "..(rs)..L["s"],1,.1,.1)
	elseif spellname == L["Shoot Crossbow"] then
		trs=rs
		rs = rs-math.mod(rs,0.01)
		Abar_Mhrs(trs-1,L["X-Bow"].." "..(rs)..L["s"],1,.1,.1)
	elseif spellname == L["Aimed Shot"] and BCB_SAVED.hunter_is_enabled then
		trs=3
		-- Speed checking from Aviana/YaHT
		for i=1,32 do
			if UnitBuff("player",i) == "Interface\\Icons\\Ability_Warrior_InnerRage" then
				trs = trs/1.3
			end
			if UnitBuff("player",i) == "Interface\\Icons\\Ability_Hunter_RunningShot" then
				trs = trs/1.4
			end
			if UnitBuff("player",i) == "Interface\\Icons\\Racial_Troll_Berserk" then
				berserkValue=0
				if((UnitHealth("player")/UnitHealthMax("player")) >= 0.40) then
					berserkValue = (1.30 - (UnitHealth("player")/UnitHealthMax("player")))/3
				else
					berserkValue = 0.3
				end
				trs = trs / (1 + berserkValue)
			end
			if UnitBuff("player",i) == "Interface\\Icons\\Inv_Trinket_Naxxramas04" then
				trs = trs/1.2
			end
			if UnitDebuff("player",i) == "Interface\\Icons\\Spell_Shadow_CurseOfTounges" then
				trs = trs/0.5
			end
		end
		rs = 3
		if trs < 2.99 and trs > 3.01 then 
			rs = trs-math.mod(trs,0.01) 
		end
		--bcb:SPELLCAST_START("Aimed Shot", trs*1000+200)
		Abar_Mhrs(trs+0.2,L["Aimed Shot"].." "..(rs)..L["s"],1,.1,.1) -- Some extra time because the release seems to be delayed on Aimed shot
	elseif spellname == L["Multi-Shot"] and BCB_SAVED.hunter_is_enabled then
		trs = 0.5
		rs = 0.5
		Abar_Mhrs(0.5,L["Multi-Shot"].." "..(rs)..L["s"],1,.1,.1)
	end
	end
	end


	
function Abar_Update()
	local ttime = GetTime()
	local left = 0.00
	tSpark=getglobal(this:GetName().. "Spark")
	tText=getglobal(this:GetName().. "Tmr")
	if abar.timer==true then
		left = (this.et-GetTime()) - (math.mod((this.et-GetTime()),.1))
		if string.find(this.txt, L["Auto Shot"].." ") then
				lf = GetTime() - last_auto_hit
				swingtime = UnitRangedDamage("player") - SWINGTIME
			if lf > swingtime and not reload and autorepeat then
				reload = true
				rl_time = SWINGTIME - math.max(lf - swingtime, 0)
				rl_time = rl_time  - math.mod(rl_time, 0.01) 	
				Abar_Mhrs(SWINGTIME - math.max(lf - swingtime, 0),L["Reloading"].." "..(rl_time)..L["s"],.5, 1, 0)
			end
		else 
			reload = false		
		end
	--	tText:SetText(this.txt.. "{"..left.."}")
		tText:SetText(left)
		tText:SetPoint("LEFT", this, "LEFT",114, 9);
		tText:Show()
	else
			tText:Hide()
	end
	this:SetValue(ttime)
	tSpark:SetPoint("CENTER", this, "LEFT", (ttime-this.st)/(this.et-this.st)*255, 0);
	if ttime>=this.et then 
	this:Hide() 
	tSpark:SetPoint("CENTER", this, "LEFT",195, 0);
	end
end


function Abar_Mhrs(bartime,text,r,g,b)
		Abar_Mhr:Hide()
		Abar_Mhr.txt = text
		local downAb, upAb, latencyAb = GetNetStats()
		Abar_Mhr.st = GetTime() - (latencyAb/1000)
		Abar_Mhr.et = GetTime() + bartime 
		Abar_Mhr:SetStatusBarColor(r,g,b)
		Abar_MhrText:SetText(text)
		Abar_Mhr:SetMinMaxValues(Abar_Mhr.st,Abar_Mhr.et)
		Abar_Mhr:SetValue(Abar_Mhr.st)
		Abar_Mhr:Show()
end

function Abar_Ohs(bartime,text,r,g,b)
	Abar_Oh:Hide()
	Abar_Oh.txt = text
	local downAb, upAb, latencyAb = GetNetStats()
	Abar_Oh.st = GetTime() - (latencyAb/1000)
	Abar_Oh.et = GetTime() + bartime 
	Abar_Oh:SetStatusBarColor(r,g,b)
	Abar_OhText:SetText(text)
	Abar_Oh:SetMinMaxValues(Abar_Oh.st,Abar_Oh.et)
	Abar_Oh:SetValue(Abar_Oh.st)
	Abar_Oh:Show()
end

function Abar_Boo(inpt)
	if inpt == true then return " ON" else return " OFF" end
end
