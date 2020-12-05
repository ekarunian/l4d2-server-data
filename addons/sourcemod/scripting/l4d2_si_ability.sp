/******************************************************
*	L4D2: Joke abilities of Special Infected v2.0
*					Author: ztar
* 			Web: http://ztar.blog7.fc2.com/
*******************************************************/
#include <sourcemod>
#include <sdktools>

#define DEBUG 0
#define PLUGIN_VERSION "2.0"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

#define MAX_FILE_LEN 128

new Handle:IncapHealth;
new Handle:SmokerTongueGravity;
new Handle:ChargerTimer = INVALID_HANDLE;

new Handle:sm_tank_dmgchange		= INVALID_HANDLE;
new Handle:sm_tank_explode			= INVALID_HANDLE;
new Handle:sm_tank_explode_radius	= INVALID_HANDLE;
new Handle:sm_tank_explode_force	= INVALID_HANDLE;
new Handle:sm_tank_incappunch		= INVALID_HANDLE;
new Handle:sm_tank_punchdamage		= INVALID_HANDLE;
new Handle:sm_tank_rockdamage		= INVALID_HANDLE;
new Handle:sm_tankhp_announce		= INVALID_HANDLE;
new Handle:sm_smoker_fishing		= INVALID_HANDLE;
new Handle:sm_smoker_fishing_force	= INVALID_HANDLE;
new Handle:sm_jockey_steal			= INVALID_HANDLE;
new Handle:sm_jockey_steal_delay	= INVALID_HANDLE;
new Handle:sm_jockey_blind			= INVALID_HANDLE;
new Handle:sm_charger_screw			= INVALID_HANDLE;
new Handle:sm_charger_screw_force	= INVALID_HANDLE;
new Handle:sm_charger_upper			= INVALID_HANDLE;
new Handle:sm_charger_upper_force	= INVALID_HANDLE;
new Handle:sm_charger_release		= INVALID_HANDLE;
new Handle:sm_boomer_rocket			= INVALID_HANDLE;
new Handle:sm_hunter_hiding			= INVALID_HANDLE;

new alpha;
new g_iVelocity	= -1;
new LastHealth[MAXPLAYERS+1];
new StealTicket[MAXPLAYERS+1];
new Float:LastHealthBuffer[MAXPLAYERS+1];
new Float:MaxHealth[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[L4D2] Joke abilities of SI",
	author = "ztar",
	description = "It's just for fun. Edit cfg file before using.",
	version = PLUGIN_VERSION,
	url = "http://ztar.blog7.fc2.com/"
}

public OnPluginStart()
{
	sm_tank_dmgchange 		= CreateConVar("sm_tank_dmgchange","1", "Change tank damage(0:OFF 1:ON)", CVAR_FLAGS);
	sm_tank_explode 		= CreateConVar("sm_tank_explode","1", "Tank explode when dies(0:OFF 1:ON)", CVAR_FLAGS);
	sm_tank_explode_radius 	= CreateConVar("sm_tank_explode_radius","300", "Explode radius of tank", CVAR_FLAGS);
	sm_tank_explode_force 	= CreateConVar("sm_tank_explode_force","400.0", "Explode force of tank", CVAR_FLAGS);
	sm_tank_incappunch 		= CreateConVar("sm_tank_incappunch","1", "Enable incap punch(0:OFF 1:ON)", CVAR_FLAGS);
	sm_tank_punchdamage 	= CreateConVar("sm_tank_punchdamage","10", "Tank punch damage", CVAR_FLAGS);
	sm_tank_rockdamage 		= CreateConVar("sm_tank_rockdamage","10", "Tank rock damage", CVAR_FLAGS);
	sm_tankhp_announce		= CreateConVar("sm_tankhp_announce","1", "Notify tank health on hint text(0:OFF 1:ON)", CVAR_FLAGS);
	sm_smoker_fishing		= CreateConVar("sm_smoker_fishing","1", "Enable fisherman(0:OFF 1:ON)", CVAR_FLAGS);
	sm_smoker_fishing_force	= CreateConVar("sm_smoker_fishing_force","800.0", "Fishing power of Smoker.", CVAR_FLAGS);
	sm_jockey_steal  		= CreateConVar("sm_jockey_steal","1", "Jockey steals primary weapon(0:OFF 1:ON)", CVAR_FLAGS);
	sm_jockey_steal_delay  	= CreateConVar("sm_jockey_steal_delay","1.5", "Delay of Jockey steal.", CVAR_FLAGS);
	sm_jockey_blind			= CreateConVar("sm_jockey_blind","1", "Jockey blinds victim(0:OFF 1:ON)", CVAR_FLAGS);
	sm_charger_screw		= CreateConVar("sm_charger_screw","1", "Enable Charger screw(0:OFF 1:ON)", CVAR_FLAGS);
	sm_charger_screw_force 	= CreateConVar("sm_charger_screw_force","250.0", "Force applied to the victim.", CVAR_FLAGS);
	sm_charger_upper 		= CreateConVar("sm_charger_upper","1", "Enable Charger uppercut(0:OFF 1:ON)", CVAR_FLAGS);
	sm_charger_upper_force 	= CreateConVar("sm_charger_upper_force","200.0", "Force applied to the victim.", CVAR_FLAGS);
	sm_charger_release 		= CreateConVar("sm_charger_release", "1", "Charger will release you(0:OFF 1:ON)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_boomer_rocket	 	= CreateConVar("sm_boomer_rocket", "1", "Boomer jumps when hurted(0:OFF 1:ON)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_hunter_hiding	 	= CreateConVar("sm_hunter_hiding", "1", "Hunter disappear gradually when hurted(0:OFF 1:ON)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	SmokerTongueGravity	= FindConVar("tongue_gravity_force");
	IncapHealth 		= FindConVar("survivor_incap_health");
	
	HookEvent("player_incapacitated", Event_Player_Incap);
	HookEvent("player_incapacitated_start", Event_Player_IncapStart);
	HookEvent("tank_spawn", Event_Tank_Spawn);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("tongue_grab", Event_Smoker_Grab);
	HookEvent("tongue_release", Event_Smoker_Failed);
	HookEvent("choke_end", Event_Smoker_Failed);
	HookEvent("choke_stopped", Event_Smoker_Failed);
	HookEvent("tongue_pull_stopped", Event_Smoker_Failed);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("charger_pummel_start", Event_Charger_Pummel);
	HookEvent("charger_charge_start", Event_Charge);
	HookEvent("charger_charge_end", Event_ChargeEnd);
	HookEvent("charger_killed", Event_ChargeEnd);
	HookEvent("round_end", Event_ChargeEnd);
	HookEvent("jockey_ride", Event_Jockey_Ride);
	HookEvent("jockey_ride_end", Event_Jockey_End);
	HookEvent("hunter_punched", Event_Hunter_Punched);
	
	if((g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]")) == -1)
		LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");
	
	AutoExecConfig(true,"l4d2_si_ability");
}
public OnMapStart()
{
	InitPrecache();
}

public OnMapEnd()
{
	if (ChargerTimer != INVALID_HANDLE)
	{
		CloseHandle(ChargerTimer);
		ChargerTimer = INVALID_HANDLE;
	}
}

InitPrecache()
{
	PrecacheParticle("fluidExplosion_frames");
	PrecacheParticle("tanker_explosion_shockwave");
}

/******************************************************
*	Common event when damaged
*******************************************************/
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if(client <= 0 || client > GetMaxClients())
		return;
	if(!IsValidEntity(client) || !IsClientInGame(client))
		return;
	if(!IsValidEntity(target) || !IsClientInGame(target))
		return;
	
	/* Notify Tank health */
	if(GetEntProp(target, Prop_Send, "m_zombieClass") == 8 && GetConVarInt(sm_tankhp_announce))
	{
		new i, j;
		new dtype = GetEventInt(event, "type");
		new Float:Health = float(GetEventInt(event,"health"));
		decl String:HealthBar[80+1];
		new Float:GaugeNum = ((Health / MaxHealth[target]) * 100.0)*0.8;
		
		for(i = 0; i < 80; i++)
			HealthBar[i] = '|';
		for(j = RoundToCeil(GaugeNum); j < 80; j++)
			HealthBar[j] = ' ';
		HealthBar[80] = '\0';
		if(dtype != 64 && dtype != 128 && dtype != 268435464)
			PrintCenterText(client, "TANK %4.0f/%4.0f  %s", Health, MaxHealth[target], HealthBar);
	}
	
	/* Change damage of Tank Punch */
	if (StrEqual(weapon, "tank_claw") && GetConVarInt(sm_tank_dmgchange))
	{
		new health = GetEventInt(event, "health");
		new dmg = GetEventInt(event, "dmg_health");
		new tank_dmg = GetConVarInt(sm_tank_punchdamage);
		SetEntProp(target, Prop_Data, "m_iHealth", (health + dmg - tank_dmg));
	}
	
	/* Change damage of Tank Rock */
	if (StrEqual(weapon, "tank_rock") && GetConVarInt(sm_tank_dmgchange))
	{
		new health = GetEventInt(event, "health");
		new dmg = GetEventInt(event, "dmg_health");
		new rock_dmg = GetConVarInt(sm_tank_rockdamage);
		SetEntProp(target, Prop_Data, "m_iHealth", (health + dmg - rock_dmg));
	}
	
	/* Charger claw blows off victim */
	if(StrEqual(weapon, "charger_claw") && GetConVarInt(sm_charger_upper))
	{
		new Float:power = GetConVarFloat(sm_charger_upper_force);
		Smash(client, target, power, 1.2, 1.5);
	}
	
	/* Blow off incapped survivor */
	if(StrEqual(weapon, "tank_claw") && GetConVarInt(sm_tank_incappunch))
	{
		if(IsPlayerIncapped(target))
		{
			Smash(client, target, 350.0, 1.5, 2.0);
		}
	}
	
	/* Boomer jumps when hurted */
	if(GetEntProp(target, Prop_Send, "m_zombieClass") == 2 && GetConVarInt(sm_boomer_rocket))
	{
		AddVelocity(target, 0.0, 500.0);
	}
	
	/* Hunter disappears gradually when hurted */
	if(GetEntProp(target, Prop_Send, "m_zombieClass") == 3 && GetConVarInt(sm_hunter_hiding))
	{
		alpha = 255;
		Remove(target);
	}
}

/******************************************************
*	Tank
*******************************************************/
public Action:Event_Player_IncapStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	/* When survivor is about to incap */
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!GetConVarInt(sm_tank_dmgchange))
		return;
	LastHealth[client] = GetClientHealth(client);
	LastHealthBuffer[client] = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
}

public Action:IncapTimer_Function(Handle:timer, any:client)
{
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
	SetEntityHealth(client, GetConVarInt(IncapHealth));
	return Plugin_Stop;
}

public Action:Event_Player_Incap(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weapon[64];
	new dmg = 9999;
	GetEventString(event, "weapon", weapon, 64);
	
	/* Set new tank damage */
	if(!GetConVarInt(sm_tank_dmgchange))
		return;
	if(StrEqual(weapon, "tank_claw"))
		dmg = GetConVarInt(sm_tank_punchdamage);
	else if(StrEqual(weapon, "tank_rock"))
		dmg = GetConVarInt(sm_tank_rockdamage);
	else
		return;
	
	if(LastHealth[client] > dmg)
	{
		/* Force revive(beta) */
		new userflags = GetUserFlagBits(client);
		SetUserFlagBits(client, ADMFLAG_ROOT);
		new iflags = GetCommandFlags("give");
		SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give health");
		SetCommandFlags("give", iflags);
		SetUserFlagBits(client, userflags);
		SetEntityHealth(client, LastHealth[client] - dmg);
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", LastHealthBuffer[client]);
	}else
	{
		/* Smash even if incap */
		if(GetConVarInt(sm_tank_incappunch))
		{
			SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
			SetEntityHealth(client, 1);
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
			CreateTimer(0.4, IncapTimer_Function, client, TIMER_REPEAT);
		}
	}
}

public Action:Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsClientInGame(client) || !IsValidEntity(client))
		return;
	
	/* Get MAX health of Tank */
	if(GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
	{
		CreateTimer(1.0, GetTankHealth, client);
	}
}

public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(client <= 0 || client > GetMaxClients())
		return;
	if(attacker <= 0 || attacker > GetMaxClients())
		return;
	if(!IsValidEntity(client) || !IsClientInGame(client))
		return;
	if(!IsValidEntity(attacker) || !IsClientInGame(attacker))
		return;
	
	if(GetEntProp(client, Prop_Send, "m_zombieClass") != 8)
		return;
	
	/* Announce tank death */
	if(GetConVarInt(sm_tankhp_announce))
	{
		PrintCenterTextAll("TANK KILLED");
	}
	
	/* Tank explosion effect */
	if(GetConVarInt(sm_tank_explode) && GetClientTeam(attacker) == 2)
	{
		decl Float:Pos[3], Float:tPos[3];
		GetClientAbsOrigin(client, Pos);
		ShowParticle(Pos, "fluidExplosion_frames", 5.0);
		ShowParticle(Pos, "tanker_explosion_shockwave", 5.0);
		LittleFlower(Pos, 1);
		
		/* Blow off victim */
		for(new target = 1; target <= GetMaxClients(); target++)
		{
			if(target == client)
				continue;
			if(!IsClientInGame(target))
				continue;
			if(GetClientTeam(target) != 2)
				continue;
			GetClientAbsOrigin(target, tPos);
			
			if (GetVectorDistance(tPos, Pos) < GetConVarInt(sm_tank_explode_radius))
			{
				Smash(client, target, GetConVarFloat(sm_tank_explode_force), 1.5, 1.5);
			}
		}
	}
}

public Action:GetTankHealth(Handle:timer, any:client)
{
	if(IsValidEntity(client) && IsClientInGame(client))
		MaxHealth[client] = float(GetClientHealth(client));
}

/******************************************************
*	Smoker
*******************************************************/
public Action:Event_Smoker_Grab(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Smoker is fishing */
	if(GetConVarInt(sm_smoker_fishing))
	{
		new target = GetClientOfUserId(GetEventInt(event, "victim"));
		CheatCommand(GetAnyClient(), "tongue_gravity_force", -20000);
		SetEntityGravity(target, 0.3);
		AddVelocity(target, GetConVarFloat(sm_smoker_fishing_force), GetConVarFloat(sm_smoker_fishing_force));
	}
}

public Action:Event_Smoker_Failed(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Reset victim condition */
	new target = GetClientOfUserId(GetEventInt(event, "victim"));
	CheatCommand(GetAnyClient(), "tongue_gravity_force", GetConVarInt(SmokerTongueGravity));
	SetEntityGravity(target, 1.0);
}

/******************************************************
*	Charger
*******************************************************/
public Action:Event_Charger_Pummel(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Stop pummel and smash */
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!GetConVarInt(sm_charger_release))
		return;
	if(client <= 0 || client > GetMaxClients())
		return;
	
	if(GetEntProp(client, Prop_Send, "m_zombieClass") == 6)
	{
		new victim = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
		
		if(IsValidEntity(victim) && victim != 0)
		{
			CallOnPummelEnded(client);
			CallResetAbility(client, 0.1);
			Smash(victim, victim, 200.0, 1.5, 1.5);
		}
	}
}

public Action:Event_Charge(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));	
	
	if (ChargerTimer != INVALID_HANDLE)
	{
		CloseHandle(ChargerTimer);
		ChargerTimer = INVALID_HANDLE;
	}
	
	ChargerTimer = CreateTimer(0.2, CheckForSurvivor, client, TIMER_REPEAT);
	TriggerTimer(ChargerTimer, true);
}

public Action:Event_ChargeEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (ChargerTimer != INVALID_HANDLE)
	{
		CloseHandle(ChargerTimer);
		ChargerTimer = INVALID_HANDLE;
	}
}

public Action:CheckForSurvivor(Handle:timer, any:client)
{
	decl Float:targetpos[3], Float:chargerpos[3];
	
	for (new target = 1; target <= GetMaxClients(); target++)
	{
		if (target == client) continue;
		if (!IsClientInGame(target)) continue;
		if (GetClientTeam(target) != 2) continue;
		if (GetEntProp(target, Prop_Send, "m_isHangingFromLedge") || GetEntProp(target, Prop_Send, "m_isFallingFromLedge")) continue;
		
		GetClientAbsOrigin(target, targetpos);
		GetClientAbsOrigin(client, chargerpos);
		
		if(GetVectorDistance(targetpos, chargerpos) < 150)
		{
			if(GetConVarInt(sm_charger_screw))
			{
				Smash(client, target, GetConVarFloat(sm_charger_screw_force), 1.2, 2.0);
			}
		}
	}
}

CallOnPummelEnded(client)
{
    static Handle:hOnPummelEnded=INVALID_HANDLE;
    if (hOnPummelEnded==INVALID_HANDLE){
        new Handle:hConf = INVALID_HANDLE;
        hConf = LoadGameConfigFile("l4d2_infected_release");
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTerrorPlayer::OnPummelEnded");
        PrepSDKCall_AddParameter(SDKType_Bool,SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_CBasePlayer,SDKPass_Pointer,VDECODE_FLAG_ALLOWNULL);
        hOnPummelEnded = EndPrepSDKCall();
        CloseHandle(hConf);
        if (hOnPummelEnded == INVALID_HANDLE){
            SetFailState("Can't get CTerrorPlayer::OnPummelEnded SDKCall!");
            return;
        }
    }
    SDKCall(hOnPummelEnded,client,true,-1);
}

CallResetAbility(client,Float:time)
{
	static Handle:hStartActivationTimer=INVALID_HANDLE;
	if (hStartActivationTimer==INVALID_HANDLE)
	{
		new Handle:hConf = INVALID_HANDLE;
		hConf = LoadGameConfigFile("l4d2_infected_release");
		
		StartPrepSDKCall(SDKCall_Entity);
		
		PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CBaseAbility::StartActivationTimer");
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);
		
		hStartActivationTimer = EndPrepSDKCall();
		CloseHandle(hConf);
		
		if (hStartActivationTimer == INVALID_HANDLE)
		{
			SetFailState("Can't get CBaseAbility::StartActivationTimer SDKCall!");
			return;
		}            
	}
	new AbilityEnt=GetEntPropEnt(client, Prop_Send, "m_customAbility");
	SDKCall(hStartActivationTimer, AbilityEnt, time, 0.0);
}

/******************************************************
*	Jockey
*******************************************************/
public Action:StealItem(Handle:timer, any:client)
{
	StealTicket[client] = 1;
}

public Action:Event_Jockey_Ride(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if(GetConVarInt(sm_jockey_steal))
	{
		StealTicket[client_victim] = 0;
		CreateTimer(GetConVarFloat(sm_jockey_steal_delay), StealItem, client_victim);
	}
	
	if (IsFakeClient(client_victim) || !GetConVarInt(sm_jockey_blind))
		return;
	
	new clients[2];
	clients[0] = client_victim;	
	
	new Handle:message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	BfWriteShort(message, 255);
	BfWriteShort(message, 0);
	BfWriteShort(message, (0x0002 | 0x0008));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 232);
	EndMessage();
	
	SetEntProp(client_victim, Prop_Send, "m_iHideHUD", 64);
}

public Action:Event_Jockey_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if(GetConVarInt(sm_jockey_steal) && StealTicket[client_victim] == 1)
	{
		if(GetPlayerWeaponSlot(client_victim, 0) != -1)
		{
			PrintHintText(client_victim, "Jockeyに武器を破壊された！");
			RemovePlayerItem(client_victim, GetPlayerWeaponSlot(client_victim, 0));
			new flags = GetCommandFlags("give");
			SetCommandFlags("give", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client_victim, "give gnome");
			SetCommandFlags("give", flags|FCVAR_CHEAT);
		}
	}
	
	if(IsFakeClient(client_victim))
		return;

	new clients[2];
	clients[0] = client_victim;	
	
	new Handle:message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	BfWriteShort(message, (0x0001 | 0x0010));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	EndMessage();
	
	SetEntProp(client_victim, Prop_Send, "m_iHideHUD", 0);
}

/******************************************************
*	Hunter
*******************************************************/
public Action:Event_Hunter_Punched(Handle:event, const String:name[], bool:dontBroadcast)
{ 
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new hunter = GetClientOfUserId(GetEventInt(event, "hunterid"));
	
	new flags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "z_spawn hunter");
	SetCommandFlags("z_spawn", flags|FCVAR_CHEAT);
	alpha = 255;
	Remove(hunter);
}

/******************************************************
*	Particle functions
*******************************************************/
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

/******************************************************
*	Other functions
*******************************************************/
public Smash(client, target, Float:power, Float:powHor, Float:powVec)
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

public LittleFlower(Float:pos[3], type)
{
	/* Cause fire(type=0) or explosion(type=1) */
	new entity = CreateEntityByName("prop_physics");
	if (IsValidEntity(entity))
	{
		pos[2] += 10.0;
		if(type == 0)
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

public AddVelocity(client, Float:xSpeed, Float:zSpeed)
{
	if(g_iVelocity == -1) return;
	
	new Float:vecVelocity[3];
	GetEntDataVector(client, g_iVelocity, vecVelocity);
	
	if(GetRandomInt(0, 1))
	{
		vecVelocity[0] -= xSpeed;
	}
	else
	{
		vecVelocity[0] += xSpeed;
	}
	
	if(GetRandomInt(0, 1))
	{
		vecVelocity[1] -= xSpeed;
	}
	else
	{
		vecVelocity[1] += xSpeed;
	}
	vecVelocity[2] += zSpeed;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}

GetAnyClient()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			return i;
	}
	return 0;
}

CheatCommand(client, const String:command[], arguments)
{
	if (!client) return;
	new admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %d", command, arguments);
	SetCommandFlags(command, flags);
	
	SetUserFlagBits(client, admindata);
}

bool:IsPlayerIncapped(client)
{
	if(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
		return true;
	else
		return false;
}

public Action:Remove(ent)
{
	if (IsValidEntity(ent))
	{
		CreateTimer(0.1, fadeout, ent, TIMER_REPEAT);
		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	}
}

public Action:fadeout(Handle:Timer, any:ent)
{
	if (!IsValidEntity(ent))
	{
		KillTimer(Timer);
		return;
	}
	alpha -= 30;
	if (alpha < 0)  alpha = 0;
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent, 255, 255, 255, alpha);
	if (alpha <= 0)
	{
		KillTimer(Timer);
	}
}

/******************************************************
*	EOF
*******************************************************/