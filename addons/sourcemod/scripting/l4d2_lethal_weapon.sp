/******************************************************
* 				L4D2: Lethal Weapon v2.3
*					Author: ztar
* 			Web: http://ztar.blog7.fc2.com/
*******************************************************/
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.3"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define MOLOTOV 0
#define EXPLODE 1

new ChargeLock[65];
new ReleaseLock[65];
new CurrentWeapon;
new ClipSize;
new ChargeEndTime[65];
new Handle:ClientTimer[65];
new g_sprite;
new Float:myPos[3], Float:trsPos[3], Float:trsPos002[3];
new UnlockFlag[4];

/* Sound */
#define CHARGESOUND 	"ambient/spacial_loops/lights_flicker.wav"
#define CHARGEDUPSOUND	"level/startwam.wav"
#define AWPSHOT			"weapons/awp/gunfire/awp1.wav"
#define EXPLOSIONSOUND	"animation/bombing_run_01.wav"

/* Sprite */
#define SPRITE_BEAM		"materials/sprites/laserbeam.vmt"

new Handle:l4d2_lw_lethalweapon		= INVALID_HANDLE;
//new Handle:l4d2_lw_lethaldamage		= INVALID_HANDLE;
new Handle:l4d2_lw_lethalforce		= INVALID_HANDLE;
//new Handle:l4d2_lw_chargetime		= INVALID_HANDLE;
new Handle:l4d2_lw_shootonce		= INVALID_HANDLE;
new Handle:l4d2_lw_ff				= INVALID_HANDLE;
new Handle:l4d2_lw_scout			= INVALID_HANDLE;
new Handle:l4d2_lw_awp				= INVALID_HANDLE;
new Handle:l4d2_lw_huntingrifle		= INVALID_HANDLE;
new Handle:l4d2_lw_g3sg1			= INVALID_HANDLE;
new Handle:l4d2_lw_flash			= INVALID_HANDLE;
new Handle:l4d2_lw_chargingsound	= INVALID_HANDLE;
new Handle:l4d2_lw_chargedsound		= INVALID_HANDLE;
new Handle:l4d2_lw_moveandcharge	= INVALID_HANDLE;
new Handle:l4d2_lw_chargeparticle	= INVALID_HANDLE;
new Handle:l4d2_lw_useammo			= INVALID_HANDLE;
new Handle:l4d2_lw_shake			= INVALID_HANDLE;
new Handle:l4d2_lw_shake_intensity	= INVALID_HANDLE;
new Handle:l4d2_lw_shake_shooteronly= INVALID_HANDLE;
new Handle:l4d2_lw_laseroffset		= INVALID_HANDLE;
new Handle:l4d2_lw_walkkey			= INVALID_HANDLE;
new Handle:l4d2_lw_randomweapon		= INVALID_HANDLE;
new Handle:l4d2_lw_selfdamage		= INVALID_HANDLE;

//101015 Added
new Handle:l4d2_lw_scout_attack		= INVALID_HANDLE;
new Handle:l4d2_lw_awp_attack		= INVALID_HANDLE;
new Handle:l4d2_lw_hunting_attack	= INVALID_HANDLE;
new Handle:l4d2_lw_g3sg1_attack		= INVALID_HANDLE;
new Handle:l4d2_lw_scout_charge		= INVALID_HANDLE;
new Handle:l4d2_lw_awp_charge		= INVALID_HANDLE;
new Handle:l4d2_lw_hunting_charge	= INVALID_HANDLE;
new Handle:l4d2_lw_g3sg1_charge		= INVALID_HANDLE;
new Handle:l4d2_lw_scout_explode	= INVALID_HANDLE;
new Handle:l4d2_lw_awp_explode		= INVALID_HANDLE;
new Handle:l4d2_lw_hunting_explode	= INVALID_HANDLE;
new Handle:l4d2_lw_g3sg1_explode	= INVALID_HANDLE;
new Handle:l4d2_lw_scout_molotov	= INVALID_HANDLE;
new Handle:l4d2_lw_awp_molotov		= INVALID_HANDLE;
new Handle:l4d2_lw_hunting_molotov	= INVALID_HANDLE;
new Handle:l4d2_lw_g3sg1_molotov	= INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[L4D2] Lethal Weapon",
	author = "ztar",
	description = "Sniper rifles can be charged up and fired to create a huge explosion",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1121995"
}

public OnPluginStart()
{
	// ConVars
	l4d2_lw_lethalweapon	= CreateConVar("l4d2_lw_lethalweapon","1", "Enable Lethal Weapon (0:OFF 1:ON 2:SIMPLE)", CVAR_FLAGS);
//	l4d2_lw_lethaldamage	= CreateConVar("l4d2_lw_lethaldamage","3000.0", "Lethal Weapon base damage", CVAR_FLAGS);
	l4d2_lw_lethalforce		= CreateConVar("l4d2_lw_lethalforce","500.0", "Lethal Weapon force", CVAR_FLAGS);
//	l4d2_lw_chargetime		= CreateConVar("l4d2_lw_chargetime","7", "Lethal Weapon charge time", CVAR_FLAGS);
	l4d2_lw_shootonce		= CreateConVar("l4d2_lw_shootonce","0", "Survivor can use Lethal Weapon once per round", CVAR_FLAGS);
	l4d2_lw_ff				= CreateConVar("l4d2_lw_ff","0", "Lethal Weapon can deal direct damage to other survivors", CVAR_FLAGS);
	l4d2_lw_scout			= CreateConVar("l4d2_lw_scout","1", "Enable Lethal Weapon for Scout", CVAR_FLAGS);
	l4d2_lw_awp				= CreateConVar("l4d2_lw_awp","1", "Enable Lethal Weapon for AWP", CVAR_FLAGS);
	l4d2_lw_huntingrifle	= CreateConVar("l4d2_lw_huntingrifle","1", "Enable Lethal Weapon for Hunting Rifle", CVAR_FLAGS);
	l4d2_lw_g3sg1			= CreateConVar("l4d2_lw_g3sg1","1", "Enable Lethal Weapon for G3SG1", CVAR_FLAGS);
	l4d2_lw_laseroffset		= CreateConVar("l4d2_lw_laseroffset", "36", "Tracker offeset", FCVAR_NOTIFY);
	
	// Additional ConVars
	l4d2_lw_flash				= CreateConVar("l4d2_lw_flash", "1", "Enable screen flash");
	l4d2_lw_chargingsound		= CreateConVar("l4d2_lw_chargingsound", "1", "Enable charging sound");
	l4d2_lw_chargedsound		= CreateConVar("l4d2_lw_chargedsound", "1", "Enable charged up sound");
	l4d2_lw_moveandcharge		= CreateConVar("l4d2_lw_moveandcharge", "1", "Enable charging while crouched and moving");
	l4d2_lw_chargeparticle		= CreateConVar("l4d2_lw_chargeparticle", "1", "Enable showing electric particles when charged");
	l4d2_lw_useammo				= CreateConVar("l4d2_lw_useammo", "1", "Enable and require use of addtional ammunition");
	l4d2_lw_shake				= CreateConVar("l4d2_lw_shake", "1", "Enable screen shake during explosion");
	l4d2_lw_shake_intensity		= CreateConVar("l4d2_lw_shake_intensity", "50.0", "Intensity of screen shake");
	l4d2_lw_shake_shooteronly	= CreateConVar("l4d2_lw_shake_shooteronly", "0", "Only the shooter experiences screen shake");
	l4d2_lw_walkkey				= CreateConVar("l4d2_lw_walkkey", "0", "Push walk key to charge instead of ducking key");
	l4d2_lw_randomweapon		= CreateConVar("l4d2_lw_randomweapon", "0", "Only one kind of weapon can shoot LW per chapter");
	l4d2_lw_selfdamage			= CreateConVar("l4d2_lw_selfdamage", "0", "Self damage when shoot");
	
	// About weapon spec
	l4d2_lw_scout_attack	= CreateConVar("l4d2_lw_scout_attack","1800", "Scout:Damage", CVAR_FLAGS);
	l4d2_lw_awp_attack		= CreateConVar("l4d2_lw_awp_attack","3000", "AWP:Damage", CVAR_FLAGS);
	l4d2_lw_hunting_attack	= CreateConVar("l4d2_lw_hunting_attack","1000", "HuntingRifle:Damage", CVAR_FLAGS);
	l4d2_lw_g3sg1_attack	= CreateConVar("l4d2_lw_g3sg1_attack","2200", "G3SG1:Damage", CVAR_FLAGS);
	l4d2_lw_scout_charge	= CreateConVar("l4d2_lw_scout_charge","4", "Scout:Charge time", CVAR_FLAGS);
	l4d2_lw_awp_charge		= CreateConVar("l4d2_lw_awp_charge","8", "AWP:Charge time", CVAR_FLAGS);
	l4d2_lw_hunting_charge	= CreateConVar("l4d2_lw_hunting_charge","5", "HuntingRifle:Charge time", CVAR_FLAGS);
	l4d2_lw_g3sg1_charge	= CreateConVar("l4d2_lw_g3sg1_charge","7", "G3SG1:Charge time", CVAR_FLAGS);
	l4d2_lw_scout_explode	= CreateConVar("l4d2_lw_scout_explode","1", "Scout:Explode", CVAR_FLAGS);
	l4d2_lw_awp_explode		= CreateConVar("l4d2_lw_awp_explode","1", "AWP:Explode", CVAR_FLAGS);
	l4d2_lw_hunting_explode	= CreateConVar("l4d2_lw_hunting_explode","1", "HuntingRifle:Explode", CVAR_FLAGS);
	l4d2_lw_g3sg1_explode	= CreateConVar("l4d2_lw_g3sg1_explode","1", "G3SG1:Explode", CVAR_FLAGS);
	l4d2_lw_scout_molotov	= CreateConVar("l4d2_lw_scout_molotov","0", "Scout:Molotov", CVAR_FLAGS);
	l4d2_lw_awp_molotov		= CreateConVar("l4d2_lw_awp_molotov","1", "AWP:Molotov", CVAR_FLAGS);
	l4d2_lw_hunting_molotov	= CreateConVar("l4d2_lw_hunting_molotov","0", "HuntingRifle:Molotov", CVAR_FLAGS);
	l4d2_lw_g3sg1_molotov	= CreateConVar("l4d2_lw_g3sg1_molotov","1", "G3SG1:Molotov", CVAR_FLAGS);
	
	// Hooks
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("weapon_fire", Event_Weapon_Fire);
	HookEvent("bullet_impact", Event_Bullet_Impact);
	HookEvent("player_incapacitated", Event_Player_Incap, EventHookMode_Pre);
	HookEvent("player_hurt", Event_Player_Hurt, EventHookMode_Pre);
	HookEvent("player_death", Event_Player_Hurt, EventHookMode_Pre);
	HookEvent("infected_death", Event_Infected_Hurt, EventHookMode_Pre);
	HookEvent("infected_hurt", Event_Infected_Hurt, EventHookMode_Pre);
	HookEvent("round_end", Event_Round_End, EventHookMode_Pre);
	
	// Weapon stuff
	CurrentWeapon	= FindSendPropOffs ("CTerrorPlayer", "m_hActiveWeapon");
	ClipSize	= FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	
	InitCharge();
	
	AutoExecConfig(true, "l4d2_lethal_weapon");
}

public OnMapStart()
{
	InitPrecache();
	
	for(new i = 0; i <= 3; i++)
	{
		if(GetConVarInt(l4d2_lw_randomweapon))
			UnlockFlag[i] = 0;
		else
			UnlockFlag[i] = 1;
	}
	
	new UnlockNum;
	UnlockNum = GetRandomInt(0, 3);
	switch(UnlockNum)
	{
		case 0:
			UnlockFlag[0] = 1;
		case 1:
			UnlockFlag[1] = 1;
		case 2:
			UnlockFlag[2] = 1;
		case 3:
			UnlockFlag[3] = 1;
	}
}

public OnConfigsExecuted()
{
	InitPrecache();
}

InitCharge()
{
	/* Initalize charge parameter */
	new i;
	for (i = 1; i <= GetMaxClients(); i++)
	{
		ChargeEndTime[i] = 0;
		ReleaseLock[i] = 0;
		ChargeLock[i] = 0;
		ClientTimer[i] = INVALID_HANDLE;
	}
	for (i = 1; i <= GetMaxClients(); i++)
	{
		if (IsValidEntity(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
				ClientTimer[i] = CreateTimer(0.5, ChargeTimer, i, TIMER_REPEAT);
		}
	}
}

InitPrecache()
{
	/* Precache models */
	PrecacheModel("models/props_junk/propanecanister001a.mdl", true);
	PrecacheModel("models/props_junk/gascan001a.mdl", true);
	
	/* Precache sounds */
	PrecacheSound(CHARGESOUND, true);
	PrecacheSound(CHARGEDUPSOUND, true);
	PrecacheSound(AWPSHOT, true);
	PrecacheSound(EXPLOSIONSOUND, true);
	
	/* Precache particles */
	PrecacheParticle("gas_explosion_main");
	PrecacheParticle("electrical_arc_01_cp0");
	PrecacheParticle("electrical_arc_01_system");
	
	g_sprite = PrecacheModel(SPRITE_BEAM);
}

public Action:Event_Round_End(Handle:event, String:event_name[], bool:dontBroadcast)
{
	/* Timer end */
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (ClientTimer[i] != INVALID_HANDLE)
		{
			CloseHandle(ClientTimer[i]);
			ClientTimer[i] = INVALID_HANDLE;
		}
		if (IsValidEntity(i) && IsClientInGame(i))
		{
			ChargeEndTime[i] = 0;
			ReleaseLock[i] = 0;
			ChargeLock[i] = 0;
		}
	}
}

public Action:Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Timer start */
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client > 0 && client <= GetMaxClients())
	{
		if (IsValidEntity(client) && IsClientInGame(client))
		{
			if (GetClientTeam(client) == 2)
			{
				if (ClientTimer[client] != INVALID_HANDLE)
					CloseHandle(ClientTimer[client]);
				ChargeLock[client] = 0;
				ClientTimer[client] = CreateTimer(0.5, ChargeTimer, client, TIMER_REPEAT);
			}
		}
	}
}

public Action:Event_Player_Incap(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Reset client condition */
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ReleaseLock[client] = 0;
	
	new String:weapon[32];
	GetClientWeapon(client, weapon, 32);
	new ct;
	
	if(StrEqual(weapon, "weapon_sniper_scout"))
		ct = GetConVarInt(l4d2_lw_scout_charge);
	else if(StrEqual(weapon, "weapon_sniper_awp"))
		ct = GetConVarInt(l4d2_lw_awp_charge);
	else if(StrEqual(weapon, "weapon_hunting_rifle"))
		ct = GetConVarInt(l4d2_lw_hunting_charge);
	else if(StrEqual(weapon, "weapon_sniper_military"))
		ct = GetConVarInt(l4d2_lw_g3sg1_charge);
	
	ChargeEndTime[client] = RoundToCeil(GetGameTime()) + ct;
}

public Action:Event_Bullet_Impact(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (ReleaseLock[client])
	{
		new String:weapon[32];
		GetClientWeapon(client, weapon, 32);
		
		new bomb, fire;
		
		if(StrEqual(weapon, "weapon_sniper_scout"))
		{
			bomb = GetConVarInt(l4d2_lw_scout_explode);
			fire = GetConVarInt(l4d2_lw_scout_molotov);
		}
		else if(StrEqual(weapon, "weapon_sniper_awp"))
		{
			bomb = GetConVarInt(l4d2_lw_awp_explode);
			fire = GetConVarInt(l4d2_lw_awp_molotov);
		}
		else if(StrEqual(weapon, "weapon_hunting_rifle"))
		{
			bomb = GetConVarInt(l4d2_lw_hunting_explode);
			fire = GetConVarInt(l4d2_lw_hunting_molotov);
		}
		else if(StrEqual(weapon, "weapon_sniper_military"))
		{
			bomb = GetConVarInt(l4d2_lw_g3sg1_explode);
			fire = GetConVarInt(l4d2_lw_g3sg1_molotov);
		}
		
		decl Float:TargetPosition[3];
		
		TargetPosition[0] = GetEventFloat(event,"x");
		TargetPosition[1] = GetEventFloat(event,"y");
		TargetPosition[2] = GetEventFloat(event,"z");
		
		/* Explode effect */
		ExplodeMain(TargetPosition, bomb, fire);
	}
	return Plugin_Continue;
}

public Action:Event_Infected_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (ReleaseLock[client])
	{
		new String:weapon[32];
		GetClientWeapon(client, weapon, 32);
		
		new bomb, fire;
		
		if(StrEqual(weapon, "weapon_sniper_scout"))
		{
			bomb = GetConVarInt(l4d2_lw_scout_explode);
			fire = GetConVarInt(l4d2_lw_scout_molotov);
		}
		else if(StrEqual(weapon, "weapon_sniper_awp"))
		{
			bomb = GetConVarInt(l4d2_lw_awp_explode);
			fire = GetConVarInt(l4d2_lw_awp_molotov);
		}
		else if(StrEqual(weapon, "weapon_hunting_rifle"))
		{
			bomb = GetConVarInt(l4d2_lw_hunting_explode);
			fire = GetConVarInt(l4d2_lw_hunting_molotov);
		}
		else if(StrEqual(weapon, "weapon_sniper_military"))
		{
			bomb = GetConVarInt(l4d2_lw_g3sg1_explode);
			fire = GetConVarInt(l4d2_lw_g3sg1_molotov);
		}
		
		decl Float:TargetPosition[3];
		new target = GetClientAimTarget(client, false);
		if (target < 0)
			return Plugin_Continue;
		GetEntityAbsOrigin(target, TargetPosition);
		
		/* Explode effect */
		EmitSoundToAll(EXPLOSIONSOUND, target);
		ExplodeMain(TargetPosition, bomb, fire);
		
		/* Reset Lethal Weapon lock */
		ReleaseLock[client] = 0;
	}
	return Plugin_Continue;
}

public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	new dtype = GetEventInt(event, "type");
	
	if (ReleaseLock[client] && dtype != 268435464)
	{
		new String:weapon[32];
		GetClientWeapon(client, weapon, 32);
		
		new health = GetEventInt(event,"health");
		new damage, bomb, fire;
		
		if(StrEqual(weapon, "weapon_sniper_scout"))
		{
			damage = GetConVarInt(l4d2_lw_scout_attack);
			bomb = GetConVarInt(l4d2_lw_scout_explode);
			fire = GetConVarInt(l4d2_lw_scout_molotov);
		}
		else if(StrEqual(weapon, "weapon_sniper_awp"))
		{
			damage = GetConVarInt(l4d2_lw_awp_attack);
			bomb = GetConVarInt(l4d2_lw_awp_explode);
			fire = GetConVarInt(l4d2_lw_awp_molotov);
		}
		else if(StrEqual(weapon, "weapon_hunting_rifle"))
		{
			damage = GetConVarInt(l4d2_lw_hunting_attack);
			bomb = GetConVarInt(l4d2_lw_hunting_explode);
			fire = GetConVarInt(l4d2_lw_hunting_molotov);
		}
		else if(StrEqual(weapon, "weapon_sniper_military"))
		{
			damage = GetConVarInt(l4d2_lw_g3sg1_attack);
			bomb = GetConVarInt(l4d2_lw_g3sg1_explode);
			fire = GetConVarInt(l4d2_lw_g3sg1_molotov);
		}
		
		decl Float:AttackPosition[3];
		decl Float:TargetPosition[3];
		GetClientAbsOrigin(client, AttackPosition);
		GetClientAbsOrigin(target, TargetPosition);
		
		/* Explode effect */
		EmitSoundToAll(EXPLOSIONSOUND, target);
		ExplodeMain(TargetPosition, bomb, fire);
		
		/* Smash target */
		if (GetConVarInt(l4d2_lw_lethalweapon) != 2)
			Smash(client, target, GetConVarFloat(l4d2_lw_lethalforce), 1.5, 2.0);
		
		/* Deal lethal damage */
		if ((GetClientTeam(client) != GetClientTeam(target)) || GetConVarInt(l4d2_lw_ff))
			SetEntProp(target, Prop_Data, "m_iHealth", health - damage);
		
		/* Reset Lethal Weapon lock */
		ReleaseLock[client] = 0;
	}
	return Plugin_Continue;
}

public Action:Event_Weapon_Fire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new String:weapon[32];
	GetClientWeapon(client, weapon, 32);
	new ct;
	
	if(StrEqual(weapon, "weapon_sniper_scout"))
		ct = GetConVarInt(l4d2_lw_scout_charge);
	else if(StrEqual(weapon, "weapon_sniper_awp"))
		ct = GetConVarInt(l4d2_lw_awp_charge);
	else if(StrEqual(weapon, "weapon_hunting_rifle"))
		ct = GetConVarInt(l4d2_lw_hunting_charge);
	else if(StrEqual(weapon, "weapon_sniper_military"))
		ct = GetConVarInt(l4d2_lw_g3sg1_charge);
	
	ChargeEndTime[client] = RoundToCeil(GetGameTime()) + ct;
	
	if (ReleaseLock[client])
	{
		/* Flash screen */
		if (GetConVarInt(l4d2_lw_flash))
		{
			ScreenFade(client, 200, 200, 255, 255, 100, 1);
		}

		if (GetConVarInt(l4d2_lw_shake))
		{
			ScreenShake(client);
		}
		
		/* Laser effect */
		GetTracePosition(client);
		if(StrEqual(weapon, "weapon_sniper_scout"))
			CreateLaserEffect(client, 0, 0, 200, 230, 2.0, 1.00);
		else if(StrEqual(weapon, "weapon_sniper_awp"))
			CreateLaserEffect(client, 0, 80, 230, 80, 2.0, 1.00);
		else if(StrEqual(weapon, "weapon_hunting_rifle"))
			CreateLaserEffect(client, 0, 230, 230, 230, 2.0, 1.00);
		else if(StrEqual(weapon, "weapon_sniper_military"))
			CreateLaserEffect(client, 0, 230, 230, 80, 2.0, 1.00);
		
		/* Emit sound */
		EmitSoundToAll(
			AWPSHOT, client,
			SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
			125, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		
		/* Reset client condition */
		CreateTimer(0.2, ReleaseTimer, client);
		if (GetConVarInt(l4d2_lw_shootonce))
		{
			ChargeLock[client] = 1;
			PrintHintText(client, "Lethal Weapon can only be fired once per round");
		}
		else
		{
			// Enable shooting more than once per round again
			ChargeLock[client] = 0;
		}
		
		/* Self Damage */
		if (GetConVarInt(l4d2_lw_selfdamage))
		{
			SetEntProp(client, Prop_Data, "m_iHealth", GetClientHealth(client) - GetConVarInt(l4d2_lw_selfdamage));
		}
	}
}

public Action:ReleaseTimer(Handle:timer, any:client)
{
	/* Set ammo after using */
	if (GetConVarInt(l4d2_lw_useammo))
	{
		new Weapon = GetEntDataEnt2(client, CurrentWeapon);
		new iAmmo = FindDataMapOffs(client,"m_iAmmo");
		SetEntData(Weapon, ClipSize, 0);
		SetEntData(client, iAmmo+8,  RoundToFloor(GetEntData(client, iAmmo+8)  / 2.0));
		SetEntData(client, iAmmo+36, RoundToFloor(GetEntData(client, iAmmo+36) / 2.0));
		SetEntData(client, iAmmo+40, RoundToFloor(GetEntData(client, iAmmo+40) / 2.0));
	}

	/* Reset flags */
	ReleaseLock[client] = 0;
	
	new String:weapon[32];
	GetClientWeapon(client, weapon, 32);
	new ct;
	
	if(StrEqual(weapon, "weapon_sniper_scout"))
		ct = GetConVarInt(l4d2_lw_scout_charge);
	else if(StrEqual(weapon, "weapon_sniper_awp"))
		ct = GetConVarInt(l4d2_lw_awp_charge);
	else if(StrEqual(weapon, "weapon_hunting_rifle"))
		ct = GetConVarInt(l4d2_lw_hunting_charge);
	else if(StrEqual(weapon, "weapon_sniper_military"))
		ct = GetConVarInt(l4d2_lw_g3sg1_charge);
	
	ChargeEndTime[client] = RoundToCeil(GetGameTime()) + ct;
}

public Action:ChargeTimer(Handle:timer, any:client)
{
	// Make sure we remove the lock if this ConVar is later disabled
	if (GetConVarInt(l4d2_lw_shootonce) < 1)
	{
		ChargeLock[client] = 0;
	}

	StopSound(client, SNDCHAN_AUTO, CHARGESOUND);
	if (!GetConVarInt(l4d2_lw_lethalweapon) || ChargeLock[client])
		return Plugin_Continue;

	if (!IsValidEntity(client) || !IsClientInGame(client))
	{
		ClientTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	/* Get data */
	new gt = RoundToCeil(GetGameTime());
	new ct;
	new buttons = GetClientButtons(client);
	new WeaponClass = GetEntDataEnt2(client, CurrentWeapon);
	new String:weapon[32];
	GetClientWeapon(client, weapon, 32);
	
	if(StrEqual(weapon, "weapon_sniper_scout"))
		ct = GetConVarInt(l4d2_lw_scout_charge);
	else if(StrEqual(weapon, "weapon_sniper_awp"))
		ct = GetConVarInt(l4d2_lw_awp_charge);
	else if(StrEqual(weapon, "weapon_hunting_rifle"))
		ct = GetConVarInt(l4d2_lw_hunting_charge);
	else if(StrEqual(weapon, "weapon_sniper_military"))
		ct = GetConVarInt(l4d2_lw_g3sg1_charge);
	
	/* These weapons allow you to start charging */
	/* Now allowed: Hunting Rifle, G3SG1, Scout, AWP */
	if (!(StrEqual(weapon, "weapon_sniper_military") && GetConVarInt(l4d2_lw_g3sg1) && UnlockFlag[0]) &&
		!(StrEqual(weapon, "weapon_sniper_awp") && GetConVarInt(l4d2_lw_awp) && UnlockFlag[1]) &&
		!(StrEqual(weapon, "weapon_sniper_scout") && GetConVarInt(l4d2_lw_scout) && UnlockFlag[2]) &&
		!(StrEqual(weapon, "weapon_hunting_rifle") && GetConVarInt(l4d2_lw_huntingrifle) && UnlockFlag[3]))
	{
		StopSound(client, SNDCHAN_AUTO, CHARGESOUND);
		ReleaseLock[client] = 0;
		ChargeEndTime[client] = gt + ct;
		return Plugin_Continue;
	}
	
	new inCharge;
	
	if(GetConVarInt(l4d2_lw_walkkey))
	{
		// Base case to be overridden, just in case someone messes with the ConVar
		if (GetConVarInt(l4d2_lw_moveandcharge) < 1)
		{
			/* Ducked, not moving, not attacking, not incapaciated */
			inCharge = ((buttons & IN_WALK) &&
						(GetEntityFlags(client) & FL_ONGROUND) &&
						!(buttons & IN_FORWARD) &&
						!(buttons & IN_MOVERIGHT) &&
						!(buttons & IN_MOVELEFT) &&
						!(buttons & IN_BACK) &&
						!(buttons & IN_ATTACK) &&
						!(buttons & IN_ATTACK2));
		}
		else
		{
			/* Ducked, moving, not attacking, not incapaciated */
			inCharge = ((buttons & IN_WALK) &&
						(GetEntityFlags(client) & FL_ONGROUND) &&
						!(buttons & IN_ATTACK) &&
						!(buttons & IN_ATTACK2));
		}
	}
	else
	{		
		if (GetConVarInt(l4d2_lw_moveandcharge) < 1)
		{
			/* Ducked, not moving, not attacking, not incapaciated */
			inCharge = ((GetEntityFlags(client) & FL_DUCKING) &&
						(GetEntityFlags(client) & FL_ONGROUND) &&
						!(buttons & IN_FORWARD) &&
						!(buttons & IN_MOVERIGHT) &&
						!(buttons & IN_MOVELEFT) &&
						!(buttons & IN_BACK) &&
						!(buttons & IN_ATTACK) &&
						!(buttons & IN_ATTACK2));
		}
		else
		{
			/* Ducked, moving, not attacking, not incapaciated */
			inCharge = ((GetEntityFlags(client) & FL_DUCKING) &&
						(GetEntityFlags(client) & FL_ONGROUND) &&
						!(buttons & IN_ATTACK) &&
						!(buttons & IN_ATTACK2));
		}
	}
	
	/* If in charging, display charge bar */
	if (inCharge && GetEntData(WeaponClass, ClipSize))
	{
		if (ChargeEndTime[client] < gt)
		{
			/* Charge end, ready to fire */
			PrintCenterText(client, "***************** CHARGED *****************");
			if (ReleaseLock[client] != 1)
			{
				decl Float:pos[3];
				GetClientAbsOrigin(client, pos);
				if (GetConVarInt(l4d2_lw_chargedsound))
				{
					EmitSoundToAll(CHARGEDUPSOUND, client);
				}
				if (GetConVarInt(l4d2_lw_chargeparticle))
				{
					ShowParticle(pos, "electrical_arc_01_system", 5.0);
				}
			}
			ReleaseLock[client] = 1;
		}
		else
		{
			/* Not charged yet. Display charge gauge */
			new i, j;
			new String:ChargeBar[50];
			new String:Gauge1[2] = "|";
			new String:Gauge2[2] = " ";
			new Float:GaugeNum = (float(ct) - (float(ChargeEndTime[client] - gt))) * (100.0/float(ct))/2.0;
			ReleaseLock[client] = 0;
			if(GaugeNum > 50.0)
				GaugeNum = 50.0;
			
			for(i=0; i<GaugeNum; i++)
				ChargeBar[i] = Gauge1[0];
			for(j=i; j<50; j++)
				ChargeBar[j] = Gauge2[0];
			if (GaugeNum >= 15)
			{
				/* Gauge meter is 30% or more */
				decl Float:pos[3];
				GetClientAbsOrigin(client, pos);
				pos[2] += 45;
				if (GetConVarInt(l4d2_lw_chargeparticle))
				{
					ShowParticle(pos, "electrical_arc_01_cp0", 5.0);
				}
				if (GetConVarInt(l4d2_lw_chargingsound))
				{
					EmitSoundToAll(CHARGESOUND, client);
				}
			}
			/* Display gauge */
			PrintCenterText(client, "           << CHARGE IN PROGRESS >>\n0%% %s %3.0f%%", ChargeBar, GaugeNum*2);
		}
	}
	else
	{
		/* Not matching condition */
		StopSound(client, SNDCHAN_AUTO, CHARGESOUND);
		ReleaseLock[client] = 0;
		ChargeEndTime[client] = gt + ct;
	}
	return Plugin_Continue;
}

public ExplodeMain(Float:pos[3], bomb, fire)
{
	/* Main effect when hit */
	if (GetConVarInt(l4d2_lw_chargeparticle))
	{
		ShowParticle(pos, "electrical_arc_01_system", 5.0);
	}
	if(bomb)
		LittleFlower(pos, EXPLODE);
	
	if (GetConVarInt(l4d2_lw_lethalweapon) == 1)
	{
		ShowParticle(pos, "gas_explosion_main", 5.0);
		if(fire)
			LittleFlower(pos, MOLOTOV);
	}
}

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	/* Show particle effect you like */
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}  
}

public PrecacheParticle(String:particlename[])
{
	/* Precache particle */
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle);
	}  
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	/* Delete particle */
    if (IsValidEntity(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
            		RemoveEdict(particle);
	}
}

public LittleFlower(Float:pos[3], type)
{
	/* Cause fire(type=0) or explosion(type=1) */
	new entity = CreateEntityByName("prop_physics");
	if (IsValidEntity(entity))
	{
		pos[2] += 10.0;
		if (type == 0)
			/* fire */
			DispatchKeyValue(entity, "model", "models/props_junk/gascan001a.mdl");
		else
			/* explode */
			DispatchKeyValue(entity, "model", "models/props_junk/propanecanister001a.mdl");
		DispatchSpawn(entity);
		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "break");
	}
}

public Action:GetEntityAbsOrigin(entity,Float:origin[3])
{
	/* Get target posision */
	decl Float:mins[3], Float:maxs[3];
	GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
	GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
	GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
	
	origin[0] += (mins[0] + maxs[0]) * 0.5;
	origin[1] += (mins[1] + maxs[1]) * 0.5;
	origin[2] += (mins[2] + maxs[2]) * 0.5;
}

Smash(client, target, Float:power, Float:powHor, Float:powVec)
{
	/* Smash target */
	// Check so that we don't "smash" other Survivors (only if "l4d2_lw_ff" is 0)
	if (GetConVarInt(l4d2_lw_ff) || GetClientTeam(target) != 2)
	{
		decl Float:HeadingVector[3], Float:AimVector[3];
		GetClientEyeAngles(client, HeadingVector);
	
		AimVector[0] = FloatMul(Cosine(DegToRad(HeadingVector[1])) ,power * powHor);
		AimVector[1] = FloatMul(Sine(DegToRad(HeadingVector[1])) ,power * powHor);
	
		decl Float:current[3];
		GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
	
		decl Float:resulting[3];
		resulting[0] = FloatAdd(current[0], AimVector[0]);	
		resulting[1] = FloatAdd(current[1], AimVector[1]);
		resulting[2] = power * powVec;
	
		TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
	}
}

public ScreenFade(target, red, green, blue, alpha, duration, type)
{
	new Handle:msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type == 0)
	{
		BfWriteShort(msg, (0x0002 | 0x0008));
	}
	else
	{
		BfWriteShort(msg, (0x0001 | 0x0010));
	}
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

public ScreenShake(target)
{
	new Handle:msg;
	if (GetConVarInt(l4d2_lw_shake_shooteronly))
	{
		msg = StartMessageAll("Shake");
	}
	else
	{
		msg = StartMessageOne("Shake", target);
	}
	BfWriteByte(msg, 0);
 	BfWriteFloat(msg, GetConVarFloat(l4d2_lw_shake_intensity));
 	BfWriteFloat(msg, 10.0);
 	BfWriteFloat(msg, 3.0);
	EndMessage();
}

public GetTracePosition(client)
{
	decl Float:myAng[3];
	GetClientEyePosition(client, myPos);
	GetClientEyeAngles(client, myAng);
	new Handle:trace = TR_TraceRayFilterEx(myPos, myAng, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, TraceEntityFilterPlayer, client);
	if(TR_DidHit(trace))
		TR_GetEndPosition(trsPos, trace);
	CloseHandle(trace);
	for(new i = 0; i < 3; i++)
		trsPos002[i] = trsPos[i];
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

public CreateLaserEffect(client, colRed, colGre, colBlu, alpha, Float:width, Float:duration)
{
	decl Float:tmpVec[3];
	SubtractVectors(myPos, trsPos, tmpVec);
	NormalizeVector(tmpVec, tmpVec);
	ScaleVector(tmpVec, GetConVarFloat(l4d2_lw_laseroffset));
	SubtractVectors(myPos, tmpVec, trsPos);
	
	decl color[4];
	color[0] = colRed; 
	color[1] = colGre;
	color[2] = colBlu;
	color[3] = alpha;
	TE_SetupBeamPoints(myPos, trsPos002, g_sprite, 0, 0, 0, duration, width, width, 1, 0.0, color, 0);
	TE_SendToAll();
}
