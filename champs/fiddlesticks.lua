require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Fiddlesticks")
pp(" - dark wind on weakest")
pp(" - pause while draining")

InitAAData({
   speed = 1750,
   particles = {"FiddleSticks_cas", "FiddleSticks_mis", "FiddleSticksBasicAttack_tar"}
})

SetChampStyle("caster")

AddToggle("offense", {on=true, key=112, label="Offensive stance"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=false, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=115, label="Move"})

spells["fear"] = {
   key="Q", 
   range=525, 
   color=violet,
   cost=65
}
spells["drain"] = {
   key="W", 
   range=575,
   color=green,
   cost={80,105,130,155,180},   
   ap=.45,
   channel=true,
   name="DrainChannel",
   object="Drain.troy",
}
spells["wind"] = {
   key="E", 
   range=750, 
   bounceRange=450,
   bounces=6,
   color=red, 
   base={65,85,105,125,145},
   ap=.45,
   scale=function(target)
                  if IsMinion(target) then
                     return .5
                  end
               end,
   cost={50,70,90,110,130}
}
spells["crow"] = {
   key="R", 
   range=800, 
   color=yellow,
   cost=100,
   radius=600
}

-- block spells while drain is on
-- beep for good crowstorm
-- auto zhonias

function Run()
   if StartTickActions() then
      return true
   end

   if CheckDisrupt("wind") or
      CheckDisrupt("fear") 
   then
      return true
   end

	if HotKey() then
		if Action() then
			return
		end
	end

	-- always stuff here
   if IsOn("lasthit") then
      if Alone() then
         if CanUse("wind") then
            -- TODO lasthit for farming.
         end
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end

   EndTickActions()
end

function Action()
   --[[
   I want something like...
   Fear if I can. I want to target EADC and EAPC if they're in range otherwise whoever is weak
   Drain if I can. I should probably try to target whatever I feared but weak will probably do.
      I think I want this over wind as wind is longer range and I probably just feared them.
   --]]
   if IsOn("offense") then      
      if CanUse("fear") then
         local target = GetMarkedTarget() or 
                        GetWeakest("fear", GetInRange(me, GetSpellRange("fear")-150, {EADC, EAPC})) or 
                        GetWeakestEnemy("fear", -150, 50)

         if target then
            Cast("fear", target)
            PrintAction("Fear", target)
            return true
         end
      end

      if CanUse("drain") then
         -- might update this to target feared guys first
         local target = GetMarkedTarget() or GetWeakestEnemy("drain", 0, 50)
         if target then
            Cast("drain", target)
            PrintAction("Drain", target)
            return true
         end
      end
   end

   -- TODO add wind on minions / pets in order to harass
   if CastBest("wind") then
      return true
   end

   return false
end

function FollowUp()
   -- clear with wind if there's 3 or more
   if IsOn("clear") and Alone() and
      me.mana/me.maxMana > .5 
   then
      if CanUse("wind") then
         local minions = SortByHealth(GetInRange(me, "wind", MINIONS), "wind")
         if #minions > 2 then
            Cast("wind", minions[1])
            PrintAction("Dark wind clearing")
            return true
         end
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end

local function onObject(object)
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)
