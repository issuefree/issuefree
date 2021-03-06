require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Kayle")

InitAAData({
  speed = 1800,
  particles = {"RighteousFury_nova"}
})

AddToggle("ult", {on=true, key=112, label="Auto Ult"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["reckoning"] = {
  key="Q", 
  range=650, 
  color=violet, 
  base={60,110,160,210,260}, 
  ap=.6,
  adBonus=1,
  cost={70,75,80,85,90}
}
spells["blessing"] = {
  key="W", 
  range=900, 
  color=green, 
  base={60,105,150,195,240}, 
  ap=.45,
  cost={60,70,80,90,100}
}
spells["fury"] = {
  key="E", 
  range=525+110, 
  color=red,
  base={20,30,40,50,60},
  ap=.25,
  cost=45
}
spells["intervention"] = {
  key="R", 
  range=900, 
  color=yellow,
  cost=0,
}

-- reckoning is pretty spammable, so spam it.
-- if people are in range and fury is off, turn it on
-- intervention is hard to use safely, might try something like
--   if someone is under 25% and becomes the target of an enemy ability intervene

function Run()

   if P.fury then
      spells["AA"].bonus = GetSpellDamage("fury")
   else
      spells["AA"].bonus = 0
   end

   if StartTickActions() then
      return true
   end


   if IsOn("ult") and CanUse("intervention") then
      local targets = GetInRange(me, "intervention", ALLIES)
      local bestT
      local bestP
      for _,target in ipairs(targets) do
         local tp = GetHPerc(target)
         if tp < .2 and #GetInRange(target, 500, ENEMIES) > 0 then
            if not bestT or tp < bestP then
               bestT = target
               bestP = tp
            end
         end
      end
      if bestT then
         Cast("intervention", bestT)
         PrintAction("Save", bestT)
         return true
      end
   end

   -- high priority hotkey actions, e.g. killing enemies
   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end

   -- auto stuff that should happen if you didn't do something more important

   
   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   if CastBest("reckoning") then
      return true
   end

   if CanUse("fury") then
      if GetWeakestEnemy("fury") then
         Cast("fury", me)
         PrintAction("Fury!")
         return true
      end
   end
   
   local target
   if IsMelee() then
      target = GetMarkedTarget() or GetMeleeTarget()
   else
      target = GetMarkedTarget() or GetWeakestEnemy("AA")
   end
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
   -- if IsOn("move") then
   --    if MeleeMove() then
   --       return true
   --    end
   -- end
   return false
end


local function onObject(object)
   PersistBuff("fury", object, "RighteousFuryHalo")
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)
