local Relic_Textures = {"Interface\\Icons\\Spell_Shadow_AntiMagicShell", 
			"Interface\\Icons\\Spell_Holy_Retribution",
			"Interface\\Icons\\Spell_Fire_BlueFlameRing",
			"Interface\\Icons\\Spell_Fire_Burnout"};
local Relic_Chain = {};
local Relic_Pylons = {{x=0.28802028, y=0.46441790}, {x=0.33408027, y=0.51853096}, {x=0.31756332, y=0.63748574}, {x=0.27402016, y=0.68555968}, {x=0.600241, y=0.09050513}, {x=0.64678496, y=0.10882642}, {x=0.69017606, y=0.13910073}};
local Relic_BEM = {28/100, 12.6/100, 47.2/100, 39.2/100};

local Relic_lang = {};
setmetatable(Relic_lang,{__index=function(t, id)
 local lo, ld = _G["Relic_Language_" .. GetLocale()], Relic_Language_enUS;
 if lo and lo[id] then t[id] = lo[id];
 elseif ld and ld[id] then t[id] = ld[id];
 else t[id] = "#NOLOC#" .. id .. "#";
 end
 return t[id];
end});

local Relic_DebuffExpire = 0;

function Relic_InZone()
 SetMapZoom(3);
 local x, y = GetPlayerMapPosition("player");
 return x > Relic_BEM[1] and x < Relic_BEM[3] and y > Relic_BEM[2] and y < Relic_BEM[3];
end
local function Relic_InRange()
 SetMapToCurrentZone();
 local x, y, d = GetPlayerMapPosition("player");
 for i=1,#Relic_Pylons do
  d = ((Relic_Pylons[i].x - x)^2 + (Relic_Pylons[i].y - y)^2)^0.5
  if d <= 0.009 then
   return true;
  end
 end
 return false;
end

local function Relic_UpdateUI()
 local bo;
 for i=1,#Relic_Chain do
  bo = _G["Relic_View_Replay" .. i .. "Tex"];
  if bo then
   bo:SetTexture(Relic_Textures[Relic_Chain[i]]);
   bo:GetParent():Show();
   bo:GetParent().toolHeader = Relic_lang.colors[Relic_Chain[i]];
   bo:GetParent().toolText = Relic_lang.remove;
  end
 end
 for i=#Relic_Chain+1,10 do
  _G["Relic_View_Replay" .. i]:Hide();
 end
end

local function Relic_ShiftRight()
 if #Relic_Chain > 0 then
  for i=1,#Relic_Chain do
   Relic_Chain[i] = Relic_Chain[i+1];
  end
  Relic_UpdateUI();
 end
end

local function Relic_Click(self)
 local id = self:GetID();
 if id > 0 and id < 5 then
  tinsert(Relic_Chain, id);
 end
 Relic_UpdateUI();
end
local function Relic_SubClick(self, button)
 local id = self:GetID();
 if button == "LeftButton" then
  tremove(Relic_Chain, id);
 elseif button == "RightButton" then
  for i=id,#Relic_Chain do 
   tremove(Relic_Chain, id); -- well, not quite the right mechanic, but the right effect.
  end
 end
 Relic_UpdateUI();
end

local function Relic_BindKeys(self)
 for i=1,4 do
  SetOverrideBindingClick(self, 1, Relic_lang.colorKeys[i], "Relic_View_Set" .. i);
 end
end
local function Relic_UnBindKeys(self, event)
 if InCombatLockdown() then
  UIErrorsFrame:AddMessage(Relic_lang.unbinderror, 1, 0.3, 0);
  self:SetScript("OnEvent", Relic_UnBindKeys);
  return self:RegisterEvent("PLAYER_REGEN_ENABLED");
 elseif event == "PLAYER_REGEN_ENABLED" then
  self:UnregisterEvent(event);
  self:SetScript("OnEvent", nil);
 end
 ClearOverrideBindings(self);
end

local function Relic_GossipOption(index) -- posthook for SelectGossipOption
 if (index == 1) then
  SetMapToCurrentZone(); -- Hopefully they won't notice!
  if GetCurrentMapContinent() == 3 and Relic_InZone() and Relic_InRange() then -- We're in one of the pylon camps at Blade's Edge; there's nothing but the relics to gossip to
   Relic_View:Show();
  end
 end
end
local function Relic_BuffUpdate(self)
 if (self.nU or 0) > GetTime() then
  return;
 end
 self.nU = GetTime() + 0.2;

 local i=1;
 while 1 do
  local bi = GetPlayerBuff(i, "HARMFUL");
  if bi == nil or bi == 0 then
   break;
  end
  local dT, dL = GetPlayerBuffTexture(bi), GetPlayerBuffTimeLeft(bi);
  if dT == "Interface\\Icons\\Spell_Arcane_Arcane02" then
   local eT = GetTime() + dL;
   if eT > (Relic_DebuffExpire+0.3) then
    Relic_DebuffExpire = eT;
    Relic_ShiftRight();
   end
   return;
  end
  i = i + 1;
 end
end

local bo;
for i=1,4 do
 bo = _G["Relic_View_Set" .. i .. "Tex"]
 if bo then 
  bo:SetTexture(Relic_Textures[i]);
  bo:GetParent():SetScript("OnClick", Relic_Click);
  bo:GetParent().toolHeader, bo:GetParent().toolText = string.format(Relic_lang.colorClick,Relic_lang.colors[i]), string.format(Relic_lang.colorHotkey,Relic_lang.colorKeys[i]);
 end
end

if Relic_View then 
 Relic_View:SetBackdropBorderColor(0.6,0.6,0.6); 
 Relic_View:SetScript("OnShow", Relic_BindKeys);
 Relic_View:SetScript("OnUpdate", Relic_BuffUpdate);
 Relic_View:SetScript("OnHide", Relic_UnBindKeys);
 Relic_ViewCaption:SetText(Relic_lang.caption);
 hooksecurefunc("SelectGossipOption", Relic_GossipOption);
 for i=1,10 do
  _G["Relic_View_Replay" .. i]:SetScript("OnClick", Relic_SubClick);
  _G["Relic_View_Replay" .. i]:RegisterForClicks("LeftButtonUp", "RightButtonUp");
 end
end

SLASH_RELIC1 = "/ogri";
SLASH_RELIC2 = "/relic";
SlashCmdList["RELIC"] = function(msg)
 if Relic_View then
  if Relic_View:IsShown() then
   Relic_View:Hide();
  else
   Relic_View:Show();
  end
 end
end