require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Azir")

InitAAData({ 
   speed=1500,
   particles = {"Azir_Base_BA_Beam.troy"} 
})

-- SetChampStyle("marksman")
-- SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "soldier"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["conquer"] = {
   key="Q", 
   range=875, 
   color=yellow, 
   base={65,85,105,125,145}, 
   ap=.5,
   delay=.24,
   speed=1200,
   width=80,
   cost=70,
} 
spells["arise"] = {
   key="W", 
   range=450, -- + 50?
   color=violet,

   delay=.24, -- TODO
   speed=0,
   radius=250, -- hacky
   noblock=true,

   base=0,
   bonus=function() 
            local dam = {50,55,60,65,70,75,80,85,90,95,100,110,120,130,140,150,160,170}
            return dam[me.level]
         end,
   ap=.6,

   useCharges=true,
   maxCharges=2,
   rechargeTime={12,11,10,9,8},
   charges=1,
   cost=40,
} 
spells["soldier"] = {
   range=310, 
   base=0,
   bonus=function() 
            local dam = {50,55,60,65,70,75,80,85,90,95,100,110,120,130,140,150,160,170}
            return dam[me.level]
         end,
   ap=.7,
}
spells["shifting"] = {
   key="E", 
   range=1100,
   base={80,100,140,180,220}, 
   ap=.4,
   width=150,
   cost=60,
} 
spells["divide"] = {
   key="R", 
   range=250, 
   color=violet, 
   base={150,225,300}, 
   ap=.6,
   cost=100,
} 

local soldiers = {}

function Run()
   soldiers = GetPersisted("soldier")

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   -- if CheckDisrupt("binding") then
   --    return true
   -- end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then
      if Alone() then
         if CanUse("arise") and spells["arise"].charges == 2 then
            local hits, kills = GetBestArea(me, "arise", 1, 1, MINIONS)
            if #hits >= 2 and #kills >= 1 then
               CastXYZ("arise", GetCastPoint(hits, "arise"))
               return true
            end
         end
      end
   end

   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   if IsOn("lasthit") and Alone() then
      if CanAttack() then
         for _,soldier in ipairs(soldiers) do
            local target = SortByHealth(GetKills("soldier", GetInRange(soldier, "soldier", MINIONS)), "soldier")[1]
            if AA(target) then
               PrintAction("Soldier hit for LH")
               return true
            end
         end
      end
   end

   EndTickActions()
end

function Action()

   local targets = {}
   for _,soldier in ipairs(soldiers) do
      targets = merge(targets, GetInRange(soldier, "soldier", ENEMIES))
   end

   SortByHealth(targets, "soldier")   

   if CanUse("arise") then
      if #targets == 0 or spells["arise"].charges == 2 then
         local target = GetWeakestEnemy("arise", spells["soldier"].range-50)
         if target then
            CastFireahead("arise", target)
            PrintAction("Arise", target)
            return true
         end
      end
   end

   if CanUse("conquer") and #soldiers > 0 and #targets == 0 then
      local target = GetWeakestEnemy("conquer")
      if target then
         local soldier = SortByDistance(soldiers, target)[1]
         CastXYZ("conquer", OverShoot(soldier, target, 150))
         PrintAction("Conquer", target)
         return true
      end
   end

   if AA(targets[1]) then
      PrintAction("Remote AA", targets[1])
      return true
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   -- local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
   return false
end

local function onCreate(object)
   PersistAll("soldier", object, "Azir_Base_P_Soldier_Ring")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

