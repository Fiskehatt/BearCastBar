SLASH_BCB1, SLASH_BCB2  = '/bcb', '/bear';

local bcb = {}
local oldUseAction
local safeZone= 0.1
local barHeight = 28
local CUSTOM_TEXTURE_PATH = "Interface\\AddOns\\BearCastBar\\textures\\"

local BCB_DEFAULTS = {}
BCB_DEFAULTS.width = 255
BCB_DEFAULTS.height = 32
BCB_DEFAULTS.heightMin = 24
BCB_DEFAULTS.heightMax = 100
BCB_DEFAULTS.widthMin = 50
BCB_DEFAULTS.widthMax = 600
BCB_DEFAULTS.lagProtectionMin = 0
BCB_DEFAULTS.lagProtectionMax = 200
BCB_DEFAULTS.lagProtection = 0.1
BCB_DEFAULTS.customCastBarTexture = "flat"
BCB_DEFAULTS.barColor = {r=0.75, g=.5, b=0, a=1.0} --0.75, .5, 0, 1.0

bcb.frame = CreateFrame("FRAME", "BearCastBar", UIParent)
bcb.frame:SetScript("OnEvent", function() bcb[event](bcb, arg1, arg2) end)
bcb.frame:SetScript("OnUpdate", function() bcb["OnUpdate"]() end)
bcb.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
bcb.frame:RegisterEvent("ADDON_LOADED")

BearCastBar.L = setmetatable({}, {__index = function(t, k)
	local v = tostring(k)
	rawset(t, k, v)
	return v
end})
local L = BearCastBar.L

function SlashCmdList.BCB(msg, editbox)
    
    bcb.configFrame:Show()

end;

function bcb:OnUpdate()
    if(bcb.casting) then
        local currentTime = GetTime()
        local currentCastTime = currentTime - bcb.bar.startTime
        local negativeCastTime = bcb.bar.duration - currentCastTime
        local currentBarPosition = (bcb.bar.duration - currentCastTime)/bcb.bar.duration

        bcb.frame.timerFrame:SetText(string.format("%." .. (1) .. "f", negativeCastTime)) --string.format("%." .. (1) .. "f", num)sss

        local w

        if(bcb.channeled) then
            currentBarPosition = (bcb.bar.remaining - currentCastTime)/bcb.bar.duration
            negativeCastTime = bcb.bar.remaining - currentCastTime
            bcb.frame.timerFrame:SetText(string.format("%." .. (1) .. "f", negativeCastTime))
            w = (BCB_SAVED.width*currentBarPosition);
        else
            w = BCB_SAVED.width-(BCB_SAVED.width*currentBarPosition);
        end

        if(w > BCB_SAVED.width) then
            bcb.debug("         OnUpdate - set all to false, hide frame. cast finished")

            bcb.casting = false
            bcb.delayed = false
            bcb.canceled = false
            bcb.frame:Hide()
        end

        w = math.min(w, BCB_SAVED.width)

        bcb.bar:SetWidth(w)
        --bcb.bar:Show()
    end

    if(bcb.casting and bcb.delayed) then
        bcb.lagBar:SetWidth(1)  
    end
end

function bcb.UseAction(slot, checkCursor, onSelf) --hook into action bar

    bcb.debug(" + UseAction")

      --dont want to include trinkets or arcane power
    if(bcb.casting and bcb.delayed == false) then
        --check if we are in the lag zone to recast
        if (bcb.bar.trueStartTime + BCB_SAVED.lagProtection + bcb.bar.duration) < GetTime() and not(bcb.channeled) then
            SpellStopCasting()
            bcb.debug("         UseAction - Setting casting to false, cast duration exeeded")

            bcb.casting = false

            bcb.debug("         UseAction - Getting client start time")
            

            if(ActionHasRange(slot)) then
                bcb.bar.clientStartTime = GetTime()
            else                    
                bcb.bar.clientStartTime = 0
            end

            bcb.canceled = true
            bcb.debug("         UseAction - Setting canceled to true, cast duration exeeded")
        end
    end

    
    oldUseAction(slot, checkCursor, onSelf)
    
end

function bcb.ShowColorPicker(r, g, b, a, changedCallback)
    ColorPickerFrame:SetColorRGB(r,g,b);
    ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a;
    ColorPickerFrame.previousValues = {r,g,b,a};
    ColorPickerFrame:SetFrameStrata("High")
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = 
    changedCallback, changedCallback, changedCallback;
    ColorPickerFrame:Hide(); -- Need to run the OnShow handler.
    ColorPickerFrame:Show();
end

function bcb.ColorWheelCallback(restore)

    local newR, newG, newB, newA;
    if restore then
    -- The user bailed, we extract the old color from the table created by ShowColorPicker.
        newR, newG, newB, newA = unpack(restore);
    else
    -- Something changed
        newA, newR, newG, newB = OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB();
    end

    -- Update our internal storage.
    BCB_SAVED.barColor.r = newR
    BCB_SAVED.barColor.g = newG
    BCB_SAVED.barColor.b = newB
    BCB_SAVED.barColor.a = newA

    -- And update any UI elements that use this color...
    bcb.bar.texture:SetVertexColor(BCB_SAVED.barColor.r, BCB_SAVED.barColor.g, BCB_SAVED.barColor.b, BCB_SAVED.barColor.a)

--    bcb.bar.texture:SetVertexColor(BCB_SAVED.barColor.r, BCB_SAVED.barColor.g, BCB_SAVED.barColor.b, BCB_SAVED.barColor.a)

end

function bcb:ADDON_LOADED(name)
    
    if(name == "BearCastBar") then
        if(BCB_SAVED == nil) then
            BCB_SAVED = {}
            BCB_SAVED.BearCastBarPoint = "CENTER"
            BCB_SAVED.BearCastBarRelativeTo = UIParent
            BCB_SAVED.BearCastBarRelativePoint = "CENTER" 
            BCB_SAVED.BearCastBarxOfs, BCB_SAVED.BearCastBaryOfs = 0;
            BCB_SAVED.height = BCB_DEFAULTS.height
            BCB_SAVED.width = BCB_DEFAULTS.width
            BCB_SAVED.lagProtection = BCB_DEFAULTS.lagProtection
            BCB_SAVED.customCastBarTexture = BCB_DEFAULTS.customCastBarTexture
            BCB_SAVED.barColor = BCB_DEFAULTS.barColor
            BCB_SAVED.debug = false
            BCB_SAVED.abar_is_enabled = true
            BCB_SAVED.hunter_is_enabled = true

            bcb.debug("Variable load failed. Using defaults.")
        end

        if(BCB_SAVED.BearCastBarPoint == nil) then
            BCB_SAVED.BearCastBarPoint = "CENTER"
        end

        if(BCB_SAVED.BearCastBarRelativeTo == nil) then
            BCB_SAVED.BearCastBarRelativeTo = UIParent
        end

        if(BCB_SAVED.BearCastBarRelativePoint == nil) then
            BCB_SAVED.BearCastBarRelativePoint = "CENTER" 
        end

        if(BCB_SAVED.BearCastBarxOfs == nil) then
            BCB_SAVED.BearCastBarxOfs = 0 
        end

        if(BCB_SAVED.BearCastBaryOfs == nil) then
            BCB_SAVED.BearCastBaryOfs = 0 
        end

        if(BCB_SAVED.lagProtection == nil) then
            BCB_SAVED.lagProtection = BCB_DEFAULTS.lagProtection
        end
        
        if(BCB_SAVED.customCastBarTexture == nil) then
            BCB_SAVED.customCastBarTexture = BCB_DEFAULTS.customCastBarTexture
        end
  
        if(BCB_SAVED.barColor == nil) then
            BCB_SAVED.barColor = BCB_DEFAULTS.barColor
        end   
        
        if(BCB_SAVED.debug == nil) then
            BCB_SAVED.debug = false
        end
        
        if(BCB_SAVED.abar_is_enabled == nil) then
            BCB_SAVED.abar_is_enabled = true
        end

        if(BCB_SAVED.hunter_is_enabled == nil) then
            BCB_SAVED.hunter_is_enabled = true
        end
        

    end    
end

function bcb:PLAYER_ENTERING_WORLD()
    this:RegisterEvent("SPELLCAST_START")
    this:RegisterEvent("SPELLCAST_CHANNEL_START")
    this:RegisterEvent("SPELLCAST_CHANNEL_STOP")
    this:RegisterEvent("SPELLCAST_CHANNEL_UPDATE")
    this:RegisterEvent("SPELLCAST_STOP")
    this:RegisterEvent("SPELLCAST_DELAYED")
    this:RegisterEvent("SPELLCAST_INTERRUPTED")--CHAT_MSG_SPELL_FAILED_LOCALPLAYER --SPELLCAST_CHANNEL_START
    this:RegisterEvent("CHAT_MSG_SPELL_FAILED_LOCALPLAYER")

    this:UnregisterEvent("PLAYER_ENTERING_WORLD")

    CastingBarFrame:Hide()
    CastingBarFrame:UnregisterAllEvents()

    --- config frame

    self.configFrame = CreateFrame("FRAME", "BearCastBar_ConfigFrame", UIParent)
		table.insert(UISpecialFrames, self.configFrame:GetName()) -- provides close frame on escape pressed
    self.configFrame:SetFrameStrata("LOW")
    self.configFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    self.configFrame:SetHeight(300)
    self.configFrame:SetWidth(500)
    self.configFrame:SetMovable(true)
    self.configFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
                                            edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
                                            tile = true, tileSize = 16, edgeSize = 16, 
                                            insets = { left = 4, right = 4, top = 4, bottom = 4 }});
    self.configFrame:SetBackdropBorderColor(1,1,1,.7);
    self.configFrame:SetBackdropColor(0,0,0,.7);
    self.configFrame:EnableMouse(true);
    self.configFrame:RegisterForDrag("LeftButton");

    self.configFrame:Hide()

    self.configFrameTitle = self.configFrame:CreateFontString("BearFont_BCBTitle", "OVERLAY", "GameFontHighlight")
    self.configFrameTitle:SetFont(GameFontNormal:GetFont(), 12, "")
    self.configFrameTitle:SetShadowOffset(1, -1)
    self.configFrameTitle:SetShadowColor(0,0,0,1.0)
    self.configFrameTitle:SetWidth(200)
    self.configFrameTitle:SetHeight(16)
    self.configFrameTitle:SetText(L["BearCastBar Options"])
    self.configFrameTitle:SetPoint("TOP",self.configFrame,0,-8)
    self.configFrameTitle:Show()
    self.configFrameTitle:SetParent(self.configFrame)


    self.configFrame.closeButton = CreateFrame("BUTTON", nil, self.configFrame, "UIPanelCloseButton") 
    self.configFrame.closeButton:SetPoint("TOPRIGHT", self.configFrame, 0,0)

    self.configFrame.closeButton:SetScript("OnClick", function(self, button, down)
        bcb.configFrame:Hide()
    end)


    --resizing

    self.configFrame.resizeFrame = CreateFrame("FRAME", nil, self.configFrame)
    self.configFrame.resizeFrame:SetFrameStrata("LOW")
    self.configFrame.resizeFrame:SetPoint("TOPLEFT", self.configFrame, "TOPLEFT", 4, -26)
    self.configFrame.resizeFrame:SetHeight(270)
    self.configFrame.resizeFrame:SetWidth(248)
    self.configFrame.resizeFrame:SetMovable(true)
    self.configFrame.resizeFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
                                            edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
                                            tile = true, tileSize = 16, edgeSize = 16, 
                                            insets = { left = 4, right = 4, top = 4, bottom = 4 }});
    self.configFrame.resizeFrame:SetBackdropBorderColor(1,1,1,.5);
    self.configFrame.resizeFrame:SetBackdropColor(0,0,0,1);

    self.configFrame.resizeFrame.title = self.configFrame:CreateFontString("BearFont_BCBTitle2", "OVERLAY", "GameFontHighlight")
    self.configFrame.resizeFrame.title:SetFont(GameFontNormal:GetFont(), 10, "")
    self.configFrame.resizeFrame.title:SetShadowOffset(1, -1)
    self.configFrame.resizeFrame.title:SetShadowColor(0,0,0,1.0)
    --self.configFrame.resizeFrame.title:SetWidth(200)
    --self.configFrame.resizeFrame.title:SetHeight(16)
    self.configFrame.resizeFrame.title:SetText(L["Cast bar"])
    self.configFrame.resizeFrame.title:SetPoint("TOPLEFT",self.configFrame.resizeFrame,10,-10)
    self.configFrame.resizeFrame.title:Show()
    self.configFrame.resizeFrame.title:SetParent(self.configFrame.resizeFrame)    

    self.configFrame.resizeFrame.heightSlider = CreateFrame("Slider", "BCB_HeightSlider", self.configFrame.resizeFrame, "OptionsSliderTemplate")
    self.configFrame.resizeFrame.heightSlider:SetWidth(228)
    self.configFrame.resizeFrame.heightSlider:SetHeight(18)
    self.configFrame.resizeFrame.heightSlider:SetOrientation("HORIZONTAL")
    self.configFrame.resizeFrame.heightSlider:SetPoint("TOPLEFT", self.configFrame.resizeFrame, 10,-40)
    self.configFrame.resizeFrame.heightSlider:SetMinMaxValues(BCB_DEFAULTS.heightMin,BCB_DEFAULTS.heightMax)
    self.configFrame.resizeFrame.heightSlider:SetValue(BCB_SAVED.height)
    self.configFrame.resizeFrame.heightSlider:SetValueStep(1)
    getglobal('BCB_HeightSliderLow'):SetText(BCB_DEFAULTS.heightMin);
    getglobal('BCB_HeightSliderHigh'):SetText(BCB_DEFAULTS.heightMax);
    getglobal('BCB_HeightSliderText'):SetText(L["Height"].." "..BCB_SAVED.height);
    self.configFrame.resizeFrame.heightSlider:SetScript("OnValueChanged", function(self, value) 
        bcb.setHeight(bcb.configFrame.resizeFrame.heightSlider:GetValue())
    end)

    self.configFrame.resizeFrame.widthSlider = CreateFrame("Slider", "BCB_WidthSlider", self.configFrame.resizeFrame, "OptionsSliderTemplate")
    self.configFrame.resizeFrame.widthSlider:SetWidth(228)
    self.configFrame.resizeFrame.widthSlider:SetHeight(18)
    self.configFrame.resizeFrame.widthSlider:SetOrientation("HORIZONTAL")
    self.configFrame.resizeFrame.widthSlider:SetPoint("TOPLEFT", self.configFrame.resizeFrame, 10,-84)
    self.configFrame.resizeFrame.widthSlider:SetMinMaxValues(BCB_DEFAULTS.widthMin,BCB_DEFAULTS.widthMax)
    self.configFrame.resizeFrame.widthSlider:SetValue(BCB_SAVED.width)
    self.configFrame.resizeFrame.widthSlider:SetValueStep(1)
    getglobal('BCB_WidthSliderLow'):SetText(BCB_DEFAULTS.widthMin);
    getglobal('BCB_WidthSliderHigh'):SetText(BCB_DEFAULTS.widthMax);
    getglobal('BCB_WidthSliderText'):SetText(L["Width"].." "..BCB_SAVED.width); 
    self.configFrame.resizeFrame.widthSlider:SetScript("OnValueChanged", function(self, value) 
        bcb.setWidth(bcb.configFrame.resizeFrame.widthSlider:GetValue())
    end)


    local lp = BCB_SAVED.lagProtection*1000
    self.configFrame.resizeFrame.lagProtection = CreateFrame("Slider", "BCB_LagProtectionSlider", self.configFrame.resizeFrame, "OptionsSliderTemplate")
    self.configFrame.resizeFrame.lagProtection:SetWidth(228)
    self.configFrame.resizeFrame.lagProtection:SetHeight(18)
    self.configFrame.resizeFrame.lagProtection:SetOrientation("HORIZONTAL")
    self.configFrame.resizeFrame.lagProtection:SetPoint("TOPLEFT", self.configFrame.resizeFrame, 10,-128)
    self.configFrame.resizeFrame.lagProtection:SetMinMaxValues(BCB_DEFAULTS.lagProtectionMin,BCB_DEFAULTS.lagProtectionMax)
    self.configFrame.resizeFrame.lagProtection:SetValue(lp)
    self.configFrame.resizeFrame.lagProtection:SetValueStep(1)
    self.configFrame.resizeFrame.lagProtection.tooltipText = L["If your connection is stable set this as close to 0ms as possible.\n\nIf your casts are not going through, set this higher until you can cast reliably.\n\n100ms recommended for average connections."]
    getglobal('BCB_LagProtectionSliderLow'):SetText(BCB_DEFAULTS.lagProtectionMin);
    getglobal('BCB_LagProtectionSliderHigh'):SetText(BCB_DEFAULTS.lagProtectionMax);
    local lp = BCB_SAVED.lagProtection*1000
    getglobal('BCB_LagProtectionSliderText'):SetText(format(L["Lag protection %dms"], lp)); 
    self.configFrame.resizeFrame.lagProtection:SetScript("OnValueChanged", function(self, value) 
        bcb.setLagProtection(bcb.configFrame.resizeFrame.lagProtection:GetValue())
    end)



    --custom texture options
    self.configFrame.customTextureLabel = self.configFrame:CreateFontString("BCB_ConfigFont", "OVERLAY", "GameFontHighlight")
    self.configFrame.customTextureLabel:SetFont(GameFontNormal:GetFont(), 10, "")
    self.configFrame.customTextureLabel:SetShadowOffset(1, -1)
    self.configFrame.customTextureLabel:SetShadowColor(0,0,0,1.0)
    self.configFrame.customTextureLabel:SetWidth(230)
    self.configFrame.customTextureLabel:SetHeight(64)
		self.configFrame.customTextureLabel:SetText("|cffFFD800"..format(L["Place custom textures in: \n%s \n\nType filename without extension. Eg \"flat\""], "Interface/AddOns/BearCastBar/textures"))
    self.configFrame.customTextureLabel:SetJustifyH("LEFT")
    self.configFrame.customTextureLabel:SetJustifyV("BOTTOM")
    self.configFrame.customTextureLabel:SetPoint("TOPLEFT",self.configFrame.resizeFrame.lagProtection,0,-10)
    self.configFrame.customTextureLabel:Show()
    self.configFrame.customTextureLabel:SetParent(self.configFrame.resizeFrame)

    self.configFrame.customTextureApplyButton = CreateFrame("BUTTON", nil, self.configFrame, "UIPanelButtonTemplate") 
    self.configFrame.customTextureApplyButton:SetPoint("TOPRIGHT", self.configFrame.customTextureLabel, "BOTTOMRIGHT", 0,-4)
    self.configFrame.customTextureApplyButton:SetFrameStrata("MEDIUM")
    self.configFrame.customTextureApplyButton:SetText(L["Apply"])
    self.configFrame.customTextureApplyButton:SetHeight(26)
    self.configFrame.customTextureApplyButton:SetWidth(self.configFrame.customTextureApplyButton:GetFontString():GetStringWidth() + 14)

    -- apply new custom texture to bar
    self.configFrame.customTextureApplyButton:SetScript("OnClick", function(self, button, down)
        BCB_SAVED.customCastBarTexture = bcb.configFrame.customTextureEditBox:GetText()
        
        bcb.bar.texture:SetTexture(CUSTOM_TEXTURE_PATH..BCB_SAVED.customCastBarTexture)
				bcb.configFrame.customTextureEditBox:ClearFocus()

    end)
		
    self.configFrame.customTextureEditBox = CreateFrame("EDITBOX", nil, self.configFrame)
    self.configFrame.customTextureEditBox:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
                                            edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
                                            tile = true, tileSize = 16, edgeSize = 16, 
                                            insets = { left = 4, right = 4, top = 4, bottom = 4 }});
    self.configFrame.customTextureEditBox:SetAutoFocus(false)                                     
    self.configFrame.customTextureEditBox:SetBackdropBorderColor(.5,.5,.5,1);
    self.configFrame.customTextureEditBox:SetBackdropColor(0,0,0,1);   
    self.configFrame.customTextureEditBox:SetTextInsets(8,8,0,0)                                        
    self.configFrame.customTextureEditBox:SetPoint("RIGHT", self.configFrame.customTextureApplyButton, "LEFT", 0, 0)
    self.configFrame.customTextureEditBox:SetFont(GameFontNormal:GetFont(), 10, "")
    self.configFrame.customTextureEditBox:SetHeight(28)
    self.configFrame.customTextureEditBox:SetWidth(235 - self.configFrame.customTextureApplyButton:GetWidth())
    self.configFrame.customTextureEditBox:SetText(BCB_SAVED.customCastBarTexture)
    self.configFrame.customTextureEditBox:SetFrameStrata("MEDIUM")
		self.configFrame.customTextureEditBox:SetScript('OnEditFocusGained', function()
			this:HighlightText()
		end)
		self.configFrame.customTextureEditBox:SetScript('OnEscapePressed', function()
			this:SetText(BCB_SAVED.customCastBarTexture)
			this:ClearFocus()
		end)
		self.configFrame.customTextureEditBox:SetScript('OnEnterPressed', function()
			BCB_SAVED.customCastBarTexture = this:GetText()
			bcb.bar.texture:SetTexture(CUSTOM_TEXTURE_PATH..BCB_SAVED.customCastBarTexture)
			this:ClearFocus()
		end)

    -- end custom texture options




    --set custom color button

    self.configFrame.colorWheelButton = CreateFrame("BUTTON", nil, self.configFrame, "UIPanelButtonTemplate") 
    self.configFrame.colorWheelButton:SetPoint("BOTTOMLEFT", self.configFrame.resizeFrame, 8,8)
    self.configFrame.colorWheelButton:SetHeight(26)
    self.configFrame.colorWheelButton:SetWidth(90)
    self.configFrame.colorWheelButton:SetText(L["Set Colour"])

    self.configFrame.colorWheelButton:SetScript("OnClick", function(self, button, down)
        
        bcb.ShowColorPicker(BCB_SAVED.barColor.r, BCB_SAVED.barColor.g, BCB_SAVED.barColor.b, BCB_SAVED.barColor.a, bcb.ColorWheelCallback)


    end)






    --resize checkbox etc

    self.configFrame.resizeFrame.unlockCheckbox = CreateFrame("CheckButton", "bcb_GlobalCheckbox_Unlock", self.configFrame.resizeFrame, "UICheckButtonTemplate");
    self.configFrame.resizeFrame.unlockCheckbox:SetPoint("BOTTOM",self.configFrame.resizeFrame, -5, 5)
    bcb_GlobalCheckbox_UnlockText:SetText(L["Lock cast bar"])

    self.configFrame.resizeFrame.unlockCheckbox:SetChecked(true)

    
    self.configFrame.resizeFrame.unlockCheckbox:SetScript("OnClick", function()
          
        if self.configFrame.resizeFrame.unlockCheckbox:GetChecked() then
            -- lock bar
            self.frame:SetMovable(false);
            self.overlay:SetAlpha(0)
            self.overlay:Hide()
            self.overlay:SetMovable(false);
            self.overlay:EnableMouse(false)
        else
            -- unlock bar  
            self.frame:SetMovable(true);
            self.overlay:SetAlpha(1)
            self.overlay:Show()
            self.overlay:SetMovable(true);
            self.overlay:EnableMouse(true)
        end          
    end)

    self.configFrame:SetScript("OnDragStart", function() 
        bcb.configFrame:StartMoving() 
    end)
    self.configFrame:SetScript("OnDragStop", function()
        bcb.configFrame:StopMovingOrSizing(); 
    end)


    --self.configFrame.resizeFrame:Show()

    --end of main cast bar section


    --start attack bar config section
    self.configFrame.attackBarConfigFrame = CreateFrame("FRAME", nil, self.configFrame)
    self.configFrame.attackBarConfigFrame:SetFrameStrata("LOW")
    self.configFrame.attackBarConfigFrame:SetPoint("TOPRIGHT", self.configFrame, "TOPRIGHT", -4, -26)
    self.configFrame.attackBarConfigFrame:SetHeight(270)
    self.configFrame.attackBarConfigFrame:SetWidth(248)
    self.configFrame.attackBarConfigFrame:SetMovable(true)
    self.configFrame.attackBarConfigFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
                                            edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
                                            tile = true, tileSize = 16, edgeSize = 16, 
                                            insets = { left = 4, right = 4, top = 4, bottom = 4 }});
    self.configFrame.attackBarConfigFrame:SetBackdropBorderColor(1,1,1,.5);
    self.configFrame.attackBarConfigFrame:SetBackdropColor(0,0,0,1);


    self.configFrame.attackBarConfigFrame.title = self.configFrame:CreateFontString("BearFont_BCBTitle3", "OVERLAY", "GameFontHighlight")
    self.configFrame.attackBarConfigFrame.title:SetFont(GameFontNormal:GetFont(), 10, "")
    self.configFrame.attackBarConfigFrame.title:SetShadowOffset(1, -1)
    self.configFrame.attackBarConfigFrame.title:SetShadowColor(0,0,0,1.0)
    --self.configFrame.resizeFrame.title:SetWidth(200)
    --self.configFrame.resizeFrame.title:SetHeight(16)
    self.configFrame.attackBarConfigFrame.title:SetText(L["Attack timer bar"])
    self.configFrame.attackBarConfigFrame.title:SetPoint("TOPLEFT",self.configFrame.attackBarConfigFrame,10,-10)
    self.configFrame.attackBarConfigFrame.title:Show()
    self.configFrame.attackBarConfigFrame.title:SetParent(self.configFrame.attackBarConfigFrame)    

    self.configFrame.attackBarConfigFrame.unlockCheckbox = CreateFrame("CheckButton", "bcb_GlobalCheckbox_UnlockAttackBar", self.configFrame.attackBarConfigFrame, "UICheckButtonTemplate");
    self.configFrame.attackBarConfigFrame.unlockCheckbox:SetPoint("TOPLEFT",self.configFrame.attackBarConfigFrame, 10, -65)
    bcb_GlobalCheckbox_UnlockAttackBarText:SetText(L["Lock attack timer bar"])

    self.configFrame.attackBarConfigFrame.unlockCheckbox:SetChecked(true)

    
    self.configFrame.attackBarConfigFrame.unlockCheckbox:SetScript("OnClick", function()
          
        if self.configFrame.attackBarConfigFrame.unlockCheckbox:GetChecked() then
            -- lock bar
            SlashCmdList["ATKBAR"]("lock")
        else
            -- unlock bar  
            SlashCmdList["ATKBAR"]("unlock")
        end          
    end)

    -- disable attack bar

    self.configFrame.attackBarConfigFrame.disableCheckbox = CreateFrame("CheckButton", "bcb_GlobalCheckbox_DisableCheckbox", self.configFrame.attackBarConfigFrame, "UICheckButtonTemplate");
    self.configFrame.attackBarConfigFrame.disableCheckbox:SetPoint("TOPLEFT",self.configFrame.attackBarConfigFrame, 10, -35)
    bcb_GlobalCheckbox_DisableCheckboxText:SetText(L["Attack bar enabled"])

    if (BCB_SAVED.abar_is_enabled == true) then
        self.configFrame.attackBarConfigFrame.disableCheckbox:SetChecked(true)
    end 

    self.configFrame.attackBarConfigFrame.disableCheckbox:SetScript("OnClick", function()
          
        if self.configFrame.attackBarConfigFrame.disableCheckbox:GetChecked() then
            -- enable bar
            SlashCmdList["ATKBAR"]("enable")
        else
            -- disable bar 
            SlashCmdList["ATKBAR"]("disable")
        end      
    end)

    -- disable for hunters

    self.configFrame.attackBarConfigFrame.hunterCheckbox = CreateFrame("CheckButton", "bcb_GlobalCheckbox_HunterCheckbox", self.configFrame.attackBarConfigFrame, "UICheckButtonTemplate");
    self.configFrame.attackBarConfigFrame.hunterCheckbox:SetPoint("TOPLEFT",self.configFrame.attackBarConfigFrame, 10, -95)
    bcb_GlobalCheckbox_HunterCheckboxText:SetText(L["Hunter abilities enabled"])

    if (BCB_SAVED.hunter_is_enabled == true) then
        self.configFrame.attackBarConfigFrame.hunterCheckbox:SetChecked(true)
    end 

    self.configFrame.attackBarConfigFrame.hunterCheckbox:SetScript("OnClick", function()
            
        if self.configFrame.attackBarConfigFrame.hunterCheckbox:GetChecked() then
            -- enable bar
            SlashCmdList["ATKBAR"]("hunton")
        else
            -- disable bar 
            SlashCmdList["ATKBAR"]("huntoff")
        end      
    end)



-----------------------
    --- CAST BAR ---
-----------------------

    self.frame:SetWidth(BCB_SAVED.width+8)
    self.frame:SetHeight(BCB_SAVED.height+8)
    self.frame:SetPoint(BCB_SAVED.BearCastBarPoint, UIParent, BCB_SAVED.BearCastBarRelativePoint, BCB_SAVED.BearCastBarxOfs, BCB_SAVED.BearCastBaryOfs)
    self.frame:SetFrameStrata("BACKGROUND")
    self.frame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
                                            edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
                                            tile = true, tileSize = 16, edgeSize = 16, 
                                            insets = { left = 4, right = 4, top = 4, bottom = 4 }});
    self.frame:SetBackdropBorderColor(0,0,0,1);
    self.frame:SetBackdropColor(0,0,0,1);
    
    --overlay for dragging
    self.overlay = CreateFrame("FRAME", nil, UIParent)
    self.overlay:SetFrameStrata("DIALOG")
    self.overlay:SetAllPoints(self.frame)
    self.overlay.texture = self.overlay:CreateTexture(nil, "BACKGROUND")
    self.overlay.texture:SetTexture(1, 0, 0, 0)
    self.overlay.texture:SetAllPoints(self.overlay)
    self.overlay:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
                                            edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
                                            tile = true, tileSize = 16, edgeSize = 16, 
                                            insets = { left = 4, right = 4, top = 4, bottom = 4 }});
    self.overlay:SetBackdropColor(0,0,0,1);
    self.overlay:Hide()
    --self.frame.overlay:SetAlpha(0)



    local f = GameFontNormal:GetFont()


    --f:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE, MONOCHROME")

    self.fontSpell = self.frame:CreateFontString("BearFont")
    self.fontSpell:SetFont(f, 12, "")
    self.fontSpell:SetShadowOffset(1, -1)
    self.fontSpell:SetShadowColor(0,0,0,1.0)

    self.fontTimer = self.frame:CreateFontString("BearFont")
    self.fontTimer:SetFont(f, 12, "")
    self.fontTimer:SetShadowOffset(1, -1)
    self.fontTimer:SetShadowColor(0,0,0,1.0)
    --self.font:SetTextColor(1,0,0,1.0)

    self.frame.spellFrame = CreateFrame("BUTTON", "bcb_SpellFrame", self.frame)
    self.frame.spellFrame:SetFrameStrata("HIGH")
    self.frame.spellFrame:SetWidth(100)
    self.frame.spellFrame:SetHeight(barHeight)
    self.frame.spellFrame:SetFontString(self.fontSpell)
    self.frame.spellFrame:SetText("")
    self.frame.spellFrame:SetPoint("CENTER",-6,0)
    self.frame.spellFrame:Disable()

    self.frame.timerFrame = CreateFrame("BUTTON", "bcb_TimerFrame", self.frame)
    self.frame.timerFrame:SetFrameStrata("HIGH")
    self.frame.timerFrame:SetWidth(40)
    self.frame.timerFrame:SetHeight(barHeight)
    self.frame.timerFrame:SetFontString(self.fontTimer)
    self.frame.timerFrame:SetText("")
    self.frame.timerFrame:SetPoint("RIGHT",-6,0)
    self.frame.timerFrame:Disable()

    self.bar = CreateFrame("FRAME", nil, self.frame)
    self.bar:SetFrameStrata("LOW")
    self.bar:SetWidth(BCB_SAVED.width)
    self.bar:SetHeight(BCB_SAVED.height)

    --this.bar.texture = this.bar:CreateTexture(nil, "OVERLAY")
    self.bar.texture = bcb.bar:CreateTexture(nil, "BACKGROUND")

    if BCB_SAVED.customCastBarTexture then
        self.bar.texture:SetTexture(CUSTOM_TEXTURE_PATH..BCB_SAVED.customCastBarTexture)
    else
        self.bar.texture:SetTexture(1, 1, 1, 1.0)
    end

    --self.bar.texture:SetTexture(1, 1, 1, 1.0)
    self.bar.texture:SetVertexColor(BCB_SAVED.barColor.r, BCB_SAVED.barColor.g, BCB_SAVED.barColor.b, BCB_SAVED.barColor.a)
    self.bar.texture:SetAllPoints(bcb.bar)

    self.bar:SetPoint("LEFT",4,0)

    self.lagBar = CreateFrame("FRAME", nil, self.frame)
    self.lagBar:SetFrameStrata("HIGH")
    self.lagBar:SetWidth(50)
    self.lagBar:SetHeight(BCB_SAVED.height)

    self.lagBar.texture = bcb.bar:CreateTexture(nil, "HIGH")
    self.lagBar.texture:SetTexture(1.0, 0, 0, 0.5)

    self.lagBar.texture:SetAllPoints(bcb.lagBar)    

    self.lagBar:SetPoint("RIGHT",-4,0)

    
    self.overlay:RegisterForDrag("LeftButton");
    self.overlay:SetScript("OnDragStart", function() bcb.frame:StartMoving() end)
    local x
    self.overlay:SetScript("OnDragStop", function() bcb.frame:StopMovingOrSizing(); BCB_SAVED.BearCastBarPoint, x, BCB_SAVED.BearCastBarRelativePoint, BCB_SAVED.BearCastBarxOfs, BCB_SAVED.BearCastBaryOfs = bcb.frame:GetPoint();end)

    oldUseAction = UseAction
    UseAction = bcb.UseAction
   
    self.bar.duration = 0;
    self.bar.trueStartTime = 0;
    self.bar.clientStartTime = 0;
    self.canceled = false
    self.resetLag = false

    self.frame:Hide() --debugging

end

function bcb.setHeight(height)
    BCB_SAVED.height = height
    bcb.bar:SetHeight(BCB_SAVED.height)
    bcb.frame:SetHeight(BCB_SAVED.height+8)
    --bcb.frame.overlay:SetAllPoints(bcb.frame)
    getglobal('BCB_HeightSliderText'):SetText(L["Height"].." "..height);
    bcb.lagBar:SetHeight(BCB_SAVED.height)

end

function bcb.setWidth(width)
    BCB_SAVED.width = width
    bcb.bar:SetWidth(BCB_SAVED.width)
    bcb.frame:SetWidth(BCB_SAVED.width+8)
    --bcb.frame.overlay:SetAllPoints(bcb.frame)
    getglobal('BCB_WidthSliderText'):SetText(L["Width"].." "..width);

end

function bcb.setLagProtection(lp)
    BCB_SAVED.lagProtection = lp/1000
    getglobal('BCB_LagProtectionSliderText'):SetText(format(L["Lag protection %dms"], lp));

end

function bcb:SPELLCAST_START(spellName, duration)
    bcb.debug(" + SPELLCAST_START ("..spellName..")".." duration: "..duration)

    self.lagBar.texture:SetAlpha(1)

    --self.lagBar:SetAlpha(1)
    --self.lagBar.texture:SetTexture(1.0, 0, 0, 0.5)
    

    if(self.casting == false and self.resetLag) then
        self.bar.clientStartTime = 0
    end

    self.frame.spellFrame:SetText(spellName)

    local down, up, latency = GetNetStats()

    


    self.bar.duration = duration/1000
    self.bar.startTime = GetTime()

    --if(self.bar.clientStartTime == 0) then
    --    bcb.debug("         SPELLCAST_START - Using latency timing")
    --    self.bar.trueStartTime = self.bar.startTime - latency/1000
    --else
        bcb.debug("         SPELLCAST_START - Using client timing")
        self.bar.trueStartTime = self.bar.clientStartTime
        self.bar.clientStartTime = 0      
   -- end

    bcb.debug("         SPELLCAST_START - Setting casting to true")
    self.channeled = false;
    self.delayed = false
    self.casting = true;

    --if the start time is more than a GCD then something went wrong
    if(self.bar.trueStartTime+1.5 < self.bar.startTime) then
        self.bar.trueStartTime = self.bar.startTime - latency/1000
    end

    --bcb.debug("Latency is: "..latency)

    self.lag = (self.bar.startTime - self.bar.trueStartTime)-BCB_SAVED.lagProtection

    --bcb.debug("lag is: "..self.lag)
    self.lagBar:SetWidth(BCB_SAVED.width-((self.bar.duration - self.lag)/self.bar.duration)*BCB_SAVED.width)

    self.frame:Show()

end

function bcb:SPELLCAST_STOP(spellName)
    bcb.debug(" + SPELLCAST_STOP")



    if(self.canceled == true) then
        bcb.debug("         SPELLCAST_STOP - Setting canceled to false")
        self.canceled = false
    elseif(self.canceled == true and GetTime()-(self.bar.trueStartTime + self.bar.duration) > 0) then
        
        bcb.debug("this should activate on zhc")
        --self.resetLag = true

        --bcb.debug("Setting reset lag to true")      
        --self.resetLag = true
    end

    --fix for procs and channeled spells
    if(GetTime()-(self.bar.trueStartTime + self.bar.duration) > 0 and self.channeled == false) then
        
        bcb.debug("         SPELLCAST_STOP - Setting casting to false")
        
        self.casting = false;
        
        self.bar:SetWidth(0)
        --self.bar:Hide()
        self.frame:Hide()

    end

    --self.bar.duration = 0


end

function bcb:SPELLCAST_CHANNEL_START(duration, spellName)

    bcb.debug(" + SPELLCAST_CHANNEL_START")

    self.frame.spellFrame:SetText(spellName)

    self.channeled = true;

    self.bar.remaining = duration/1000
    self.bar.duration = duration/1000
    self.bar.startTime = GetTime()
    self.lag = 0
    self.casting = true;

    self.frame:Show()
    self.lagBar.texture:SetAlpha(0)



end

function bcb:SPELLCAST_CHANNEL_STOP()

    bcb.debug(" + SPELLCAST_CHANNEL_STOP")

    self.casting = false;

    self.bar:SetWidth(0)
    self.frame:Hide()

end

function bcb:SPELLCAST_CHANNEL_UPDATE(duration)

    bcb.debug(" + SPELLCAST_CHANNEL_UPDATE")

    local losttime = self.bar.duration - (GetTime() - self.bar.startTime) - duration/1000;

    self.bar.remaining = self.bar.remaining-losttime
end

function bcb:SPELLCAST_INTERRUPTED(spellName)
    bcb.debug(" + SPELLCAST_INTERRUPTED")

    self.casting = false;


    self.bar:SetWidth(0)
    self.lagBar:SetAlpha(0)
    self.frame:Hide()



end


function bcb:CHAT_MSG_SPELL_FAILED_LOCALPLAYER(spellName) --this is causing issues
   -- bcb.debug("Failed local")

   -- self.casting = false;

   -- self.bar:SetWidth(0)
   -- self.lagBar:SetAlpha(0)
    --self.frame:Hide()
end

function bcb:SPELLCAST_DELAYED(timeDelayed)
    bcb.debug(" + SPELLCAST_DELAYED")

    self.bar.duration = self.bar.duration + (timeDelayed/1000)

    self.delayed = true
    self.lagBar.texture:SetAlpha(0)
end



function bcb.debug(m)
    if(BCB_SAVED.debug) then
        DEFAULT_CHAT_FRAME:AddMessage(m, 0.0, 1.0, 0.0);
    end;
end;


--------------------------------
------- attack bar--------------
--------------------------------

bcb.attackBar = CreateFrame("FRAME", "BearAttackBar", UIParent)

bcb.attackBar:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
bcb.attackBar:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
bcb.attackBar:RegisterEvent("PLAYER_LEAVE_COMBAT")
bcb.attackBar:RegisterEvent("VARIABLES_LOADED")
bcb.attackBar:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")

--bcb.attackBar:SetScript("OnEvent", function() Abar_event(event); end)
--bcb.attackBar:SetScript("OnUpdate", function() Abar_Update() end)

--Abar_Mhr = CreateFrame("STATUSBAR", "BearAttackBar", bcb.attackBar)
--Abar_Oh = CreateFrame("STATUSBAR", "BearAttackBar", bcb.attackBar)
