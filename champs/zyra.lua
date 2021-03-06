require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Zyra")

SetChampStyle("caster")

InitAAData({
   speed = 1700, windup=.2,
   particles = {"Zyra_basicAttack"}
})

AddToggle("seed", {on=true, key=112, label="Auto seed", auxLabel="{0}", args={function() return spells["seed"].charges end}})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=false, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "bloom"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["bloom"] = {
   key="Q", 
   range=800, 
   color=violet, 
   base={70,105,140,175,210}, 
   ap=.65,
   delay=.8-.1, -- TestSkillShot
   speed=0,
   noblock=true,
   radius=225-25, -- reticle
   name="ZyraQFissure",
   cost={75,80,85,90,95},
}
spells["seed"] = {
   key="W", 
   range=850, 
   color=green,
   width=150,
   name="ZyraSeed",

   useCharges=true,
   maxCharges=2,
   rechargeTime={17,16,15,14,13},
   charges=1,

   extraCooldown=.75
}
spells["roots"] = {
   key="E", 
   range=1100-50, 
   color=yellow, 
   base={60,95,130,165,200}, 
   ap=.5,
   delay=.24,
   speed=1150,
   noblock=true,
   width=80,  --?
   growWidth=315,
   name="ZyraGraspingRoots",
   cost={70,75,80,85,90},
}
spells["strangle"] = {
   key="R", 
   range=700, 
   color=red, 
   base={180,265,350}, 
   ap=.7,
   delay=.2,
   speed=0,
   noblock=true,
   radius=525,  -- reticle
   cost={100,120,140}
}

function Run()
   if StartTickActions() then
      return true
   end

   local seeds = GetPersisted("seed")

   for _,seed in ipairs(seeds) do
      if CanUse("bloom") and GetDistance(seed, GetMousePos()) < spells["bloom"].radius then
         Circle(seed, 75, violet, 3)
         LineBetween(mousePos, seed)
      end
      if CanUse("roots") and GetDistance(seed, GetMousePos()) < spells["roots"].growWidth then
         Circle(seed, 70, yellow, 3)
         LineBetween(mousePos, seed)
      end
   end

   if CastAtCC("bloom") or
      CastAtCC("roots")
   then
      return true
   end

   if HotKey() then
      if Action() then
         return true
      end
   end

   -- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then
      if Alone() then
         if KillMinionsInArea("bloom") then
            return true
         end      
      end

      if VeryAlone() then
         if KillMinionsInLine("roots") then
            return true
         end
      end
   end


   if HotKey() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   -- TestSkillShot("roots")
   -- TestSkillShot("bloom", "zyra_Q_expire")

   if SkillShot("roots") then
      return true
   end

   if SkillShot("bloom") then
      return true
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
   PersistAll("seed", object, "Zyra_seed_indicator_team")
end

local function onSpell(unit, spell)
   if IsOn("seed") then
      if ICast("roots", unit, spell) then
         if CanUse("seed") then
            for _,enemy in ipairs(ENEMIES) do 
               if GetOrthDist(spell.endPos, enemy) < spells["roots"].growWidth then
                  local point = Projection(me, spell.endPos, GetDistance(enemy))
                  if GetDistance(point) > GetSpellRange("seed") then
                     point = Projection(me, point, GetSpellRange("seed"))
                  end
                  StartChannel(.25)
                  CastXYZ("seed", point)
                  PrintAction("Seed on roots")
                  break
               end
            end
         end
      end

      if ICast("bloom", unit, spell) then
         if CanUse("seed") then
            StartChannel(.25)
            CastXYZ("seed", spell.endPos)
            PrintAction("Seed on bloom")
         end
      end
   end

end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)
