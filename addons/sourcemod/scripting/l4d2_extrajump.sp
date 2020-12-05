#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Handle:g_ChargeTime = INVALID_HANDLE; 
new Float:g_NextUseTime[MAXPLAYERS+1] = 0.0;

new Handle:sm_extrajump			= INVALID_HANDLE;
new Handle:sm_extrajump_sound	= INVALID_HANDLE;
new Handle:sm_extrajump_speed	= INVALID_HANDLE;
new Handle:sm_extrajump_volume	= INVALID_HANDLE;

new g_iVelocity		= -1;
new String:g_sSound[128] = "UI/menu_countdown.wav";

public Plugin:myinfo = 
{
	name = "[L4D2] Hover Jump",
	author = "ztar",
	description = "It allows you hover jump.",
	version = PLUGIN_VERSION,
	url = "http://ztar.blog7.fc2.com/"
}

public OnPluginStart()
{	
	CreateConVar("sm_extrajump_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	sm_extrajump = CreateConVar("sm_extrajump", "1", "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	sm_extrajump_sound = CreateConVar("sm_extrajump_sound", g_sSound, "", FCVAR_PLUGIN);
	sm_extrajump_speed = CreateConVar("sm_extrajump_speed", "300", "", FCVAR_PLUGIN);
	sm_extrajump_volume = CreateConVar("sm_extrajump_volume", "0.5", "", FCVAR_PLUGIN);
	g_ChargeTime = CreateConVar("sm_extrajump_chargetime", "1.0", "Power charge time");
	
	RegConsoleCmd("hover", extrajumpP);
	
	if((g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]")) == -1)
		LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");
	
	AutoExecConfig(true,"l4d2_extrajump");
}

public OnRoundStart()
{
	for(new i = 1; i <= MAXPLAYERS+1; i++)
		g_NextUseTime[i] = 0.0;
}

public OnMapStart()
{
	for(new i = 1; i <= MAXPLAYERS+1; i++)
		g_NextUseTime[i] = 0.0;
}

public OnConfigsExecuted()
{
	GetConVarString(sm_extrajump_sound, g_sSound, sizeof(g_sSound));
	PrecacheSound(g_sSound, true);
}

public Action:extrajumpP(client, args)
{
	if(GetConVarBool(sm_extrajump))
	{
		/* In cooltime */
		if(g_NextUseTime[client] < GetGameTime())
		{
			new Float:vecPos[3];
			GetClientAbsOrigin(client, vecPos);
			EmitSoundToAll(g_sSound, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, GetConVarFloat(sm_extrajump_volume), SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);
			AddVelocity(client, GetConVarFloat(sm_extrajump_speed));
			
			/* Set cooltime */
			g_NextUseTime[client] = GetGameTime() + GetConVarFloat(g_ChargeTime);
		}
	}
}

AddVelocity(client, Float:speed)
{
	if(g_iVelocity == -1) return;
	
	new Float:vecVelocity[3];
	GetEntDataVector(client, g_iVelocity, vecVelocity);
	
	vecVelocity[2] = speed;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVelocity);
}
