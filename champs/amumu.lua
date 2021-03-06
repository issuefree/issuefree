require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Amumu")
pp(" - Despair and Tantrum in the jungle")
pp(" - Despair and Tantrum enemies")

InitAAData({
  baseAttackSpeed = 0.638,
  windup=.30,
  extraRange=25,
  particles = {"SadMummyBasicAttack"}
})

AddToggle("", {on=true, key=112, label="- - -"})
AddToggle("jungle", {on=true, key=113, label="Jungle"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "tantrum"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["bandage"] = {
  key="Q", 
  range=1100, 
  color=violet, 
  base={80,130,180,230,280}, 
  ap=.7,
  delay=.16,
  speed=2000,
  width=80,
  cost={80,90,100,110,120}
}
spells["despair"] = {
  key="W", 
  range=300, 
  color=blue,
}
spells["tantrum"] = {
  key="E", 
  range=350, 
  color=red, 
  base={75,100,125,150,175}, 
  ap=.5,
  cost=35
}
spells["curse"] = {
  key="R", 
  range=550, 
  color=yellow, 
  base={150,250,350}, 
  ap=.8,
  cost={100,150,200}
}

function Run()
   if StartTickActions() then
      return true
   end

   if CanUse("despair") then
      if P.despair and 
         #GetInRange(me, GetSpellRange("despair")+50, MINIONS, ENEMIES, CREEPS) == 0 
      then
         CastBuff("despair", false)
      end
   end

	if HotKey() then
		if Action() then
			return true
		end
	end

   if IsOn("jungle") then
      if #GetInRange(me, "despair", BIGCREEPS, MAJORCREEPS) > 0  then

         CastBuff("despair")

         if CanUse("tantrum") then
            Cast("tantrum", me)
            PrintAction("Tantrum for jungle")
            return true
         end
      end
   end

	if IsOn("lasthit") then
      if CanUse("tantrum") and not Engaged() then
         if #GetKills("tantrum", GetInRange(me, "tantrum", MINIONS)) >= 2 then
            Cast("tantrum", me)
            PrintAction("Tantrum for lasthit")
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
   -- TestSkillShot("bandage")
   
   if GetWeakestEnemy("despair") then
      CastBuff("despair")
   end

   if CastBest("tantrum") then
      Cast("tantrum", me)
      return true
   end

   -- amumu is melee but not really an aa champ. Don't bother forcing auto attack
   -- local target = GetMarkedTarget() or GetMeleeTarget()
   -- if AutoAA(target) then
   --    return true
   -- end

   return false
end

function FollowUp()
   if IsOn("clear") and Alone() then
      if CanUse("tantrum") and #GetInRange(me, "tantrum", MINIONS) >= 3 then
         Cast("tantrum", me)
         PrintAction("Tantrum for clear")
         return true
      end
   end

   return false
end

local function onObject(object)
   PersistBuff("despair", object, "Despair_buf", 150)
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)
