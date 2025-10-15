#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.2"
public Plugin myinfo = 
{
    name = "Player Flags Fix",
    author = "+SyntX34 - Based on GAMMACASE's work",
    description = "Fixes PLAYER_FLAG_BITS truncation causing trigger_push prediction issues",
    version = PLUGIN_VERSION,
    url = "https://github.com/SyntX34 && https://steamcommunity.com/id/SyntX34"
};
Address 
    g_SendTableCRC = Address_Null,
    m_fFlags_bits = Address_Null,
    m_vecBaseVelocity_flags = Address_Null,
    PLAYER_FLAG_BITS_addr = Address_Null;
int
    g_OriginalBaseVelocityFlags,
    g_OriginalFlagsBits,
    g_OriginalSendTableCRC,
    g_OriginalPlayerFlagBits;
EngineVersion g_Engine;
ConVar g_cvPluginEnabled, g_cvFixFlags;
bool g_bPluginEnabled, g_bFixFlags;
public void OnPluginStart()
{
    g_Engine = GetEngineVersion();
    g_cvPluginEnabled = CreateConVar("sm_playerflagsfix_enable", "1", "Enable/disable the Player Flags Fix plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvFixFlags = CreateConVar("sm_playerflagsfix_fixflags", "1", "Fix PLAYER_FLAG_BITS truncation issues", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvPluginEnabled.AddChangeHook(OnConVarChanged);
    g_cvFixFlags.AddChangeHook(OnConVarChanged);
    g_bPluginEnabled = g_cvPluginEnabled.BoolValue;
    g_bFixFlags = g_cvFixFlags.BoolValue;
    if (!IsSupportedEngine())
    {
        SetFailState("This plugin only supports CS:GO and CS:S");
        return;
    }
    char engineName[32];
    GetEngineName(engineName, sizeof(engineName));
    PrintToServer("[PlayerFlagsFix] Detected game: %s", engineName);
    ConVar sv_sendtables = FindConVar("sv_sendtables");
    if (sv_sendtables != null)
    {
        sv_sendtables.SetBool(true);
        sv_sendtables.AddChangeHook(OnSendTablesChanged);
    }
    if (g_bPluginEnabled)
    {
        ApplyPatches();
    }
    PrintToServer("[PlayerFlagsFix] Plugin loaded successfully");
    AutoExecConfig(true);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    bool oldPluginState = g_bPluginEnabled;
    bool oldFixFlagsState = g_bFixFlags;
    g_bPluginEnabled = g_cvPluginEnabled.BoolValue;
    g_bFixFlags = g_cvFixFlags.BoolValue;
    if (!oldPluginState && g_bPluginEnabled)
    {
        ApplyPatches();
        PrintToServer("[PlayerFlagsFix] Plugin enabled - patches applied");
    }
    else if (oldPluginState && !g_bPluginEnabled)
    {
        RestorePatches();
        PrintToServer("[PlayerFlagsFix] Plugin disabled - patches restored");
    }
    else if (g_bPluginEnabled && oldFixFlagsState != g_bFixFlags)
    {
        if (g_bFixFlags)
        {
            ApplyFlagPatches();
            PrintToServer("[PlayerFlagsFix] Flag fixes enabled");
        }
        else
        {
            RestoreFlagPatches();
            PrintToServer("[PlayerFlagsFix] Flag fixes disabled");
        }
    }
}

public void OnPluginEnd()
{
    RestorePatches();
    PrintToServer("[PlayerFlagsFix] Plugin unloaded, original values restored");
}

public void OnSendTablesChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    convar.SetBool(true);
}

bool IsSupportedEngine()
{
    return (g_Engine == Engine_CSGO || g_Engine == Engine_CSS);
}

void GetEngineName(char[] buffer, int size)
{
    if (g_Engine == Engine_CSGO)
        strcopy(buffer, size, "CS:GO");
    else if (g_Engine == Engine_CSS)
        strcopy(buffer, size, "CS:S");
    else
        strcopy(buffer, size, "Unknown");
}

void GetGameDataFileName(char[] buffer, int size)
{
    if (g_Engine == Engine_CSGO)
        strcopy(buffer, size, "playerflagsfix.csgo");
    else if (g_Engine == Engine_CSS)
        strcopy(buffer, size, "playerflagsfix.css");
    else
        strcopy(buffer, size, "playerflagsfix.games");
}

void ApplyPatches()
{
    if (!g_bPluginEnabled)
        return;
    char gamedataFile[64];
    GetGameDataFileName(gamedataFile, sizeof(gamedataFile));
    GameData gd = new GameData(gamedataFile);
    if (gd == null)
    {
        LogError("Could not load gamedata file '%s'", gamedataFile);
        return;
    }
    if (!SetupPatches(gd))
    {
        LogError("Failed to setup memory patches");
        delete gd;
        return;
    }
    delete gd;
    PrintToServer("[PlayerFlagsFix] All patches applied successfully");
}

void RestorePatches()
{
    if (g_SendTableCRC != Address_Null)
        StoreToAddress(g_SendTableCRC, g_OriginalSendTableCRC, NumberType_Int32);
    if (m_fFlags_bits != Address_Null)
        StoreToAddress(m_fFlags_bits, g_OriginalFlagsBits, NumberType_Int32);
    if (m_vecBaseVelocity_flags != Address_Null)
        StoreToAddress(m_vecBaseVelocity_flags, g_OriginalBaseVelocityFlags, NumberType_Int32);
    if (PLAYER_FLAG_BITS_addr != Address_Null)
        StoreToAddress(PLAYER_FLAG_BITS_addr, g_OriginalPlayerFlagBits, NumberType_Int32);
}

void ApplyFlagPatches()
{
    if (!g_bPluginEnabled || !g_bFixFlags)
        return;
    if (PLAYER_FLAG_BITS_addr != Address_Null)
    {
        StoreToAddress(PLAYER_FLAG_BITS_addr, 0xFFFFFFFF, NumberType_Int32);
        PrintToServer("[PlayerFlagsFix] PLAYER_FLAG_BITS patched to 32 bits");
    }
    if (m_fFlags_bits != Address_Null)
    {
        StoreToAddress(m_fFlags_bits, 32, NumberType_Int32);
        PrintToServer("[PlayerFlagsFix] m_fFlags patched to 32 bits");
    }
}

void RestoreFlagPatches()
{
    if (!g_bPluginEnabled)
        return;
    if (PLAYER_FLAG_BITS_addr != Address_Null)
    {
        StoreToAddress(PLAYER_FLAG_BITS_addr, g_OriginalPlayerFlagBits, NumberType_Int32);
        PrintToServer("[PlayerFlagsFix] PLAYER_FLAG_BITS restored");
    }
    if (m_fFlags_bits != Address_Null)
    {
        StoreToAddress(m_fFlags_bits, g_OriginalFlagsBits, NumberType_Int32);
        PrintToServer("[PlayerFlagsFix] m_fFlags restored");
    }
}

bool SetupPatches(GameData gd)
{
    g_SendTableCRC = gd.GetAddress("g_SendTableCRC");
    if (g_SendTableCRC == Address_Null)
    {
        LogError("Failed to find g_SendTableCRC address");
        return false;
    }
    int m_fFlags_offset = gd.GetOffset("m_nBits");
    Address m_fFlags_addr = gd.GetAddress("m_fFlags");
    if (m_fFlags_addr == Address_Null || m_fFlags_offset == -1)
    {
        LogError("Failed to find m_fFlags address or offset");
        return false;
    }
    m_fFlags_bits = m_fFlags_addr + view_as<Address>(m_fFlags_offset);
    int currentFlagsBits = LoadFromAddress(m_fFlags_bits, NumberType_Int32);
    if (currentFlagsBits != 11)
    {
        LogError("Unexpected m_fFlags bits value: %d (expected 11)", currentFlagsBits);
        return false;
    }
    int m_vecBaseVelocity_offset = gd.GetOffset("m_Flags");
    Address m_vecBaseVelocity_addr = gd.GetAddress("m_vecBaseVelocity");
    if (m_vecBaseVelocity_addr == Address_Null || m_vecBaseVelocity_offset == -1)
    {
        LogError("Failed to find m_vecBaseVelocity address or offset");
        return false;
    }
    m_vecBaseVelocity_flags = m_vecBaseVelocity_addr + view_as<Address>(m_vecBaseVelocity_offset);
    PLAYER_FLAG_BITS_addr = gd.GetAddress("PLAYER_FLAG_BITS");
    if (PLAYER_FLAG_BITS_addr == Address_Null)
    {
        LogError("Failed to find PLAYER_FLAG_BITS address");
        return false;
    }
    int currentPlayerFlagBits = LoadFromAddress(PLAYER_FLAG_BITS_addr, NumberType_Int32);
    if (currentPlayerFlagBits != ((1 << 11) - 1))
    {
        LogError("Unexpected PLAYER_FLAG_BITS value: %d (expected %d)", currentPlayerFlagBits, ((1 << 11) - 1));
        return false;
    }
    g_OriginalSendTableCRC = LoadFromAddress(g_SendTableCRC, NumberType_Int32);
    g_OriginalFlagsBits = currentFlagsBits;
    g_OriginalBaseVelocityFlags = LoadFromAddress(m_vecBaseVelocity_flags, NumberType_Int32);
    g_OriginalPlayerFlagBits = currentPlayerFlagBits;
    if (g_bFixFlags)
    {
        StoreToAddress(PLAYER_FLAG_BITS_addr, 0xFFFFFFFF, NumberType_Int32);
        PrintToServer("[PlayerFlagsFix] Patched PLAYER_FLAG_BITS from %d to 32 bits", g_OriginalPlayerFlagBits);
        StoreToAddress(m_fFlags_bits, 32, NumberType_Int32);
        PrintToServer("[PlayerFlagsFix] Patched m_fFlags from %d to 32 bits", g_OriginalFlagsBits);
    }
    StoreToAddress(m_vecBaseVelocity_flags, (1 << 2), NumberType_Int32);
    PrintToServer("[PlayerFlagsFix] Patched m_vecBaseVelocity flags from %d to %d", g_OriginalBaseVelocityFlags, (1 << 2));
    StoreToAddress(g_SendTableCRC, 1234, NumberType_Int32);
    PrintToServer("[PlayerFlagsFix] Forced sendtable update");
    return true;
}