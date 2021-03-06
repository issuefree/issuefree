require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Sion")

InitAAData({ 
})

SetChampStyle("bruiser")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["smash"] = {
   key="Q", 
   range=800, -- TODO wiki says 300-600
   color=yellow, 
   base={20,40,60,80,100}, 
   ad=.65,
   delay=.24, 
   speed=2000, -- 
   width=190, -- reticle
   chargeTime=2,
   scale=function(target)
            local scale
            if smashStartTime then
               local ct = time() - smashStartTime
               scale = math.min(3, 1 + 2*(ct / spells["smash"].chargeTime))
            else
               scale = 1
            end
            if IsMinion(target) then
               scale = scale*.8
            end
            return scale
         end,
   type="P",
   cost=45,
} 
spells["furnace"] = {
   key="W", 
   range=525, 
   color=cyan, 
   base={40,65,90,115,140}, 
   ap=.4,
   targetMaxHealth={.1,.11,.12,.13,.14},
   armTime=2,
   duration=6,
   cost={65,70,75,80,85},
} 
spells["roar"] = {
   key="E",
   range=825,  -- reticle
   color=violet, 
   base={70,105,140,175,210}, 
   ap=.4,
   delay=.24, -- tss
   speed=1750, -- tss
   width=85, -- reticle
   knockback=650, --reticle
   cost={35,40,45,50,55},
} 
spells["roarKB"] = copy(spells["roar"])
spells["roarKB"].scale = 1.5

spells["onslaught"] = {
   key="R", 
   base={150,300,450}, 
   ad=.4,
   duration=8,
   type="P",
   cost=100,
} 

--TODO
-- detect glory in death
-- detect onslaught

smashStartTime = nil

function Run()
   Circle(P.onslaught, nil, red)

   -- local minion = SortByDistance(GetInRange(me, "roar", MINIONS))[1]
   -- if minion then
   --    Circle(minion)
   --    local kbs = getRoarCollisions(minion)
   --    for _,kb in ipairs(kbs) do
   --       Circle(kb, nil, red)
   --    end
   -- end

   if StartTickActions() then
      return true
   end

   if CastAtCC("roar") then
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
      if Alone() then
         
         if CanUse("roar") then
            local minions = GetUnblocked("roar", me, MINIONS)
            local minion, score = SelectFromList( minions, 
               function(item)                  
                  local hits = getRoarCollisions(item, CREEPS, MINIONS, PETS, ENEMIES)
                  local score, kills = scoreHits("roarKB", hits, .05, .95)
                  local s1 = scoreHits("roar", {item}, .05, .95)
                  score = score + s1
                  return score            
               end )
            if score >= GetThreshMP(thing, .1, 1.5) then
               CastXYZ("roar", minion)
               PrintAction("Roar for LH", score)
               return true
            end
         end

         if CanUse("furnace") then
            if GetSpellInfo("W").name == "sionwdetonate" then
               local kills = GetKills("furnace", GetInRange(me, "furnace", MINIONS))
               if #kills >= 2 then
                  Cast("furnace", me)
                  PrintAction("Pop shield for LH")
                  return true
               end
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
   if CanUse("roar") then
      local throws = GetUnblocked("roar", me, PETS, CREEPS, MINIONS)
      local throw, score = SelectFromList( throws, 
         function(item)                  
            local hits = getRoarCollisions(item, ENEMIES)
            local score = scoreHits("roarKB", hits, 1, 5)
            return score            
         end )
      if score >= 1 then
         CastXYZ("roar", throw)
         PrintAction("Roar for damage", score)
         return true
      end
   end

   if SkillShot("roar", nil, nil, 2.5) then
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

function getRoarCollisions(target, ...)
   return removeItems( GetInLine( target, 
                                  {width=GetWidth(target)}, 
                                  Projection(me, target, spells["roar"].range + spells["roar"].knockback), 
                                  GetInRange(target, spells["roar"].range + spells["roar"].knockback, concat(...)) ),
                       {target} )
end

local function onCreate(object)
   PersistBuff("onslaught", object, "Sion_Base_R_Cas.troy")
   PersistBuff("glory", object, "Sion_Base_Passive_Skin")

   if Persist("smashEnd", object, "Sion_Base_Q_Hit") then
      smashStartTime = nil
   end
end

local function onSpell(unit, spell)
   if ICast("smash", unit, spell) then
      smashStartTime = time()
   end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

