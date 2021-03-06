require "issuefree/basicUtils"

-- "hardness" of the cc
local GRAB = 4
local TAUNT = 4
local STUN = 3
local KNOCK = 3
local FEAR = 3
local BIND = 2
local SLOW = 1
local SILENCE = 1

ignoredSpells = {
	"attack", "recall", "potion", "summoner", "IronStylus", "item", "ZhonyasHourglass",
	"totem", "ward", "BilgewaterCutlass", "ItemSwordOfFeastAndFamine",
	"trinket", "HealthBomb", "RanduinsOmen", "YoumusBlade", "FlaskOfCrystalWater", 
	"ElixirOfWrath", "HextechGunblade", "Muramana", "shurelyascrest", "lanternwally",
	"kalistarallydash", "hextechsweeper", "quicksilversash", "dummy", "oracleextractsight",
	"elixirofsorcery",

	"snowballfollowupcast",
}

-- some spells cause predictable movement patterns that we can take advantage of:
--[[
	spell={
		duration=seconds		How long the prediction is valid for. If a stall has a duration of 2 that character will be there for 2 seconds.
									Duration doesn't quite make sense for dashes at this time.
		type="dash",			These spells cause the character to move to a predictable spot
			ends="<type>",		"max"			Dash always ends at max range
														Graves's dash
									"reverse"	Dash always ends at max range opposite of fire direction
														Caitlyn's net
									"point"		Dash ends at the fire point capped at range
														Tristana's jump
									"target"		Dash ends on a target
														Jax's leap, Alistair's headbutt
			range=#,				Max cast range
			overShoot=#,		How far past the cast point the land position is (some spells undershoot a bit)

		type="stall"			These spells cause the character to temporarily stop
	}
]]

SPELL_DEFS = {
   Aatrox = {
      aatroxq={type="dash", ends="point", range=650},
   },
	Ahri = {
		ahriorbofdeception={range=880, radius=80, time=1, ss=true, isline=true},
		ahriseduce={range=975, radius=80, time=1, ss=true, isline=true, block=true, cc=TAUNT, nodamage=true},
      ahritumble={type="dash", ends="max", range=450, key="R"},
      ahrifoxfire={},
	},
	Akali = {
		akalimota={},
      akalishadowswipe={},
      akalishadowdance={type="dash", ends="target", key="R"},
      akalismokebomb={},
	},
	Alistar = {
		alistarq={
			cc=KNOCK,
			type="dash", ends="target", overShoot=-25,
		},
		alistarw={},
		alistare={},
		alistarr={},
	},
	Amumu = {
		bandagetoss={
			range=1100, radius=80, time=1, ss=true, isline=true, block=true, cc=STUN, 
			type="dash", ends="target"
		},
		auraofdespair={},
		tantrum={},
	},
	Annie = {
		disintegrate={key="Q", cc=STUN},
		infernalguardian={key="R", range=600, perm=true, cc=STUN},
		incinerate={},
		moltenshield={},
		infernalguardianguide={},
	},
	Anivia = {
		flashfrostspell={range=1100, radius=90, time=2, ss=true, show=true, isline=true, cc=STUN},
		frostbite={},
		crystallize={},
		flashfrost={},
		glacialstorm={},
	},
	Ashe = {
		asheq={block=true, cc=SLOW, physical=true},
		volley={"asheq"},
		enchantedcrystalarrow={range=50000, radius=120, time=4, ss=true, show=true, isline=true, cc=STUN, dodgeByObject=true},
		ashespiritofthehawk={},
	},
	AurelionSol = {
	
	},
   Azir = {
   	azirq={},
   	azirw={},
   	azire={key="E", type="dash", ends="target"},
   	azirr={},
   	azirdummyspell={},
   	azirtowerclick={},
   }, 
   Bard={
   	bardq={},
   	bardw={},
   	bardwhealthpack={},
   	bardwdirectheal={},
   	barde={},
   	bardr={},
   },
	Blitzcrank = {
		rocketgrab={
			key="Q", range=925, radius=90, time=1, ss=true, block=true, perm=true, show=true, isline=true, cc=GRAB,
			type="stall",
		},
		rocketgrabmissile={"rocketgrab"},
		overdrive={},
		powerfist={},
		staticfield={},
	},
	Brand = {
		brandq={range=1050, radius=70, time=1, ss=true, isline=true, block=true, cc=STUN},
		brandw={},
		brande={range=900, radius=250, time=4, ss=true, isline=false},
		brandr={},
	},
	Braum = {
		braumq={range=1000, radius=175, time=1, ss=true, isline=true, block=true, cc=SLOW},
		braumqmissile={},
		braumw={type="dash", ends="target"},
		braume={},
		braumrwrapper={},
	},
	Caitlyn = {
		caitlynheadshotmissile={physical=true},
      caitlynentrapment={type="dash", ends="reverse", range=400+75},
		caitlynentrapmentmissile={range=1000, radius=50, time=1, ss=true, isline=true, cc=SLOW, physical=true},
		caitlynpiltoverpeacemaker={
			range=1300, radius=80, time=1, ss=true, isline=true, physical=true,
			type="stall"
		},
      caitlynyordletrap={key="W"},
		caitlynaceinthehole={
			physical=true,
			type="stall", duration=2
		},
	},
	Cassiopeia = {
		cassiopeiamiasma={range=850, radius=175, time=1, ss=true, isline=false},
		cassiopeianoxiousblast={range=850, radius=75, time=1, ss=true, isline=false},
		cassiopeiatwinfang={},
		cassiopeiapetrifyinggaze={type="stall"},
	},
	Chogath = {
		rupture={
			range=950, radius=275, time=2, ss=true, show=true, isline=false, cc=SLOW,
			type="stall"
		},
		feralscream={cc=SILENCE},
		feast={},
		vorpalspikes={},
	},
	Corki = {
		missilebarrage={},
		missilebarragemissile={range=1225, radius=80, time=1, ss=true, isline=true, block=true},
		missilebarragemissile2={range=1225, radius=100, time=1, ss=true, isline=true, block=true},
		carpetbomb={
			--range=800, radius=150, time=1, ss=true, isline=true, point=true,
			type="dash", ends="point", range=800
		},
		phosphorusbomb={},
		ggun={},
	},
	Darius = {
		dariusaxegrabcone={
			key="E", range=540, perm=true, cc=GRAB, nodamage=true,
			type="stall"
		},
		dariusegrabsound={},
      dariusexecute={type="dash", ends="target"},
      dariuscleave={},
      dariusnoxiantacticsonh={},
	},
	Diana = {
		dianavortex={},
		dianaorbs={},
		dianaarc={range=900, radius=205, time=1, ss=true, isline=true},
      dianateleport={type="dash", ends="target"},
	},
	Draven = {
		dravendoubleshot={range=1050, radius=125, time=1, ss=true, isline=true, cc=SLOW, physical=true},
		dravenrcast={range=50000, radius=100, time=4, ss=true, show=true, isline=true, physical=true,
			type="stall"
		},
		dravenspinning={},
		dravenfury={},
	},
	DrMundo = {
		infectedcleavermissile={},
		infectedcleavermissilecast={key="Q", range=1000, radius=60, time=1, ss=true, perm=true, block=true, isline=true, block=true, cc=SLOW},
		burningagony={key="W"},
		masochism={},
		sadism={},
	},
	Elise = {
		elisehumanq={},
      elisespiderqcast={type="dash", ends="target"},
      elisehumanw={},
      elisespiderw={},
		elisehumane={range=1075, radius=100, time=1, ss=true, block=true, perm=true, isline=true, block=true},
		elisespidereinitial={},
		elisespidere={},
		eliser={},
		eliserspider={},
	},
	Evelynn = {
		evelynnq={},
		evelynnw={},
		evelynne={},
		evelynnr={},
	},
	Ezreal = {
		ezrealmysticshot={key="Q", range=1100, radius=80, time=1, ss=true, block=true, perm=true, isline=true, block=true, physical=true},
		ezrealessenceflux={},
		ezrealessencefluxmissile={range=900, radius=100, time=1, ss=true, isline=true},
      ezrealarcaneshift={type="dash", ends="point", range=475},
		ezrealtrueshotbarrage={
			range=50000, radius=150, time=4, ss=true, show=true, isline=true, dodgeByObject=true,
			type="stall", duration=1
		},
	},
	FiddleSticks = {
		terrify={cc=FEAR, nodamage=true},

      drain={type="stall"},
      drainchannel={"drain"},

		crowstorm={
			range=800, radius=300, time=1.5, ss=true, isline=false,
			type="dash", ends="point"
		},
		fiddlesticksdarkwind={cc=SILENCE},
	},
   Fiora={
      fioraq={type="dash", ends="target"},
      fiorariposte={},
      fioraflurry={},
      fioradance={},
   },
	Fizz = {
		fizzmarinerdoom={range=1275, radius=100, time=1.5, ss=true, isline=true, point=true, block=true, cc=SLOW},
		fizzjump={},
		fizzpiercingstrike={},
		fizzseastonepassive={},
		fizzjumptwo={},
		fizzjumpbuffer={},
	},
	Galio = {
		galioresolutesmite={range=905, radius=200, time=1.5, ss=true, isline=false, cc=SLOW},
		galiorighteousgust={range=1000, radius=120, time=1.5, ss=true, isline=true},
      galioidolofdurand={type="stall", duration=2},
      galiobulwark={},
	},
	Gangplank = {
		gangplankqwrapper={physical=true},
		gangplankqproceed={},
		gangplankw={},
		gangplanke={},
		gangplankr={},
	},
	Garen = {
		garenq={key="Q"},
		garenw={key="W"},
		garene={key="E"},
		garenecancel={},
		garenr={key="R"},
	},
	Gnar = {
		gnarq={key="Q", range=1100, width=55, physical=true},
		gnarqmissile={"gnarq"},
		gnarbigq={key="Q", range=1100, width=90, physical=true},
		gnarbigqmissile={"gnarbigq"},
		gnarbigw={},
		gnare={type="dash", range=475, ends="point", physical=true},
		gnarbige={type="dash", range=475, ends="point", physical=true},
		gnarr={},
	},

	Graves = {
		gravesclustershot={range=750, radius=50, time=1, ss=true, isline=true, physical=true},
		gravessmokegrenade={range=700, radius=275, time=1.5, ss=true, isline=false},
		gravessmokegrenadeboom={},
      gravesmove={type="dash", ends="max", range=425},
		graveschargeshot={range=1000, radius=110, time=1, ss=true, isline=true, physical=true},
	},

	Gragas = {
		gragasq={range=850, radius=320, time=2.5, ss=true, show=true, isline=false},
		gragasqtoggle={},
		gragasw={},
		gragase={range=650, radius=150, time=1.5, ss=true, isline=true, point=true, block=true, cc=STUN},
		gragasr={range=1050, radius=400, time=1.5, ss=true, isline=false, cc=KNOCK},
	},
   Hecarim={
      hecarimult={type="dash", ends="point", range=1000},
      hecarimramp={},
      hecarimw={},
      hecarimrapidslash={},
      hecarimramp={},
   },
	Heimerdinger = {
		heimerdingerq={key="Q"},
		heimerdingerw={key="W"},
		heimerdingere={key="E", range=950, radius=225, time=2, ss=true, show=true, isline=false, cc=STUN},
		heimerdingerr={key="R"},
		heimerdingereult={key="E"},
	},
	Irelia = {
		ireliatranscendentblades={range=1200, radius=80, time=0.8, ss=true, isline=true},
		ireliaequilibriumstrike={cc=STUN},
      ireliagatotsu={type="dash", ends="target"},
      ireliahitenstyle={},
	},
	Janna = {
		howlinggale={range=1700, radius=100, time=3, ss=true, show=true, isline=true, dodgeByObject=true},
		sowthewind={cc=SLOW},
      reapthewhirlwind={type="stall", duration=2},
      eyeofthestorm={},
	},
	JarvanIV = {
		jarvanivdragonstrike={range=770, radius=70, time=1, ss=true, isline=true, cc=KNOCK, physical=true},
		jarvanivdemacianstandard={range=830, radius=150, time=2, ss=true, isline=false},
		jarvanivcataclysm={
			range=650, radius=300, time=1.5, ss=true, isline=false, physical=true,
			type="dash", ends="point"
		},
		jarvanivgoldenaegis={},
	},
   Jax={
      jaxleapstrike={key="Q", type="dash", ends="target", overShoot=-50},
      jaxempowertwo={key="W"},
      jaxcounterstrike={key="E"},
      jaxrelentlessassault={},
   },
	Jayce = {
		jayceaccelerationgate={},
		jaycestancegth={},
		jaycestancehtg={},
      jaycetotheskies={type="dash", ends="target"},
		jaycestaticfield={},
		jaycehypercharge={},
		jaycethunderingblow={},
		jayceshockblast={range=1470, radius=100, time=1, ss=true, show=true, isline=true, block=true, physical=true},
	},
	Jinx = {
		jinxq={key="Q"},
      jinxw={key="W", type="stall"},
		jinxwmissile={key="W", range=1500, radius=80, time=1.5, ss=true, show=true, isline=true, block=true, perm=true, physical=true, cc=SLOW},
		jinxe={key="E"},
		jinxr={
			key="R", range=50000, radius=150, time=4, ss=true, show=true, isline=true, physical=true, dodgeByObject=true,
			type="stall"
		},
	},
	Kalista = {
		kalistaw={},
		kalistar={},
		kalistarx={},
		kalistamysticshot={},
		kalistaexpungewrapper={},
		kalistaexpunge={},
		kalistamysticshotmis={},
	},
	Karma = {
		karmaq={key="Q"},
		karmasolkimshield={key="E"},
		karmamantra={key="R"},
		karmaspiritbind={},
	},
	Karthus = {
		laywaste={key="Q", range=875, radius=150, time=1, ss=true, isline=false},
		karthuslaywastea1={"laywaste"},
		karthuslaywastea2={"laywaste"},
		karthuslaywastea3={"laywaste"},
		karthuslaywastedeada1={"laywaste"},
		karthuslaywastedeada2={"laywaste"},
		karthuslaywastedeada3={"laywaste"},
		karthusdefile={key="E"},
		karthuswallofpain={key="W"},
		karthuswallofpain2={key="W"},
		karthusfallenone={key="R"},
		karthusfallenone2={key="R"},
		karthusdeathdefiedbuff={},
	},
	Kassadin = {
		nulllance={cc=SILENCE},
		forcepulse={cc=SLOW},
		riftwalk={
			range=700, radius=150, time=1, ss=true, isline=true, point=true,
			type="dash", ends="point"
		},
		netherblade={},
	},
	Katarina = {
		katarinaq={},
		katarinaw={},
      katarinae={type="dash", ends="target"},
      katarinar={type="stall"},
	},
	Kayle = {
		judicatorreckoning={cc=SLOW},
		judicatorrighteousfury={},
		judicatordivineblessing={},
		judicatorintervention={},
	},	
	Kennen = {
		kennenshurikenhurlmissile1={range=1050, radius=75, time=1, ss=true, isline=true, block=true},
		kennenshurikenstorm={}, --TODO
		kennenbringthelight={},
		kennenmegaproc={},
		kennenlightningrush={},
		kennenlrcancel={},
	},
	Khazix = {
		khazixq={},
		khazixqevo={},
		khazixqlong={},
		khazixw={range=1000, radius=120, time=0.5, ss=true, isline=true, cc=SLOW, physical=true},
		khazixwlong={range=1000, radius=150, time=1, ss=true, isline=true, cc=SLOW, physical=true},
		khazixwevo={},
		khazixe={
			range=600, radius=200, time=1, ss=true, isline=false, physical=true,
			type="dash", ends="point"
		},
		khazixelong={
			range=900, radius=200, time=1, ss=true, isline=false, physical=true,
			type="dash", ends="point"
		},
		khazixeevo={},
		khazixr={},
	},
	Kindred={

	},
	KogMaw = {
		kogmawq={},--TODO
		kogmawqmis={},
		kogmawvoidooze={},
		kogmawvoidoozemissile={range=1150, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		kogmawlivingartillery={range=2200, radius=200, time=1.5, ss=true, show=true, isline=false},
		kogmawbioarcanebarrage={},
	},
	Leblanc = {
		leblancsoulshackle={range=1000, radius=80, time=1, ss=true, isline=true, block=true, cc=BIND},
		leblancsoulshacklem={range=1000, radius=80, time=1, ss=true, isline=true, block=true, cc=BIND},
		leblancslide={
			range=600, radius=250, time=1, ss=true, isline=false,
			type="dash", ends="point"
		},
		leblancslidem={
			range=600, radius=250, time=1, ss=true, isline=false,
			type="dash", ends="point"
		},
		leblancslidereturn={range=1000, radius=50, time=1, ss=true, isline=false},
		leblancslidereturnm={range=1000, radius=50, time=1, ss=true, isline=false},
		leblancchaosorb={},
		leblancchaosorbm={},
	},
	LeeSin = {
		blindmonkqone={key="Q", range=975, radius=150, time=1, ss=true, block=true, perm=true, isline=true, block=true, physical=true},
		blindmonkrkick={range=1200, radius=100, time=1, ss=true, isline=true, physical=true},
      blindmonkqtwo={type="dash", ends="target"},
      blindmonkwone={type="dash", ends="target"},
      blindmonkwtwo={type="dash", ends="target"},
      blindmonkeone={},
      blindmonketwo={},
	},
	Leona = {
		leonazenithblademissile={range=700, radius=150, time=1, ss=true, isline=true},
      leonazenithblade={}, --{type="dash", ends="target?"}, -- TODO
      leonasolarbarrier={},
      leonashieldofdaybreak={},
		leonasolarflare={cc=STUN},
	},
	Lissandra = { -- todo dash
		lissandraq={},
		lissandraqmissile={range=725, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		lissandraw={},
		lissandrae={range=1050, radius=100, time=1.5, ss=true, isline=true},
		lissandraemissile={},
		lissandrarenemy={},
		lissandrar={},
	},
	Lucian = {
		lucianq={range=1100, radius=100, time=0.75, ss=true, isline=true, physical=true},
		lucianw={range=1000, radius=150, time=1.5, ss=true, isline=true, physical=true},
      luciane={type="dash", ends="point", range=450},
		lucianr={range=1400, radius=250, time=3, ss=true, isline=true, physical=true},
		lucianrdisable={},
	},
	Lux = {
		luxlightbinding={key="Q", range=1175, radius=150, time=1, ss=true, isline=true, cc=BIND},
		luxlightstriketoggle={},
		luxlightstrikekugel={range=1100, radius=300, time=2.5, ss=true, show=true, isline=false, cc=SLOW},
		luxmalicecannon={
			range=3000, radius=180, time=1.5, ss=true, isline=true,
			type="stall"
		},
		luxmalicecannonmis={},
		luxprismaticwave={},
	},
	Lulu = {
		luluq={range=925, radius=50, time=1, ss=true, isline=true, cc=SLOW},
		luluqmissile={},
		luluw={},
		luluwtwo={},
		lulue={},
		lulur={},
	},
	Malphite = {
		seismicshard={cc=SLOW},
		ufslash={
			range=1000, radius=325, time=1, ss=true, show=true, isline=false, cc=KNOCK,
			type="dash", ends="point"
		},
		landslide={},
		obduracy={},
	},
	Malzahar = {
		alzaharcallofthevoid={range=900, radius=100, time=1, ss=true, isline=false, cc=SILENCE},
		alzaharnullzone={range=800, radius=250, time=1, ss=true, isline=false},
		alzaharmaleficvisions={},
      alzaharnethergrasp={
	      cc=STUN,
      	type="stall"
      },
	},
	Maokai = {
	 	maokaiunstablegrowth={
	 		cc=STUN,
	 		type="dash", ends="target"
	 	},
	 	maokaisapling2boom={},
	 	maokaitrunkline={},
	 	maokaidrain3={},
	 	maokaidrain3toggle={},
		maokaitrunklinemissile={range=600, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		maokaisapling2={range=1100, radius=350, time=1, ss=true, isline=false},
	},
   MasterYi={
   	alphastrike={},
      meditate={type="stall"},
      wujustyle={},
      masteryidoublestrike={},
      highlander={},
   },
	MissFortune = {
		missfortunericochetshot={physical=true},
		missfortunescattershot={range=800, radius=400, time=3, ss=true, isline=false},
      missfortunebullettime={tupe="stall"},
      missfortuneviciousstrikes={},
	},
   MonkeyKing={
   	monkeykingnimbus={type="dash", ends="target"},
   	monkeykingdecoy={},
   	monkeykingspintowin={},
   	monkeykingspintowinleave={},
	},

	Mordekaiser = {
		mordekaisersyphonofdestruction={},
		mordekaisercreepingdeathcast={},
		mordekaisermaceofspades={},
		mordekaiserchildrenofthegrave={},
	},
	Morgana = {
		darkbindingmissile={key="Q", range=1300, radius=110, time=1.5, ss=true, show=true, perm=true, block=true, isline=true, cc=BIND},
		tormentedsoil={range=900, radius=300, time=1.5, ss=true, isline=false},
		blackshield={},
		soulshackles={},
	},
	Nami = {
		namiq={range=875, radius=200, time=1.5, ss=true, show=true, isline=false, cc=STUN},
		namiqmissile={}, --TODO
		namir={range=2550, radius=350, time=3, ss=true, isline=true, cc=KNOCK},
		namirmissile={},
		namiw={},
		namie={},
	},
	Nasus = {
		nasusq={key="Q"}, -- siphon
		nasusw={key="W", cc=SLOW, nodamage=true},
		nasuse={key="W"}, -- spirit fire
		nasusr={key="R"},
	},
	Nautilus = {
		nautilusanchordrag={key="Q", range=950, radius=80, time=1.5, ss=true, perm=true, block=true, isline=true},
		nautilusanchordragmissile={},
		nautilusgrandline={cc=KNOCK},
		nautilussplashzone={},
		nautiluspiercinggaze={},
	},
	Nidalee = {
		javelintoss={key="Q", range=1500, radius=40, time=1.5, ss=true, block=true, perm=true, show=true, isline=true},
      pounce={type="dash", ends="max", range=375},
      bushwhack={},
      aspectofthecougar={},
      swipe={},
      takedown={},
      primalsurge={},
	},
	Nocturne = {
		nocturneduskbringer={range=1200, radius=150, time=1.5, ss=true, isline=true, physical=true},
		nocturneunspeakablehorror={},
		nocturneshroudofdarkness={},
		nocturneparanoia={},
	},
   Nunu={
      consume={type="stall"},
      absolutezero={type="stall"},
      iceblast={},
      bloodboil={},
   },
	Olaf = {
		olafaxethrow={range=1000, radius=100, time=1.5, ss=true, isline=true, point=true, cc=SLOW, physical=true},
		olafaxethrowcast={},
		olafrecklessstrike={},
		olaffrenziedstrikes={},
		olafragnarok={},
	},
	Orianna = {
		orianaredactcommand={},
		orianadetonatecommand={},
		orianadissonancecommand={},
		orianaizunacommand={range=825, radius=90, time=1.5, ss=true, isline=false},
	},
	Pantheon = {
		pantheonq={key="Q", physical=true},
      pantheonw={key="W", type="dash", ends="target", overShoot=-50},
      pantheone={key="E"},
      pantheonrfall={key="R"},
      pantheonrjump={key="R"},
	},
   Poppy={
      poppye={key="Q"},
--      poppyw={type="dash", ends="target", overShoot=300},
      poppye={},
      poppyr={key="R"},
   },
  	Quinn = {
  		quinnq={key="Q"},
		quinnqmissile={key="Q", range=1025, radius=40, time=1, ss=true, isline=true, cc=BLIND, physical=true},
		quinnvalorq={},
		quinnw={},
		quinne={},
		quinnwenhanced={},
		quinnvalore={},
		quinnr={},
		quinnrfinale={},
	},
	Rammus = {
		puncturingtaunt={cc=TAUNT, nodamage=true},
		powerball={},
		defensiveballcurl={},
		tremors2={},
	},
	RekSai = {

	},
	Renekton = {
		-- RenektonSliceAndDice={range=450, radius=80, time=1, ss=true, isline=true, physical=true},
		-- renektondice={range=450, radius=80, time=1, ss=true, isline=true, physical=true},
      renektonsliceanddice={type="dash", ends="max", range=450},
      renektondice={type="dash", ends="max", range=450},
      renektoncleave={},
      renektonpreexecute={},
      renektonsuperexecute={},
      renektonreignofthetyrant={},
      renektonexecute={},
  	},
	Rengar = {
		rengarq={key="Q"},
		rengarw={key="W"},
		rengare={key="E", cc=STUN, physical=true},
		rengarefinal={key="E"},
		rengarefinalmax={},
		rengarr={key="R"},
	},
   Riven={
      rivenfeint={type="dash", ends="max", range=325},
      rivenmartyr={},
      riventricleave={type="dash", ends="point", range=325},
      rivenfengshuiengine={},
      rivenizunablade={},
      riventricleavebuffer={}
   },
 	Rumble = {
		rumblegrenademissile={range=1000, radius=100, time=1.5, ss=true, isline=true},
		rumbleshield={},
		rumblecarpetbomb={range=1700, radius=100, time=1.5, ss=true, isline=true},
		rumblegrenade={},
		rumbleflamethrower={},
	},
	Ryze = {
		ryzeq={},
		ryzerq={},
		ryzew={cc=BIND},
		ryzerw={cc=BIND},
		ryzee={},
		ryzere={},
		ryzer={},
		ryzepassivespell={},
	},
	Sejuani = {
		sejuaniglacialprison={range=1150, radius=180, time=1, ss=true, isline=true, cc=STUN},
		sejuaninorthernwinds={},
		sejuaniwintersclaw={},
		sejuaniarcticassault={},
		sejuaniglacialprisonstart={},
		sejuaniglacialprisoncast={},
		sejuaninorthernwindsremoval={},
	},
	Shaco = {
		deceive={
			range=400, radius=100, time=3.5, ss=true, isline=false, nodamage=true,
			type="dash", ends="point"
		},
		hallucinatefull={},
		jackinthebox={},
		twoshivpoison={},
		hallucinateguide={},
	},
	Shen = {
		shenshadowdash={
			range=600, radius=150, time=1, ss=true, isline=true, point=true, cc=TAUNT, nodamage=true,
			type="dash", ends="max"
		},
      shenstandunited={type="stall"},
      shenfeint={},
      shenvorpalstar={},
	},
	Shyvana = {
   	shyvanatransformcast={type="dash", ends="point", range=1000},	
		shyvanatransformleap={range=925, radius=150, time=1.5, ss=true, isline=true},
		shyvanafireball={},
		shyvanafireballdragon2={},
		shyvanafireballmissile={range=1000, radius=80, time=1, ss=true, isline=true},
		shyvanaimmolationaura={},
		shyvanaimmolatedragon={},
	},
	Sion = {
		sionq={key="Q", type="stall"},
		sionw={key="W"},
		sione={key="E"},
		sionr={},
		sionpassivespeed={},
		sionwdetonate={},
  	},
	Sivir = {
		sivirq={key="Q", range=1000, radius=100, time=1, ss=true, isline=true, physical=true},
		-- spiralblade={key="Q", range=1000, radius=100, time=1, ss=true, isline=true, physical=true},
		sivirw={},
		sivire={},
		sivirr={},
	},
	Singed = {
		megaadhesive={range=1000, radius=350, time=1.5, ss=true, isline=false, cc=SLOW},
		poisontrail={},
		fling={},
	},
	Skarner = {
		skarnerfracture={range=600, radius=100, time=1, ss=true, isline=true},
		skarnerimpale={cc=GRAB},
	},
	Sona = {
		sonaq={},
		sonaw={},
		sonae={},
		sonar={range=1000, radius=350, time=1, ss=true, isline=true, cc=STUN},
	},
	Soraka = {
		sorakaq={},
		sorakaw={},
		sorakawparticlemissile={},
		sorakae={},
		sorakar={},
	},
	Swain = {
		swainshadowgrasp={range=900, radius=265, time=1.5, ss=true, isline=false, cc=STUN},
		swaintorment={},
		swaindecrepify={},
		swainmetamorphism={},
	},
	Syndra = {
		syndraq={range=800, radius=200, time=1, ss=true, isline=false},
		syndraw={},
		syndrawcast={range=950, radius=200, time=1, ss=true, isline=false, cc=SLOW},
		syndrae={range=650, radius=100, time=0.5, ss=true, isline=true, cc=STUN},
		syndrar={},
		syndrarcasttime={},
		syndrae5={},
	},
	TahmKench = {

	},
	Talon={
		taloncutthroat={type="dash", ends="target"},
		talonrake={},
		talonnoxiandiplomacy={},
		talonshadowassault={},
		talonrakemissileone={},
		talonshadowassaulttoggle={},
	},
	Taric = {
		dazzle={cc=STUN},
		shatter={},
		imbue={},
		tarichammersmash={},
	},
	Teemo = {
		movequick={},
		blindingdart={cc=BLIND},
		teemorcast={},
	},
	Thresh = {
		threshq={key="Q", range=1100, radius=100, time=1.5, ss=true, show=true, block=true, perm=true, isline=true, cc=STUN},
		threshqinternal={},
		threshqleap={--[[type="dash"]]},
		threshw={},
      threshe={type="stall"},
      threshrpenta={type="stall"},
  	},
	Tristana = {
		tristanaq={},
		tristanaw={
			range=900, radius=200, time=1, ss=true, isline=false,
			type="dash", ends="point"
		},
		tristanae={},
		tristanar={cc=KNOCK},
	},
	Trundle = {
		trundleq={},
		trundletrollsmash={},
		trundledesecrate={},
		trundlecircle={},
		trundlepain={},
	},
	Tryndamere = {
		slashcast={},
		slash={
			range=660, radius=100, time=1, ss=true, isline=true, point=true, physical=true,
			type="dash", ends="point"
		},
		mockingshout={},
		undyingrage={},
		bloodlust={},
	},
	TwistedFate = {
		redcard={cc=SLOW},
		yellowcard={cc=STUN},
		wildcards={range=1450, radius=80, time=1, ss=true, show=true, isline=true},
		pickacard={},
		goldcardlock={},
		bluecardlock={},
		redcardlock={},
		destiny={},
		gate={},
	},
	Twitch = {
		twitchvenomcask={cc=SLOW, nodamage=true},
		twitchvenomcaskmissile={},
		twitchhideinshadows={},
		twitchexpunge={},
		twitchfullautomatic={},
	},
	Udyr={
		udyrbearstance={},
		udyrtigerstance={},
		udyrturtlestance={},
		udyrphoenixstance={},
	},
	Urgot = {
		urgotheatseekingmissile={},
		urgotheatseekinghomemissile={},
		urgotheatseekinglinemissile={range=1000, radius=80, time=0.8, ss=true, isline=true, block=true, physical=true},
		urgotplasmagrenade={range=950, radius=300, time=1, ss=true, isline=false, physical=true},
		urgotplasmagrenadeboom={},
		urgotterrorcapacitoractive2={},
		urgotswap2={},
	},
	Vayne = {
		vaynecondemn={cc=KNOCK, physical=true},
		vaynecondemnmissile={},
      vaynetumble={type="dash", ends="max", range=300},
      vayneinquisition={},
	},
	Varus = {
		varusq={range=1475, radius=50, time=1, ss=true, isline=true, physical=true},
		varuse={},
		varusr={range=1075, radius=80, time=1.5, ss=true, isline=true, cc=STUN},
		varusemissile={},
	},
	Veigar = {
		veigarbalefulstrike={},
		veigardarkmatter={range=900, radius=225, time=2, ss=true, show=true, isline=false},
		veigareventhorizon={cc=STUN},	
		veigarprimordialburst={},
	},
   Velkoz={
   	-- ult={type="stall"},
   	-- TODO get obj for channel
   	velkozq={},
   	velkozqsplitactivate={},
   	velkozw={},
   	velkoze={},
   	velkozr={type="stall"},
	},	
	Vladimir = {
		vladimirq={},
		vladimirw={},
		vladimire={},
		vladimirr={},
	},
	Volibear = {
		volibearq={cc=KNOCK, physical=true},
		volibearw={},
		volibeare={},
		volibearr={}
	},
	Vi = {
		viq={range=900, radius=150, time=1, ss=true, isline=true, physical=true}, -- TODO dash stuff
		vie={},
		vir={},
		assaultandbattery={cc=KNOCK, physical=true},
	},
	Viktor = {
		viktorqbuff={},
		viktordeathray={}, --{range=700, radius=80, time=2, ss=true, isline=true},
		viktorgravitonfield={},
		viktorpowertransfer={},
		viktorchaosstorm={},
		viktorchaosstormguide={},
	},
   Warwick={
   	warwickq={},
   	warwickw={},
   	warwicke={},
   	warwickr={},
   },	
	Xerath = {
		xerathlocuspulse={},
		xerathmagespear={},
		xeratharcanopulse2={range=1500, radius=80, time=1, ss=true, show=true, isline=true},
		xeratharcanebarrage2={range=1100, radius=200, time=1, ss=true, isline=false},
		xerathrmissilewrapper={range=5600, radius=150, time=1, ss=true, isline=false},
		xerathlocusofpower2={type="stall"},
      xeratharcanopulsechargeup={type="stall"},
      xerathmagespearmissile={},
  	},
   XinZhao={
      xenzhaosweep={type="dash", ends="target"},
      xenzhaobattlecry={},
      xenzhaocombotarget={},
      xenzhaothrust={},
      xenzhaothrust2={},
      xenzhaothrust3={},
      xenzhaoparry={},
   },
   Yasuo={
      yasuodashwrapper={type="dash", ends="max", range=300},
      yasuowmovingwall={},
      yasuoqw={},
      yasuoq={},
      yasuoq2w={},
      yasuoq3w={},
      yasuoq2={},
      yasuoq3={},
      yasuodummyspell={},
      yasuorknockupcombow={},
      yasuordummyspell={},
      tempyasuormissile={},
   },
	Yorick = {
		yorickdecayed={},
		yoricksummondecayed={},
		yorickravenous={},
		yoricksummonravenous={},
		yorickspectral={},
		yorickreviveally={},
		yorickreviveallyguide={},
	},
  	Zac = {
		zacq={range=550, radius=100, time=1, ss=true, isline=true, cc=SLOW},
		zacw={},
		zace={range=1550, radius=200, time=2, ss=true, isline=false, cc=KNOCK},
		zacr={},
	},
	Zed = {
		zedshuriken={range=900, radius=100, time=1, ss=true, isline=true, physical=true},
		zedshadowdash={range=550, radius=150, time=1, ss=true, isline=true, point=true, physical=true},
		zedw2={range=550, radius=150, time=0.5, ss=true, isline=false, physical=true},
		zedpbaoedummy={},
		zedult={},
		zedr2={},
	},
	Ziggs = {
		ziggsq={range=1100, radius=150, time=1.5, ss=true, show=true, isline=true, point=true, block=true},
		ziggsqspell={},
		ziggsw={range=1000, radius=225, time=1, ss=true, isline=false, cc=KNOCK},
		ziggswtoggle={},
		ziggse={range=900, radius=250, time=1, ss=true, isline=false, cc=SLOW},
		ziggse2={},
		ziggsr={range=5300, radius=550, time=3, ss=true, isline=false},
	},
	Zilean = {
		zileanq={},
		rewind={},
		timewarp={},
		timebomb={},
		zileanqattachaudio={},
		chronoshift={},
	},
	Zyra = {
		ZyraQ={key="Q", range=800, radius=275, time=1.5, ss=true},
		ZyraW={key="W"},
		ZyraE={key="E", range=1100, radius=90, time=2, ss=true, show=true, isline=true, cc=BIND},
		zyrabramblezone={key="R", cc=KNOCK},
		zyrapassivedeathmanager={},
	},
}

function GetSpellDef(name, spellName)
	local spellTable = SPELL_DEFS[name]
	if spellTable then
		local spellDef = spellTable[string.lower(spellName)]
		if spellDef then
			if type(spellDef[1]) == "string" then
				spellDef = spellTable[spellDef[1]]
			end
			spellDef.name = spellName
			if not spellDef.time then
				spellDef.time = 1
			end
			if not spellDef.radius then
				spellDef.radius = 0
			end
			spellDef.radius = spellDef.radius or spellDef.width * 2
			return spellDef
		else
			for _,ignored in ipairs(ignoredSpells) do
				if find(spellName, ignored) then
					return
				end
			end
			log("No def for "..name, "spelldefs")
			log(string.lower(spellName).."={},", "spelldefs")
			print("Spell Def needed: "..name.." "..spellName)
			table.insert(ignoredSpells, spellName)
		end
	else
		print("No defs for "..name)
		log("No defs for "..name, "spelldefs")
	end
	return nil
end
