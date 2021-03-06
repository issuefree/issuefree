require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Karma")

InitAAData({
   speed=1500,
   particles = {"Karma_Base_BA_mis"}
})

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move to Mouse"})

spells["flame"] = {
   key="Q", 
   range=950, 
   color=violet, 
   base={80,125,170,215,260}, 
   ap=.6,
   delay=.16,
   speed=1700,
   width=100,
   radius=250,
   cost={50,55,60,65,70},
}
spells["soulflare"] = {
   key="R",
   base={25+50,75+150,125+250,175+350},
   ap=.9
}
spells["tether"] = {
   key="W", 
   range=650, 
   color=yellow, 
   base={60,110,160,210,260}, 
   ap=.9,
   cost={70,75,80,85,90}
}
spells["shield"] = {
   key="E", 
   range=800, 
   color=cyan, 
   base={80,110,140,170,200}, 
   ap=.5,
   cost={60,65,70,75,80},
   shieldRadius=700,
   damageRadius=600
}
spells["mantra"] = {
   key="R",
   cost=0,
} 

function Run()
   if StartTickActions() then
      return true
   end

   local target = CastAtCC("flame", nil, true)
   if target then
      Cast("mantra", me)
      Cast("flame", target)
      PrintAction("Soulflare", target)
      return true
   end

	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	if IsOn("lasthit") and Alone() then
      if CanUse("flame") then
         local unblocked = GetUnblocked("flame", me, MINIONS)
         local bestK = 1
         local bestT
         for _,target in ipairs(unblocked) do
            local kills = #GetKills("flame", GetInRange(target, 150, MINIONS))
            if kills > bestK then
               bestT = target
               bestK = kills
            end
         end
         if bestT then
            CastXYZ("flame", bestT)
            PrintAction("flame for lasthit")
            return true
         end
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end
   EndTickActions()
end

function Action()
   if CanUse("tether") then
      local target = SortByDistance(GetInRange(me, "tether", ENEMIES))[1]
      if target then
         if GetHPerc(me) < .5 and CanUse("mantra") then
            Cast("mantra", me)
            PrintAction("Mantra for heal", nil, 1)
         end
         Cast("tether", target)
         PrintAction("Tether", target)
         return true
      end
   end

   if CanUse("flame") then
      -- if CanUse("mantra") then -- look for executes, then for clumps
      --    local unblocked = GetUnblocked("flame", me, MINIONS, ENEMIES)
      --    unblocked = FilterList(unblocked, function(item) return not IsMinion(item) end)
      --    unblocked = SortByDistance(FilterList(unblocked, function(item) return IsGoodFireahead("flame", item) end))
      --    for _,target in ipairs(unblocked) do -- aim for the closest guy I can kill
      --       if GetSpellDamage("flame", target) < target.health and
      --          GetSpellDamage("flame", target) + GetSpellDamage("soulflare", target) > target.health then
      --          Cast("mantra", me)
      --          CastFireahead("flame", target)
      --          PrintAction("Soulflare for execute", target)
      --          return true
      --       end
      --    end
      --    local bestT
      --    local bestH = 1
      --    for _,target in ipairs(unblocked) do
      --       local hits = #GetInRange(target, spells["flame"].radius, ENEMIES)
      --       if hits > bestH then
      --          bestT = target
      --          bestH = hits
      --       end
      --    end
      --    if bestT then
      --       Cast("mantra", me)
      --       CastFireahead("flame", bestT)
      --       PrintAction("Soulflare for aoe", bestT)
      --       return true
      --    end
      -- end

      local target = GetSkillShot("flame")
      if target then
         if CanUse("mantra") and ApproachAngleRel(me, target) < 30 then
            Cast("mantra", me)
            PrintAction("Mantra for good flame", nil, 1)
         end

         CastFireahead("flame", target)
         PrintAction("Flame", target)
         return true
      end
   end

   return false
end

function FollowUp()
   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end

local function onObject(object)
end

local function onSpell(unit, spell)
   local target = CheckShield("shield", unit, spell, "CHECK")
   if target then
      if CanUse("mantra") and
         #GetInRange(target, spells["shield"].shieldRadius, ALLIES) >= 2 and
         #GetInRange(target, spells["shield"].damageRadius, ENEMIES) >= 2
      then
         Cast("mantra", me)
         PrintAction("Mantra for shield")
      end
      Cast("shield", target)
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)
