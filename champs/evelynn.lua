require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Evelynn")

InitAAData({ 
   particles = {"EvelynnBasicAttack_tar"}
})

AddToggle("stealth", {on=false, key=112, label="Stealth Mode"})
AddToggle("jungle", {on=true, key=113, label="Jungle"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "spike", "ravage"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

--[[
Hate Spike will firstly prioritize Evelynn's most recent target and 
   it will target low health units secondly if Evelynn has not attacked a unit. 
   If both an enemy champion and a low health minion are in range, Hate Spike will prioritize the enemy champion.
Hate Spike is only usable when a visible enemy unit is within its range.
]]
spells["spike"] = {
   key="Q", 
   range=500, 
   color=violet, 
   base={40,55,70,85,100}, 
   ap={.35,.4,.45,.5,.55},
   adBonus={.5,.55,.6,.65,.7},
   width=80,
   noblock=true,
   cost={12,18,24,30,36},
} 
spells["frenzy"] = {
   key="W",
   cost=0,
} 

-- test if this is a modaa or an attack reset
spells["ravage"] = {
   key="E", 
   range=225+GetWidth(me),
   color=yellow, 
   base={70,110,150,190,230}, 
   type="P",
   ap=1,
   adBonus=1,
   cost={50,55,60,65,70},
   onHit=true,
} 
spells["embrace"] = {
   key="R",
   range=650,
   radius=250, -- wiki
   color=red,
   base=0, 
   targetHealth={.15,.20,.25},
   targetHealthAP=.0001,   
   cost=100
} 

function Run()
   if StartTickActions() then
      return true
   end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important

   if IsOn("lasthit") then
      if ( not P.walk and not Engaged() ) or
           VeryAlone() or
           not ( P.walk and IsOn("stealth") and Alone() ) 
      then

         if CanUse("spike") then
            if GetThreshMP("spike", .15) <= 1 then
               local minions = GetKills("spike", SortByHealth(GetInRange(me, "spike", MINIONS)))
               local lt = GetWithBuff("attack", minions)[1]
               if lt and
                  ( JustAttacked() or not IsInRange("AA", lt) )
               then
                  Cast("spike", me)
                  AddWillKill(lt, "spike")
                  PrintAction("Spike last attack for LH")
                  return true
               end

               local lt = minions[1]
               if lt then
                  if not IsInRange("AA", lt) or JustAttacked() then
                     Cast("spike", me)
                     AddWillKill(lt, "spike")
                     PrintAction("Spike for LH")
                     return true
                  end
               end
            end
         end

         if CanUse("ravage") then
            if GetThreshMP("ravage", .15) <= 1 then
               local target = KillMinion("ravage", "strong", false, true)
               if target and not WillKill("AA", target) then
                  if KillMinion("ravage", "strong", true) then
                     return true
                  end
               end
            end
         end

      end
   end
   
   if IsOn("clear") then
      if CanUse("spike") then
         if GetThreshMP("spike", .15) <= 1 then
            if #GetInRange(me, "spike", MINIONS) > 0 then
               Cast("spike", me)
               PrintAction("Spike for clear")
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
   -- TODO probably hold off casting if there are people just out of range
   -- TODO I really only want to cast this if there's a hard engage
      -- The shield is a big part of this spell. Should I only embrace if I'm directly engaged?
      -- Trying: if I can spike people and I'm "skirmishing" then go hard
         -- This won't embrace if I'm dueling...
   if CanUse("embrace") then
      if #GetInRange(me, "spike", ENEMIES) >= 1 and Skirmishing() then
         local hits, kills, score = GetBestArea(me, "embrace", 1, 1, ENEMIES)
         if #hits >= 2 then
            CastXYZ("embrace", GetCastPoint(hits, "embrace"))
            PrintAction("Embrace for hits", #hits)
            return true
         elseif #hits == 1 and GetHPerc(hits[1]) > .75 then
            CastXYZ("embrace", hits[1])
            PrintAction("Embrace solo")
            return true
         end
      end
   end

   if CastBest("ravage") then
      return true
   end

   if CastBest("spike") then
      return true
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

local function jungle()
   if IsOn("jungle") and (Alone() or not P.walk) then
      if JustAttacked() then
         if CanUse("spike") then
            local creeps = GetInRange(me, "spike", CREEPS)
            if #creeps > 0 then
               Cast("spike", me)
               PrintAction("Spike in jungle")
               return true
            end
         end

         if CanUse("ravage") then
            local creep = GetBiggestCreep(GetInRange(me, "ravage", CREEPS))
            if creep then
               Cast("ravage", creep)
               PrintAction("Ravage in jungle")
               return true
            end
         end
      end

      if AA(creep) then
         PrintAction("AA "..creep.charName)
         return true
      end
   end
end
SetAutoJungle(jungle)

local function onCreate(object)
   Persist("walk", object, "Evelynn_Ring_Green")
   PersistOnTargets("attack", object, "EvelynnBasicAttack", MINIONS, CREEPS)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

