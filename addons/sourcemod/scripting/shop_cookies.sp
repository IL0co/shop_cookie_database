#include <sourcemod>
#include <shop>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name		= "[SHOP] Cookies DataBase",
	version		= "1.0.0",
	description	= "A cookie module for a shop to save data",
	author		= "iLoco",
	url			= "https://github.com/IL0co"
}

Database db;
char dbPrefix[64];
int iId[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int max)
{
	CreateNative("Shop_GetClientCookie", Native_GetClientCookie);
	CreateNative("Shop_SetClientCookie", Native_SetClientCookie);
	CreateNative("Shop_GetClientCookieTime", Native_GetClientCookieTime);

	RegPluginLibrary("ShopCookies");
	return APLRes_Success;
}

public int Native_GetClientCookieTime(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int item_id = GetNativeCell(2);
	int result = -1;

	char buffer[256];

	db.Format(buffer, sizeof(buffer), "SELECT `last_update` FROM `shop_cookies` WHERE `player_id` = %i AND `item_id` = %i", iId[client], item_id);
	DBResultSet query = SQL_Query(db, buffer);

	if (query != null)
	{
		if(query.FetchRow())
		{
			result = query.FetchInt(0);
		}

		delete query;
	}

	return result;
}

public int Native_GetClientCookie(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int item_id = GetNativeCell(2);
	int maxlen = GetNativeCell(4);

	char buff[128];
	char buffer[256];

	db.Format(buffer, sizeof(buffer), "SELECT `data` FROM `shop_cookies` WHERE `player_id` = %i AND `item_id` = %i", iId[client], item_id);
	DBResultSet query = SQL_Query(db, buffer);

	if (query != null)
	{
		if(query.FetchRow())
		{
			query.FetchString(0, buff, sizeof(buff));
			SetNativeString(3, buff, maxlen);	
		}

		delete query;

		if(buff[0])
			return true;
	}

	return false;
}

public int Native_SetClientCookie(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int item_id = GetNativeCell(2);

	if(iId[client] < 0)
		return false;

	char data[128], buffer[256];
	GetNativeString(3, data, sizeof(data));	

	db.Format(buffer, sizeof(buffer), "SELECT `id` FROM `shop_cookies` WHERE `player_id` = %i AND `item_id` = %i", iId[client], item_id);
	DBResultSet query = SQL_Query(db, buffer);

	if (query != null)
	{
		if(query.FetchRow())
			FormatEx(buffer, sizeof(buffer), "UPDATE `shop_cookies` SET `data` = '%s', `last_update` = %i WHERE `player_id` = %i AND `item_id` = %i", data, GetTime(), iId[client], item_id);
		else
			FormatEx(buffer, sizeof(buffer), "INSERT INTO `shop_cookies` (`data`, `player_id`, `item_id`, `last_update`) VALUES ('%s', %i, %i, %i)", data, iId[client], item_id, GetTime());

		delete query;
	}

	SQL_Query(db, buffer);

	return true;
}

public void OnPluginStart()
{
	if(Shop_IsStarted())
	{
		Shop_Started();

		for(int i = 1; i <= MaxClients; i++)	if(IsClientAuthorized(i) && IsClientInGame(i) && !IsFakeClient(i) && Shop_IsAuthorized(i))
			Shop_OnAuthorized(i);
	}
}

public void Shop_OnAuthorized(int client)
{
	iId[client] = -1;

	char buff[64], buffer[256];

	GetCmdArg(1, buff, sizeof(buff));
	GetClientAuthId(client, AuthId_Steam2, buff, sizeof(buff));
	
	db.Format(buffer, sizeof(buffer), "SELECT `id` FROM `%splayers` WHERE `auth` = '%s'", dbPrefix, buff);
	DBResultSet query = SQL_Query(db, buffer);

	if (query != null)
	{
		if(query.FetchRow())
		{
			iId[client] = query.FetchInt(0);
		}

		delete query;
	}
}

public void Shop_Started()
{
	if(Shop_GetDatabaseType() != DB_MySQL)
		return;

	if(db)
		delete db;
	db = Shop_GetDatabase();

	db.Query(SQL_Callback_ErrorCheck, "CREATE TABLE IF NOT EXISTS `shop_cookies` (`id` int(11) NOT NULL AUTO_INCREMENT, `data` varchar(128) NOT NULL default 'unknown', `player_id` int(11) NOT NULL, `item_id` int(11) NOT NULL, `last_update` int(20) NOT NULL, PRIMARY KEY (`id`));");

	Shop_GetDatabasePrefix(dbPrefix, sizeof(dbPrefix));
}

public void SQL_Callback_ErrorCheck(Database hOwner, DBResultSet hResult, const char[] szError, any data)
{
	if(szError[0])
	{
		LogError("SQL_Callback_ErrorCheck: %s", szError);
	}
}
