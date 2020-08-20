#if defined _ShopCookies_included_
  #endinput
#endif
#define _ShopCookies_included_

/*
 * Получить Cookie игрока по id предмета
 *	-
 * @param client 		  Индекс игрока
 * @param item_id 		  Индекс предмета
 * @param buffer 		  Буфер в который сохранит результат
 * @param maxlen 		  Максимальная длинна буфера
 *  -
 * @return                true если успех, или же false	  
*/
native bool Shop_GetClientCookie(int client, ItemId item_id, char[] buffer, int maxlen);

/*
 * Задать Cookie игроку по id предмета
 *	-
 * @param client 		  Индекс игрока
 * @param item_id 		  Индекс предмета
 * @param buffer 		  Данные на сохранение
 *  -
 * @return                true если успех, или же false	  
*/
native bool Shop_SetClientCookie(int client, ItemId item_id, char[] buffer);

/*
 * Задать Cookie игроку по id предмета
 *	-
 * @param client 		  Индекс игрока
 * @param item_id 		  Индекс предмета
 * @param buffer 		  Данные на сохранение
 *  -
 * @return                -1 при неудаче, или же время в UNIX
*/
native bool Shop_GetClientCookieTime(int client, ItemId item_id);

#if !defined REQUIRE_PLUGIN
public void __pl_ShopCookies_SetNTVOptional()
{
	MarkNativeAsOptional("Shop_GetClientCookie");
	MarkNativeAsOptional("Shop_SetClientCookie");
	MarkNativeAsOptional("Shop_GetClientCookieTime");
}
#endif