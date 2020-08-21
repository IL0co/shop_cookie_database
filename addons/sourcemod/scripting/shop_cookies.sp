#include <sourcemod>
#include <shop>
#include <shop_cookies>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name		= "[SHOP] Cookies DataBase",
	version		= "1.0.1",
	description	= "A cookie module for a shop to save data",
	author		= "iLoco",
	url			= "https://github.com/IL0co"
}

Database db;
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

	if(IsFakeClient(client))
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is a bot", client);
	else if(iId[client] == -1)
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is have invalid 'player_id'", client);

	ItemId item_id = GetNativeCell(2);

	if(!Shop_IsItemExists(item_id))
		ThrowNativeError(SP_ERROR_PARAM, "ItemId %i id not exist'", item_id);

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

	if(IsFakeClient(client))
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is a bot", client);
	else if(iId[client] == -1)
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is have invalid 'player_id'", client);

	ItemId item_id = GetNativeCell(2);

	if(!Shop_IsItemExists(item_id))
		ThrowNativeError(SP_ERROR_PARAM, "ItemId %i id not exist'", item_id);

	char data[SHOPCOOKIE_DATA_MAXLEN];
	char buffer[256];

	FormatEx(buffer, sizeof(buffer), "SELECT `data` FROM `shop_cookies` WHERE `player_id` = %i AND `item_id` = %i", iId[client], item_id);
	DBResultSet query = SQL_Query(db, buffer);

	if (query != null)
	{
		if(query.FetchRow())
		{
			query.FetchString(0, data, sizeof(data));
			SetNativeString(3, data, SHOPCOOKIE_DATA_MAXLEN);	
		}

		delete query;

		if(data[0])
			return true;
	}

	return false;
}

public int Native_SetClientCookie(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if(IsFakeClient(client))
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is a bot", client);
	else if(iId[client] == -1)
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is have invalid 'player_id'", client);

	ItemId item_id = GetNativeCell(2);

	if(!Shop_IsItemExists(item_id))
		ThrowNativeError(SP_ERROR_PARAM, "ItemId %i id not exist'", item_id);
		
	char data[SHOPCOOKIE_DATA_MAXLEN], buffer[384];
	GetNativeString(3, data, sizeof(data));	

	FormatEx(buffer, sizeof(buffer), "SELECT `id` FROM `shop_cookies` WHERE `player_id` = %i AND `item_id` = %i", iId[client], item_id);
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
	iId[client] = Shop_GetClientId(client);
}

public void Shop_Started()
{
	if(Shop_GetDatabaseType() != DB_MySQL)
		return;

	if(db)
		delete db;
	db = Shop_GetDatabase();

	char driver[12];
	db.Driver.GetIdentifier(driver, sizeof(driver));

	if(StrEqual(driver, "sqlite", false))		
		db.Query(SQL_Callback_ErrorCheck, "CREATE TABLE IF NOT EXISTS `shop_cookies` (`auth` int(11) NOT NULL, `data` varchar(%i) NOT NULL, `player_id` int(11) NOT NULL, `item_id` int(11) NOT NULL, `last_update` int() NOT NULL);", SHOPCOOKIE_DATA_MAXLEN);
	else
		db.Query(SQL_Callback_ErrorCheck, "CREATE TABLE IF NOT EXISTS `shop_cookies` (`id` int(11) NOT NULL AUTO_INCREMENT, `data` varchar(%i) NOT NULL default 'unknown', `player_id` int(11) NOT NULL, `item_id` int(11) NOT NULL, `last_update` int() NOT NULL, PRIMARY KEY (`id`));", SHOPCOOKIE_DATA_MAXLEN);
}

public void SQL_Callback_ErrorCheck(Database hOwner, DBResultSet hResult, const char[] szError, any data)
{
	if(szError[0])
	{
		LogError("SQL_Callback_ErrorCheck: %s", szError);
	}
}
