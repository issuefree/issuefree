require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Malphite")

InitAAData({
   extraRange=5,
   particles={"Malphite_Base_CleaveHit"}
})

AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["shard"] = {
   key="Q", 
   range=625, 
   color=violet, 
   base={70,120,170,220,270},
   ap=.6,
   type="M",
   cost={70,75,80,85,90}
} 
spells["strikes"] = {
   key="W",
   base={25,40,55,70,85},
   ap=.15,
   cost=25,
} 
spells["slam"] = {
   key="E", 
   range=400-10, 
   color=yellow, 
   base={60,100,140,180,220}, 
   ap=.2,
   armor=.3,
   cost={50,55,60,65,70}
} 
spells["force"] = {
   key="R", 
   range=1000, 
   color=red, 
   base={200,300,400}, 
   ap=1,
   delay=.2,
   speed=1800,
   radius=300,
   cost=100
} 

spells["AA"].bonus = 
   function()
      if P.strikes then
         return GetSpellDamage("strikes")
      end
   end



function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important

   if IsOn("lasthit") then
      if KillMinionsInPB("slam") then
         return true
      end
   end

   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   if CastBest("shard") then
      return true
   end
   if #GetInRange(me, "slam", ENEMIES) > 0 then
      if CanUse("strikes") then
         Cast("strikes", me)
         PrintAction("Strikes!", nil, 1)
      end

      if CanUse("slam") then
         Cast("slam", me)
         PrintAction("SLAM")
         return true
      end

   end


   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()

   return false
end

local function onCreate(object)
   PersistBuff("strikes", object, "Malphite_Base_Enrage_buf.troy")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

