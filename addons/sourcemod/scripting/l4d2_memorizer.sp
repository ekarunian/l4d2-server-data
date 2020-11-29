/******************************************************
* 			L4D2: Status Memorizer v1.2
*					Author: ztar
* 			Web: http://ztar.blog7.fc2.com/
*******************************************************/
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.2"
#define DEBUG		0
#define DEBUG_LOG	0

#define SURVIVOR	2
#define MAXPLAYER	32+1
#define MAXSLOT		5
#define MAXLENGTH	128
#define NONE		-1

/* Cvar */
new Handle:sm_memory_enable	= INVALID_HANDLE;
new Handle:sm_memory_logmsg	= INVALID_HANDLE;

/* Array of survivor's data */
new ammo[MAXPLAYER];
new clip[MAXPLAYER];
new clip02[MAXPLAYER];
new upgrade[MAXPLAYER];
new upammo[MAXPLAYER];
new dual[MAXPLAYER];
new Health[MAXPLAYER];
new IncapCount[MAXPLAYER];
new Float:HealthBuffer[MAXPLAYER];
new String:EquipData[MAXPLAYER][MAXSLOT][MAXLENGTH];
new bool:MissionChangerVote;

public Plugin:myinfo = 
{
	name = "[L4D2] Status Memorizer",
	author = "ztar",
	description = "Memorize each player's status when chapter ends. It fixed copy bug of L5D-L16D.",
	version = PLUGIN_VERSION,
	url = "http://ztar.blog7.fc2.com/"
}

/******************************************************
*	Initial functions
*******************************************************/
public OnPluginStart()
{
	sm_memory_enable = CreateConVar("sm_memory_enable","1","0:OFF 1:ON", FCVAR_NOTIFY);
	sm_memory_logmsg = CreateConVar("sm_memory_logmsg","1","0:OFF 1:ON", FCVAR_NOTIFY);
	
	HookEvent("round_start", Event_Round_Start);
	HookEvent("map_transition", Event_Map_Transition);
	HookEvent("finale_vehicle_leaving", Event_Finale_Clear);
	HookEvent("vote_passed", Event_Vote_EndSuccess);
	HookEvent("vote_failed", Event_Vote_EndFail);
	
	ResetParameter();
}

public OnMapStart()
{
	decl String:CurrentMap[64];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	/* Trying to get first map name */
	if (StrContains(CurrentMap, "1_") != -1 ||
		StrContains(CurrentMap, "_1") != -1 ||
		StrContains(CurrentMap, "01") != -1 ||
		StrContains(CurrentMap, "_m1") != -1 ||
		StrEqual(CurrentMap, "l4d2_pasiri1"))
	{
		if (StrEqual(CurrentMap, "c1_2_jam") ||
			StrEqual(CurrentMap, "c1_3_school") ||
			StrEqual(CurrentMap, "c1_4_roof_safe"))
			return;
		ResetParameter();
	}
}

ResetParameter()
{
	for(new i = 1; i < MAXPLAYER; i++)
	{
		Health[i] = 100;
		HealthBuffer[i] = 0.0;
		IncapCount[i] = 0;
		dual[i] = 0;
		for(new j = 0; j < MAXSLOT; j++)
		{
			EquipData[i][j] = "NONE";
		}
	}
}

public OnNewMission()
{
	DebugPrint("*** NEW CAMPAIGN ***");
	ResetParameter();
}

public Action:Event_Finale_Clear(Handle:event, const String:name[], bool:dontBroadcast)
{
	DebugPrint("*** FINALE CLEARED ***");
	ResetParameter();
}

/******************************************************
*	When vote change map
*******************************************************/
public Action:Callvote_Handler(client, args)
{
	DebugPrint("*** VOTE START ***");
	decl String:voteName[32];
	GetCmdArg(1, voteName, sizeof(voteName));
	
	if((StrEqual(voteName,"ReturnToLobby", false) ||
		StrEqual(voteName,"ChangeMission", false)))
	{
		MissionChangerVote = true;
	}
}

public Event_Vote_EndSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!MissionChangerVote)
		return;
	
	decl String:details[256], String:param1[256];
	GetEventString(event, "details", details, sizeof(details));
	GetEventString(event, "param1", param1, sizeof(param1));
	
	MissionChangerVote = false;
	
	if(strcmp(details, "#L4D_vote_passed_mission_change", false) == 0)
		ResetParameter();
	
	if (strcmp(details, "#L4D_vote_passed_return_to_lobby", false) == 0)
		ResetParameter();
}

public Event_Vote_EndFail(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(MissionChangerVote)
		MissionChangerVote = false;
}

/******************************************************
*	Memorize status of survivors
*******************************************************/
public Action:Event_Map_Transition(Handle:event, const String:name[], bool:dontBroadcast)
{
	DebugPrint("*** MAP TRANSITION ***");
	MemoryEquipment();
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	DebugPrint("*** ROUND START ***");
	CreateTimer(0.2, RoundStartDelay);
}

public Action:RoundStartDelay(Handle:timer)
{
	new String:pName[MAXPLAYERS+1];
	if(!GetConVarInt(sm_memory_enable))
		return;
	for(new i = 1; i < MAXPLAYER; i++)
	{
		if (IsValidEntity(i) &&
			IsClientInGame(i) &&
			GetClientTeam(i) == SURVIVOR)
		{
			GetClientName(i, pName, sizeof(pName));
			
			/* Restore health when round starts */
			SetEntityHealth(i, Health[i]);
			SetEntPropFloat(i, Prop_Send, "m_healthBuffer", HealthBuffer[i]);
			SetEntProp(i, Prop_Send, "m_currentReviveCount", IncapCount[i]);
			
			/* Restore status when round starts */
			for(new j = 0; j < MAXSLOT; j++)
			{
				new entID = GetPlayerWeaponSlot(i, j);
				if(entID != NONE)
				{
					RemovePlayerItem(i, GetPlayerWeaponSlot(i, j));
				}
				if(!StrEqual(EquipData[i][j], "NONE"))
				{
					CheatCommand(i, "give", EquipData[i][j]);
					if(j == 0)
					{
						new cWeapon = GetEntDataEnt2(i, FindSendPropOffs("CTerrorPlayer", "m_hActiveWeapon"));
						new ammoOffset = FindDataMapOffs(i, "m_iAmmo");
						
						if (StrEqual(EquipData[i][j], "weapon_rifle") ||
							StrEqual(EquipData[i][j], "weapon_rifle_sg552") ||
							StrEqual(EquipData[i][j], "weapon_rifle_desert") ||
							StrEqual(EquipData[i][j], "weapon_rifle_m60") ||
							StrEqual(EquipData[i][j], "weapon_rifle_ak47"))
						{
							SetEntData(i, ammoOffset+(12), ammo[i]);
						}
						else if(StrEqual(EquipData[i][j], "weapon_smg") ||
								StrEqual(EquipData[i][j], "weapon_smg_silenced") ||
								StrEqual(EquipData[i][j], "weapon_smg_mp5"))
						{
							SetEntData(i, ammoOffset+(20), ammo[i]);
						}
						else if(StrEqual(EquipData[i][j], "weapon_pumpshotgun") ||
								StrEqual(EquipData[i][j], "weapon_shotgun_chrome"))
						{
							SetEntData(i, ammoOffset+(28), ammo[i]);
						}
						else if(StrEqual(EquipData[i][j], "weapon_autoshotgun") ||
								StrEqual(EquipData[i][j], "weapon_shotgun_spas"))
						{
							SetEntData(i, ammoOffset+(32), ammo[i]);
						}
						else if(StrEqual(EquipData[i][j], "weapon_hunting_rifle"))
						{
							SetEntData(i, ammoOffset+(36), ammo[i]);
						}
						else if(StrEqual(EquipData[i][j], "weapon_sniper_scout") ||
								StrEqual(EquipData[i][j], "weapon_sniper_military") ||
								StrEqual(EquipData[i][j], "weapon_sniper_awp"))
						{
							SetEntData(i, ammoOffset+(40), ammo[i]);
						}
						else if(StrEqual(EquipData[i][j], "weapon_grenade_launcher"))
						{
							SetEntData(i, ammoOffset+(68), ammo[i]);
						}
						if(cWeapon == -1)
							continue;
						
						SetEntProp(cWeapon, Prop_Send, "m_iClip1", clip[i], 1);
						SetEntProp(cWeapon, Prop_Send, "m_upgradeBitVec", upgrade[i]);
						SetEntProp(cWeapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", upammo[i]);
					}
					else if(j == 1)
					{
						if(StrEqual(EquipData[i][j], "weapon_chainsaw"))
						{
							new cWeapon = GetEntDataEnt2(i, FindSendPropOffs("CTerrorPlayer", "m_hActiveWeapon"));
							SetEntProp(cWeapon, Prop_Data, "m_iClip1", clip02[i]); 
						}
						else if(StrEqual(EquipData[i][j], "weapon_pistol") &&
								dual[i] == 1)
						{
							CheatCommand(i, "give", "weapon_pistol");
						}
					}
				}
			}
			if (StrEqual(EquipData[i][0], "NONE") &&
				StrEqual(EquipData[i][1], "NONE") &&
				StrEqual(EquipData[i][2], "NONE") &&
				StrEqual(EquipData[i][3], "NONE") &&
				StrEqual(EquipData[i][4], "NONE"))
			{
				CheatCommand(i, "give", "pistol");
			}
			DebugPrint("[%d] <%s> Status restored", i, pName);
		}
	}
}

public MemoryEquipment()
{
	new String:pName[MAXPLAYERS+1];
	
	if(GetConVarInt(sm_memory_logmsg))
	{
		decl String:CurrentMap[64];
		GetCurrentMap(CurrentMap, sizeof(CurrentMap));
		
		LogMessage("Clear Result: [%s]", CurrentMap);
	}
	
	for(new i = 1; i < MAXPLAYER; i++)
	{
		if (IsValidEntity(i) &&
			IsClientInGame(i) &&
			GetClientTeam(i) == SURVIVOR)
		{
			GetClientName(i, pName, sizeof(pName));
			
			/* Memorize health when map ends */
			if(IsPlayerIncapped(i) || !IsPlayerAlive(i))
			{
				Health[i] = 50;
				HealthBuffer[i] = 0.0;
				IncapCount[i] = 0;
			}
			else
			{
				Health[i] = GetClientHealth(i);
				HealthBuffer[i] = 
					GetEntPropFloat(i, Prop_Send, "m_healthBuffer");
				IncapCount[i] = GetEntProp(i, Prop_Send, "m_currentReviveCount");
			}
			if(GetConVarInt(sm_memory_logmsg))
			{
				LogMessage("=========================");
				LogMessage("[%d] PLAYER <%s> (Health:%d(+%.0f)",
							i, pName, Health[i], HealthBuffer[i]);
			}
			
			/* Memorize status when map ends */
			for(new j = 0; j < MAXSLOT; j++)
			{
				new entID = GetPlayerWeaponSlot(i, j);
				if(entID != NONE)
				{
					new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
					GetEdictClassname(entID, EquipData[i][j], MAXLENGTH);
					
					/* Get primary weapon info */
					if(j == 0)
					{
						clip[i] = GetEntProp(entID, Prop_Send, "m_iClip1");
						upgrade[i] = GetEntProp(entID, Prop_Send, "m_upgradeBitVec");
						upammo[i] = GetEntProp(entID, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
						
						if (StrEqual(EquipData[i][j], "weapon_rifle") ||
							StrEqual(EquipData[i][j], "weapon_rifle_sg552") ||
							StrEqual(EquipData[i][j], "weapon_rifle_desert") ||
							StrEqual(EquipData[i][j], "weapon_rifle_m60") ||
							StrEqual(EquipData[i][j], "weapon_rifle_ak47"))
						{
							ammo[i] = GetEntData(i, ammoOffset+(12));
						}
						else if(StrEqual(EquipData[i][j], "weapon_smg") ||
								StrEqual(EquipData[i][j], "weapon_smg_silenced") ||
								StrEqual(EquipData[i][j], "weapon_smg_mp5"))
						{
							ammo[i] = GetEntData(i, ammoOffset+(20));
						}
						else if(StrEqual(EquipData[i][j], "weapon_pumpshotgun") ||
								StrEqual(EquipData[i][j], "weapon_shotgun_chrome"))
						{
							ammo[i] = GetEntData(i, ammoOffset+(28));
						}
						else if(StrEqual(EquipData[i][j], "weapon_autoshotgun") ||
								StrEqual(EquipData[i][j], "weapon_shotgun_spas"))
						{
							ammo[i] = GetEntData(i, ammoOffset+(32));
						}
						else if(StrEqual(EquipData[i][j], "weapon_hunting_rifle"))
						{
							ammo[i] = GetEntData(i, ammoOffset+(36));
						}
						else if(StrEqual(EquipData[i][j], "weapon_sniper_scout") ||
								StrEqual(EquipData[i][j], "weapon_sniper_military") ||
								StrEqual(EquipData[i][j], "weapon_sniper_awp"))
						{
							ammo[i] = GetEntData(i, ammoOffset+(40));
						}
						else if (StrEqual(EquipData[i][j], "weapon_grenade_launcher"))
						{
							ammo[i] = GetEntData(i, ammoOffset+(68));
						}
					}
					
					/* Get melee weapon info */
					if(j == 1)
					{
						if(StrEqual(EquipData[i][j], "weapon_melee"))
						{
							GetEntPropString(entID, Prop_Data, "m_strMapSetScriptName",
											EquipData[i][j], MAXLENGTH);
						}
						else if(StrEqual(EquipData[i][j], "weapon_chainsaw"))
						{
							clip02[i] = GetEntProp(entID, Prop_Send, "m_iClip1");
						}
						else if(StrEqual(EquipData[i][j], "weapon_pistol") &&
								GetEntProp(entID, Prop_Send, "m_isDualWielding") > 0)
						{
							dual[i] = 1;
						}
					}
				}
				else
				{
					EquipData[i][j] = "NONE";
				}
				if(GetConVarInt(sm_memory_logmsg))
				{
					if(j == 0)
						LogMessage("slot%d : %s (%d/%d)", j+1, EquipData[i][j], clip[i], ammo[i]);
					else
						LogMessage("slot%d : %s", j+1, EquipData[i][j]);
				}
			}
		}
	}
	if(GetConVarInt(sm_memory_logmsg))
		LogMessage("=========================");
}

/******************************************************
*	Other functions
*******************************************************/
public CheatCommand(client, const String:command[], const String:arguments[])
{
	if (!client) return;
	new admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	
	SetUserFlagBits(client, admindata);
}

bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
		return true;
	else
		return false;
}

DebugPrint(const String:format[], any:...)
{
	#if DEBUG || DEBUG_LOG
	decl String:buffer[192];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if DEBUG
	PrintToChatAll("%s", buffer);
	#endif
	LogMessage("%s", buffer);
	#else
	
	if(format[0])
		return;
	else
		return;
	#endif
}

/******************************************************
*	EOF
*******************************************************/