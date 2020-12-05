#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define DEBUG 0
#define PLUGIN_VERSION "1.1"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

new Handle:GunzWeapon		 = INVALID_HANDLE;
new Handle:HomerunSurvivor	 = INVALID_HANDLE;
new Handle:HomerunTank		 = INVALID_HANDLE;
new Handle:RemoveDamage 	 = INVALID_HANDLE;
new Handle:hForce 			 = INVALID_HANDLE;
new Handle:vForce 			 = INVALID_HANDLE;

new Handle:ForceOfBat = INVALID_HANDLE;
new Handle:ForceOfCri = INVALID_HANDLE;
new Handle:ForceOfBar = INVALID_HANDLE;
new Handle:ForceOfGui = INVALID_HANDLE;
new Handle:ForceOfAxe = INVALID_HANDLE;
new Handle:ForceOfPan = INVALID_HANDLE;
new Handle:ForceOfKat = INVALID_HANDLE;
new Handle:ForceOfMac = INVALID_HANDLE;
new Handle:ForceOfTon = INVALID_HANDLE;
new Handle:ForceOfKni = INVALID_HANDLE;
new Handle:ForceOfSld = INVALID_HANDLE;
new Handle:ForceOfClb = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[L4D2] Homerun Bat",
	author = "ztar",
	description = "Melee weapon causes nice Homerun.",
	version = PLUGIN_VERSION,
	url = "http://ztar.blog7.fc2.com/"
}

public OnPluginStart()
{
	GunzWeapon		  = CreateConVar("l4d2_gunz_weapon","1", "Enable KS(?)", CVAR_FLAGS);
	HomerunSurvivor	  = CreateConVar("l4d2_homerun_survivor","1", "Are you Homerun king?", CVAR_FLAGS);
	HomerunTank		  = CreateConVar("l4d2_homerun_tank","1", "Are you Homerun king?", CVAR_FLAGS);
	RemoveDamage	  = CreateConVar("l4d2_removeffdamage","1", "Remove FF damage.", CVAR_FLAGS);
	hForce			  = CreateConVar("l4d2_smashrate_h","1.5", "Horizontal force rate", CVAR_FLAGS);
	vForce			  = CreateConVar("l4d2_smashrate_v","1.0", "Vertical force rate", CVAR_FLAGS);
	
	ForceOfBat = CreateConVar("l4d2_force_bat","350", "Swing force of your Baseball bat", CVAR_FLAGS);
	ForceOfCri = CreateConVar("l4d2_force_cri","280", "Swing force of your Cricket bat", CVAR_FLAGS);
	ForceOfBar = CreateConVar("l4d2_force_bar","250", "Swing force of your Crowbar", CVAR_FLAGS);
	ForceOfGui = CreateConVar("l4d2_force_gui","800", "Swing force of your Guitar", CVAR_FLAGS);
	ForceOfAxe = CreateConVar("l4d2_force_axe","260", "Swing force of your Fire axe", CVAR_FLAGS);
	ForceOfPan = CreateConVar("l4d2_force_pan","350", "Swing force of your Flying pan", CVAR_FLAGS);
	ForceOfKat = CreateConVar("l4d2_force_kat","210", "Swing force of your Katana", CVAR_FLAGS);
	ForceOfMac = CreateConVar("l4d2_force_mac","200", "Swing force of your Machete", CVAR_FLAGS);
	ForceOfTon = CreateConVar("l4d2_force_ton","240", "Swing force of your Tonfa", CVAR_FLAGS);
	ForceOfKni = CreateConVar("l4d2_force_kni","100", "Swing force of your Knife", CVAR_FLAGS);
	ForceOfSld = CreateConVar("l4d2_force_sld","230", "Swing force of your Shield", CVAR_FLAGS);
	ForceOfClb = CreateConVar("l4d2_force_clb","380", "Swing force of your golfclub", CVAR_FLAGS);
	
	HookEvent("weapon_fire", Event_Weapon_Fire);
	HookEvent("player_hurt", Event_Player_Hurt, EventHookMode_Pre);
	
	AutoExecConfig(true,"l4d2_homerun_bat");
}

public Action:Event_Weapon_Fire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, 64);
	
	/* Check current melee weapon */
	if(StrEqual(weapon, "melee") && GetConVarInt(GunzWeapon))
	{
		GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_strMapSetScriptName", weapon, sizeof(weapon));
		if (StrEqual(weapon, "katana") ||
			StrEqual(weapon, "machete") ||
			StrEqual(weapon, "knife"))
		{
			if(!(GetEntityFlags(client) & FL_ONGROUND))
			{
				/* Slash! */
				Smash(client, client, 350.0, 2.0, -0.1);
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:power = 200.0;
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, 64);
	
	/* Check current melee weapon */
	if(StrEqual(weapon, "melee"))
	{
		GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_strMapSetScriptName", weapon, sizeof(weapon));
		
		#if DEBUG
		PrintToChatAll("[DEBUG] Weapon name->%s", weapon);
		#endif
		
		/* return if HomerunTank is OFF */
		if(GetConVarInt(HomerunTank) == 0 && GetEntProp(target, Prop_Send, "m_zombieClass") == 8)
			return Plugin_Continue;
		
		/* return if HomerunSurvivor is OFF */
		if(GetConVarInt(HomerunSurvivor) == 0 && (GetClientTeam(client) == GetClientTeam(target)))
			return Plugin_Continue;
		
		/* remove FF damage */
		if(GetConVarInt(RemoveDamage) && (GetClientTeam(client) == GetClientTeam(target)))
			SetEntityHealth(target, (GetEventInt(event,"dmg_health")+ GetEventInt(event,"health")));
		
		/* Set Power */
		if(StrEqual(weapon, "baseball_bat")){
			power = GetConVarFloat(ForceOfBat);
		}else if(StrEqual(weapon, "cricket_bat")){
			power = GetConVarFloat(ForceOfCri);
		}else if(StrEqual(weapon, "crowbar")){
			power = GetConVarFloat(ForceOfBar);
		}else if(StrEqual(weapon, "electric_guitar")){
			power = GetConVarFloat(ForceOfGui);
		}else if(StrEqual(weapon, "fireaxe")){
			power = GetConVarFloat(ForceOfAxe);
		}else if(StrEqual(weapon, "frying_pan")){
			power = GetConVarFloat(ForceOfPan);
		}else if(StrEqual(weapon, "katana")){
			power = GetConVarFloat(ForceOfKat);
		}else if(StrEqual(weapon, "machete")){
			power = GetConVarFloat(ForceOfMac);
		}else if(StrEqual(weapon, "tonfa")){
			power = GetConVarFloat(ForceOfTon);
		}else if(StrEqual(weapon, "knife")){
			power = GetConVarFloat(ForceOfKni);
		}else if(StrEqual(weapon, "riot_shield")){
			power = GetConVarFloat(ForceOfSld);
		}else if(StrEqual(weapon, "golfclub")){
			power = GetConVarFloat(ForceOfClb);
		}
		
		/* Smash target */
		Smash(client, target, power, GetConVarFloat(hForce), GetConVarFloat(vForce));
	}
	return Plugin_Continue;
}

Smash(client, target, Float:power, Float:powHor, Float:powVec)
{
	/* Smash target */
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
