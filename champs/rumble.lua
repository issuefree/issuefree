require "issuefree/timCommon"
require "issuefree/modules"


pp("\nTim's Rumble")

InitAAData({ 
})

SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "harpoon"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["flame"] = {
   key="Q", 
   range=600, 
   color=yellow, 
   base={25,45,65,85,105}, 
   ap=.33,
   cone=65,    --reticle
   noblock=true,
   scale=function(target)
      local scale = 1
      if dangerZone() then
         scale = scale + .5
      end
      if IsMinion(target) then
         scale = scale / 2
      end
      return scale
   end
} 
spells["shield"] = {
   key="W",
   range=25,
   base={50,80,110,140,170}, 
   ap=.4,
   scale=function(target)
      if dangerZone() then
         return 1.5
      end
   end
} 
spells["harpoon"] = {
   key="E", 
   range=850, 
   color=violet, 
   base={45,70,95,120,145}, 
   ap=.4,
   delay=.24,  --tss
   speed=2000,   --tss
   width=100,  --reticle
   scale=function(target)
      if dangerZone() then
         return 1.5
      end
   end
} 
spells["equalizer"] = {
   key="R", 
   range=1700, 
   color=red, 
   base={650,925,1000}, 
   ap=1.5,
   delay=.5,       --TODO
   speed=0,
   cost={10,20,30,40,50}
} 
spells["equalizerLine"] = {
   range=1000,
   base={650,925,1000}, 
   ap=1.5,
   width=200,
}

spells["overheating"] = {
   base=20,
   lvl=5,
   ap=.25
}
spells["AA"].bonus = 
   function()
      if P.overheating then
         return GetSpellDamage("overheating")
      end
   end

function dangerZone()
   return not P.overheating and GetMPerc(me) >= .5 and GetMPerc(me) < 1
end

function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CastAtCC("harpoon") then
      return true
   end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

   local starts = GetInRange(me, "equalizer", SortByDistance(ENEMIES))
   local bestStart
   local bestHits
   local bestScore = 1.5
   for _,start in ipairs(starts) do
      local hits, kills, score = GetBestLine(start, "equalizerLine", 1, 0, GetInRange(start, "equalizerLine", ENEMIES))
      if score > bestScore then
         bestStart = start
         bestHits = hits
         bestScore = score
      end
   end
   if bestStart then
      local center = GetAngularCenter(bestHits, bestStart)
      local ep = Projection(bestStart, center, GetSpellRange("equalizerLine"))
      LineObject(bestStart, GetSpellRange("equalizerLine"), 0, AngleBetween(bestStart, center), spells["equalizerLine"].width)
   end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then
      if Alone() then
         if not P.harpoon then
            if KillMinion("harpoon", "burn") then
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

   EndTickActions()
end

function Action()
   if SkillShot("harpoon", nil, nil, 1) then
      return true
   end

   if CanUse("flame") then
      local target = GetWeakestEnemy("flame", -150)
      if target then
         Cast("flame", target)
         PrintAction("Flame nearby")
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
   Persist("harpoon", object, "rumble_taze_mis")
   PersistBuff("overheating", object, "rumble_overheat")
end

local function onSpell(unit, spell)
   if GetHPerc(me) < .75 or GetMPerc(me) < .5 then
      CheckShield("shield", unit, spell)
   end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

