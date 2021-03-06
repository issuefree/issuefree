require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Caitlyn")
pp(" - alert for snipe")
pp(" - try to trap to kite or chase")
pp(" - piltover people out of AA range")
pp(" - farming w/headshot clears with piltover")

InitAAData({
   speed = 2500,
   extraRange=-10,
   extraWindup=.15,
   particles = {"caitlyn_Base_mis", "caitlyn_Base_passive"},
   attacks = {"attack", "CaitlynHeadshotMissile"}
})

SetChampStyle("marksman")

AddToggle("pp", {on=true, key=112, label="Piltover", auxLabel="{0}", args={"pp"}})
AddToggle("trap", {on=true, key=113, label="Trap"})
AddToggle("execute", {on=true, key=114, label="AutoExecute", auxLabel="{0}", args={"ace"}})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["pp"] = {
   key="Q", 
   range=1250, 
   color=violet, 
   base={30,70,110,150,190}, 
   ad={1.3,1.4,1.5,1.6,1.7},
   cost={50,60,70,80,90},
   delay=.7-.3, -- reduce delay for less leading
   speed=2200,
   type="P",
   width=80,
   noblock=true
}
spells["trap"] = {
   key="W", 
   range=800, 
   color=blue,
   type="M",
   cost=50,
   delay=.8,
   speed=0,
   radius=67.5,
   noblock=true
}
spells["net"] = {
   key="E", 
   range=950, 
   color=yellow, 
   base={70,110,150,190,230}, 
   ap=.8,
   type="M",
   cost=75,
   delay=.225,
   speed=20
}
spells["recoil"] = {
   key="E", 
   range=400, 
   color=blue
}
spells["ace"] = {
   key="R", 
   range={2000, 2500, 3000},
   color=red, 
   base={250,475,700}, 
   type="P",
   adBonus=2,
   cost=100,
}
spells["headshot"] = {
   base={0},
   ad=.5,
   type="P",
   -- no need to code up the 5.11 change to passive
}

spells["AA"].damOnTarget = 
   function(target)
      if P.headshot and not IsHero(target) then
         return GetSpellDamage("headshot")*3
      end
   end

function Run()
   if P.headshot then
      spells["AA"].bonus = GetSpellDamage("headshot")
   else
      spells["AA"].bonus = 0
   end

   if StartTickActions() then
      return true
   end
   
   if IsOn("execute") and CanUse("ace") then
      local target = GetWeakestEnemy("ace")
      if target and WillKill("ace", target) then
         LineBetween(me, target, 3)
         Circle(target, 100, red, 6)
      end
   end

   if CastAtCC("trap") then
      return true
   end
   if IsOn("piltover") then
      local target = CastAtCC("piltover", nil, true)
      if target and not IsInAARange(target) then
         return true
      end
   end

   if HotKey() and CanAct() then
      if Action() then
         return true
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
   -- TestSkillShot("pp")
   -- TestSkillShot("trap")
   -- TestSkillShot("net")

   if IsOn("trap") and 
      CanUse("trap") and 
      me.mana > GetSpellCost("net") + GetSpellCost("trap") and
      ( not CanUse("ace") or me.mana > GetSpellCost("ace") + GetSpellCost("trap") )
   then
      if SkillShot("trap") then
         return true
      end
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   if IsOn("pp") and 
      CanUse("pp") and 
      me.mana > GetSpellCost("net") + GetSpellCost("pp") and
      ( not CanUse("ace") or me.mana > GetSpellCost("ace") + GetSpellCost("pp") ) and
      not GetWeakestEnemy("AA")
   then
      if SkillShot("pp") then
         return true
      end
   end

   return false
end

function FollowUp()
   if IsOn("clear") and Alone() then
      -- check for a big clear from pp
      if IsOn("pp") then
         if HitMinionsInLine("pp", GetThreshMP("pp", .05, 2)) then
            return true
         end
      end
   end

   return false
end

local function onObject(object)
   PersistBuff("headshot", object, "headshot_rdy")
end

local function onSpell(unit, spell)

end

AddOnCreate(onObject)
AddOnSpell(onSpell)

AddOnTick(Run)