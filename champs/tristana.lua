require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Tristana")
pp(" - Track charge and charge stacks")
pp(" - Disrupt with buster")
pp(" - Execute with buster (if AA won't do the trick)")
pp(" - Jump on targets if I can finish them with jump/charge/AA/AA")
pp(" - Cast charge on stuff")
pp(" - Target charged stuff with auto attacks")
pp(" - Rapid fire if things are well in (100) attack range")


InitAAData({
   speed=2250,
   extraWindup=-.1,
   particles={"Tristana_Base_BA_mis"}  -- Trists object is shared with minions. This could result in clipping. Can be turned back on for testing
})

SetChampStyle("marksman")
-- SetChampStyle("caster")

AddToggle("jump", {on=false, key=112, label="Jumps"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["rapid"] = {
   key="Q", 
   cost=0,
} 

spells["jump"] = {
   key="W", 
   range=900, 
   color=blue, 
   base={80,105,130,155,180}, 
   ap=.5,
   delay=.2,
   speed=1200, --?
   radius=250, --reticle
   noblock=true,
   cost=60,
   damOnTarget=
      function(target)
         if HasBuff("charge", target) then
            return GetSpellDamage("jump")*.20*(getCharges()+1)
         end
         return 0
      end,
} 
spells["charge"] = {
   key="E", 
   range=GetAARange,
   rangeType="e2e",
   color=violet,
   base={60,70,80,90,100}, 
   ap=.5,
   adBonus={.5,.65,.80,.95,1.1},
   radius=150, --?
   cost={70,75,80,85,90},
   damOnTarget=
      function(target)
         if HasBuff("charge", target) and getCharges() > 0 then
            return GetSpellDamage("charge")*.3*getCharges()
         end
         return 0
      end,
} 
spells["buster"] = {
   key="R", 
   range=GetAARange,
   rangeType="e2e",
   color=red, 
   base={300,400,500}, 
   ap=1,
   knockback={600,800,1000},
   radius=200,
   cost=100,
} 

local jumpPoint = nil
local kbPoint = nil
local kbType = nil

function getKBPoint()

   kbType = nil
   local kbDist = GetLVal(spells["buster"], "knockback")
   local busterRange = GetSpellRange("buster")
   local jumpRange = GetSpellRange("jump")

   -- if GetDistance(HOME) < (850 + kbDist + busterRange + jumpRange) then
   --    PrintState(0, "HOME")      
   --    kbType = "HOME"
   --    return Point(HOME)
   -- end

   local point = SortByDistance(GetInRange(me, 750+kbDist+busterRange+jumpRange, MYTURRETS))[1]
   if point then 
      PrintState(0, "TURRET")
      kbType = "TURRET"
      return point 
   end

   -- local otherAllies = GetOtherAllies()
   -- for _,ally in ipairs(GetInRange(me, kbDist+busterRange, otherAllies)) do
   --    local pick = SelectFromList(
   --       ALLIES, 
   --       function(a) 
   --          return #GetInRange(a, 500, otherAllies)
   --       end,
   --       ally
   --    )
   --    local group = GetInRange(pick, 500, otherAllies)
   --    if #group >= 2 or GetHPerc(pick) > .5 then
   --       PrintState(0, "ALLIES")
   --       kbType = "ALLIES"
   --       return GetCenter(group)
   --    end
   -- end

   -- for _,minion in ipairs(GetInRange(me, 1000, MYMINIONS)) do
   --    local pick = SelectFromList(
   --       MYMINIONS, 
   --       function(a) 
   --          return #GetInRange(minion, 450, MYMINIONS)
   --       end,
   --       minion
   --    )
   --    local group = GetInRange(minion, 450, MYMINIONS)
   --    if #group >= 3 then
   --       point = GetCenter(group)
   --       if GetDistance(point, HOME) < GetDistance(me, HOME)+250 then         
   --          PrintState(0, "MINIONS")
   --          return point
   --       end
   --    end
   -- end

   return nil
end

function getJumpPoint()
   local target = GetWeakestEnemy("jump", 500)

   -- if I don't have a target or a place I want to knock em bail
   if not target or not kbPoint then 
      return nil
   end

   -- I have a target and a point I'd like to knock them to

   local predTarget = GetSpellFireahead("jump", target) -- where they'll be when I land - ish

   -- local predTarget = mousePos
   
   -- local point
   -- if GetDistance(predTarget, kbPoint) > GetDistance(target, kbPoint) then 
   --    -- they're moving away from the kb point, lead em
   --    point = Projection(kbPoint, predTarget, GetDistance(kbPoint, predTarget)+100)
   --    target = predTarget
   -- else       
   --    point = Projection(kbPoint, target, GetDistance(kbPoint, target)+300) 
   -- end

   local point = Projection(kbPoint, predTarget, GetDistance(kbPoint, predTarget)+GetSpellRange("buster"))
   if GetDistance(point) > GetSpellRange("jump") then
      local jd = GetSpellRange("jump")-5
      local od = GetOrthDist(predTarget, me, kbPoint)
      local dx = math.sqrt(jd^2 - od^2) + math.sqrt(GetDistance(kbPoint)^2 - od^2)

      point = Projection(kbPoint, predTarget, dx)
   end

   -- can't get to where I'd need to go
   if GetDistance(point) > GetSpellRange("jump") then
      return nil
   end

   if GetDistance(kbPoint, point) - GetDistance(predTarget, kbPoint) < 300 then -- I won't be able to lead them enough
      return nil
   end

   -- don't jump into walls
   if IsWall(point) then
      return nil
   end

   -- I have a point I'd like to jump to so I can kb
   Circle(point, 50, red, 4)

   -- If I'm closer to the kb point than I am to them don't jump yet
   if GetDistance(kbPoint)+100 < GetDistance(predTarget) then 
      return nil
   end

   -- make sure if I did KB them that they'd go where I want
   local kbDist = GetLVal(spells["buster"], "knockback")
   if kbType == "HOME" then
      if GetDistance(predTarget, kbPoint) > kbDist + 800 then -- I can't knock them home
         return nil
      end
      if GetDistance(predTarget, kbPoint) < 900 then -- already in poool don't bother
         return nil
      end
   elseif kbType == "TURRET" then
      if GetDistance(predTarget, kbPoint) > kbDist + 750 then -- I can't knock them into a turret
         return nil
      end
      if GetDistance(predTarget, kbPoint) < 850 then -- already under tower don't bother
         return nil
      end
   elseif kbType == "ALLIES" then
      if GetDistance(predTarget, kbPoint) > kbDist + 250 then -- I can't knock them into allies
         return nil
      end
   end

   if UnderTower(point) then -- don't jump under towers
      return nil
   end

   if #GetInRange(point, 1000, ENEMIES) > 2 then -- don't jump into groups
      return nil
   end

   return point, predTarget
end

function getCharges()
   if P.charge then
      if find(P.charge.name, "_pulse") then
         return 0
      elseif find(P.charge.name, "_1") then
         return 1
      elseif find(P.charge.name, "_2") then
         return 2
      elseif find(P.charge.name, "_3") then
         return 3
      elseif find(P.charge.name, "_max") then
         return 4
      end
   end
   return 0
end

function Run()
   if StartTickActions() then
      return true
   end

   if CheckDisrupt("buster") then
      return true
   end

   if IsOn("jump") then
      kbPoint = getKBPoint()
      Circle(kbPoint)
      if kbPoint then
         jumpPoint, jumpTarget= getJumpPoint()
         if jumpPoint and jumpTarget then
            Circle(jumpPoint, 50, red, 4)
            -- LineBetween(jumpTarget, GetKnockback("buster", jumpPoint, jumpTarget))
            -- Circle(jumpTarget, nil, red)
            -- LineBetween(me, jumpPoint)
         end
      end
   end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important

   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   -- if IsOn("jump") and 
   --    CanUse("jump") and CanUse("buster") and
   --    me.mana > (GetSpellCost("jump") + GetSpellCost("buster"))
   -- then
   --    if jumpPoint and GetDistance(jumpPoint) < GetSpellRange("jump") then
   --       CastXYZ("jump", jumpPoint)
   --       PrintAction("JUMP for kb to "..kbType)
   --       return true
   --    end
   -- end

   if CanUse("buster") then
      local target = GetKills("buster", GetInRange(me, "buster", ENEMIES))[1]
      if target and not WillKill("AA", target) then
         Cast("buster", target)
         PrintAction("Buster for execute", target)
         return true
      end
   end

   -- version for just jumping on fully charged enemies
   -- if CanUse("jump") then
   --    -- if there's a target in jump range with 4 charges
   --    if getCharges() == 4 then
   --       local target = GetWithBuff("charge", ENEMIES)[1]         
   --       if target and IsInRange("jump", target) then
   --          -- and I can't kill them with an AA
   --          if not IsInAARange(target) then
   --             local point = GetSpellFireahead("jump", target)
   --             Circle(point)
   --             if WillKill("jump", "charge", "AA", "AA", target) then
   --                Cast("jump", target)
   --                PrintAction("Jump on charged", target)
   --                return true
   --             end
   --          end
   --       end
   --    end
   -- end

   -- generic jump for finish
   if CanUse("jump") then
      local targets = SortByDistance(ENEMIES, me, true)
      for _,target in ipairs(targets) do
         local point = GetSpellFireahead("jump", target)
         if not IsInAARange(point) then
            if ( not UnderTower(point) or GetHPerc(me) > .75 ) and
               IsInRange("jump", target) and 
               WillKill("jump", "charge", "AA", "AA", target) 
            then
               Cast("jump", target)
               PrintAction("Jump for finish", target)
               return true
            end
         end
      end
   end

   if CanUse("buster") and kbPoint then
      for _,target in ipairs(SortByDistance(GetInRange(me, "buster", ENEMIES))) do
         local targetKb = GetKnockback("buster", me, target)
         -- the kb will move them closer to the kbPoint than they are now (why kb if it won't move them where I want to move them)
         if GetDistance(kbPoint, targetKb) < GetDistance(kbPoint, target) and
            ( GetDistance(targetKb, kbPoint) < 500 or  -- they'll land where I want them
              UnderMyTower(targetKb) or -- they'll land under tower
              GetDistance(targetKb, HOME) < 800 ) -- they'll land in the pool 
         then 
            Cast("buster", target)
            PrintAction("KB to "..kbType, target)
            return true
         end
      end
   end

   if CastBest("charge") then
      return true
   end

   if CanUse("rapid") then
      local target = GetWeakestEnemy("AA", -100)
      if target then
         Cast("rapid", me)
         PrintAction("Rapid Fire", target)
         return true
      end
   end

   local target = GetMarkedTarget() or 
                  GetWeakest("AA", GetWithBuff("charge", GetInRange(me, "AA", ENEMIES))) or
                  GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()
   return false
end

local function onObject(object)
   PersistOnTargets("charge", object, "Tristana_Base_E_charge_buff_", ENEMIES, TURRETS, CREEPS, MINIONS)
   Persist("charge", object, "Tristana_Base_E_charge_buff_")
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

AddOnTick(Run)

