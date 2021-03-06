require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Vel'Koz")

-- track deconstruction

InitAAData({ 
   speed=2000,
   particles = {"Velkoz_Base_BA_Beam.troy"} 
})

SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "disruption"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

function deconOnHit(target)
   if HasBuff("deconstructionFull", target) then
      return GetSpellDamage("deconstruction")
   end
   return 0
end

spells["deconstruction"] = {
   base=25,
   lvl=10,
   type="T"
}
spells["fission"] = {
   key="Q", 
   range=1200,
   color=violet, 
   base={80,120,160,200,240}, 
   ap=.6,
   delay=.26, -- testskillshot
   speed=1250,  -- testskillshot
   width=65,  -- reticle
   splitDist=900, -- visual
   cost={40,45,50,55,60},
   damOnTarget=deconOnHit,
} 
spells["rift"] = {
   key="W", 
   range=900, 
   color=yellow, 
   base={30,50,70,90,110}, 
   ap=.25,
   delay=.35, -- guess
   speed=1500,  -- guess
   width=90,  -- reticle
   noblock=true,

   useCharges=true,
   maxCharges=2,
   rechargeTime={18,17,16,15,14},
   charges=1,
   cost={50,55,60,65,70},
   damOnTarget=deconOnHit,
} 
spells["disruption"] = {
   key="E", 
   range=1175, 
   color=blue, 
   base={70,100,130,160,190}, 
   ap=.5,
   delay=.24+.55, -- testskillshot
   speed=0,
   radius=225,  -- reticle
   noblock=true,
   cost={50,55,60,65,70},
   damOnTarget=deconOnHit,
} 
spells["ray"] = {
   key="R", 
   range=1550, 
   color=red, 
   base={500,700,900}, 
   ap=.6,
   width=125, -- guess
   cost=100,
   damOnTarget=deconOnHit,
} 

local fissionAngle

function Run()
   if CanUse("fission") then
      local p = Point(mousePos)
      p.y = me.y
      if IsInRange("fission", mousePos) then
         LineBetween(me, p, 1, violet)
         LineObject(p, spells["fission"].splitDist, AngleBetween(me, p)+math.pi/2, 1, violet)
         LineObject(p, spells["fission"].splitDist, AngleBetween(me, p)-math.pi/2, 1, violet)
      end
   end

   for _,t in ipairs(GetWithBuff("deconstruction", CREEPS)) do
      Circle(t)
   end

   if StartTickActions() then
      return true
   end

   if P.fission and fissionAngle then
      local targets = GetInRange(P.fission, spells["fission"].splitDist, ENEMIES)
      for _,target in ipairs(targets) do
         local r = GetDistance(target) / GetDistance(P.fission, target)
         local point = VP:GetPredictedPos(target, .25, target.ms, me, true)
         local ra = RadsToDegs(RelativeAngle(P.fission, me, point))
         if ra > 85 and ra < 95 then
            if not IsBlocked(point, "fission", P.fission, ENEMIES, MINIONS, PETS) then
               Cast("fission", me, true)
               PrintAction("Fission for split", target)
               break
            end
         end
      end
   end

   -- auto stuff that always happen
   if CheckDisrupt("distruption") then
      return true
   end

   if CastAtCC("rift") or
      CastAtCC("fission") or
      CastAtCC("disruption")
   then
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
         if KillMinionsInArea("disruption") then
            return true
         end
         if spells["rift"].charges > 1 then
            if KillMinionsInLine("rift") then
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
   -- TestSkillShot("fission", nil, {"Q_cas"})
   -- TestSkillShot("rift", nil, {"Poot"})
   -- TestSkillShot("disruption", "explo")

   if CanUse("fission") and not P.fission then
      -- try the easy shot first
      if SkillShot("fission") then
         return true
      end

      -- ok math is hard so let's brute force it.
      -- if there's no clean shot find a target probably weakest in 1485
      -- if there's a target it's blocked so scan right and left at intervals
      -- at each interval get the intercept at 90
      -- check if it's clean to that point and from that point to the target
      -- FIRE!

      -- local mins = { 
      --    Point(mousePos.x+50, mousePos.y, mousePos.z+50),
      --    Point(mousePos.x-50, mousePos.y, mousePos.z+25), 
      --    Point(mousePos.x-100, mousePos.y, mousePos.z+25), 
      --    Point(mousePos.x+100, mousePos.y, mousePos.z+25), 
      --    Point(mousePos.x+200, mousePos.y, mousePos.z+200), 
      -- }

      -- local targs = {
      --    Point(mousePos.x+350, mousePos.y, mousePos.z+320),
      -- }

      -- for _,m in ipairs(mins) do
      --    m.width = 60
      --    Circle(m, nil, yellow)
      -- end
      -- for _,t in ipairs(targs) do
      --    t.width = 80
      --    Circle(t, nil, red)
      -- end

      local targets = SortByHealth(GetInRange(me, 1485, ENEMIES, targs), "fission")
      for _,target in ipairs(targets) do
         local tp = GetSpellFireahead("fission", target)
         local ta = AngleBetween(me, tp)
         local d = GetDistance(tp)
         for da = 5,45,5 do
            local a = DegsToRads(da)
            for _,i in ipairs({-1,1}) do
               local na = ta + a*i
               local iDist = d*math.cos(a)
               if iDist < GetSpellRange("fission") then 
                  local iPoint = ProjectionA(me, na, iDist)
                  iPoint.y = target.y
                  if not IsBlocked(iPoint, "fission", me, ENEMIES, MINIONS, mins, PETS) then
                     if not IsBlocked(tp, "fission", iPoint, ENEMIES, MINIONS, mins, PETS) then
                        CastXYZ("fission", iPoint)
                        Circle(iPoint, 25, blue)
                        LineBetween(me, iPoint)
                        LineBetween(iPoint, tp)

                        -- PrintState(0, ta)
                        -- PrintState(1, da)
                        -- PrintState(2, na)
                        -- PrintState(3, iDist)

                        PrintAction("Fission for split", target)
                        return true
                     end               
                  end
               end
            end
         end
      end
   end

   if SkillShot("rift") then
      return true
   end

   if SkillShot("disruption") then
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

local function onCreate(object)
   PersistOnTargets("deconstruction", object, "Velkoz_Base_P_Research", ENEMIES, CREEPS)
   Persist("fission", object, "Velkoz_Base_Q_mis.troy")
end

local function onSpell(unit, spell)
   if ICast("fission", unit, spell) then
      fissionAngle = AngleBetween(me, spell.endPos)
   end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

