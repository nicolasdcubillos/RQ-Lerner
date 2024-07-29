*/
*!*
*!*		Nombre: Cargue de Requisiciones desde Archivo Excel - Libreria Lerner
*!*
*!*		Autor: Nicolás David Cubillos
*!*
*!*		Contenido: Cargue de Requisiciones desde Archivo Excel - Libreria Lerner
*!*
*!*		Fecha: 1 de junio de 2024
*!*
*/

*---------------------------------------------------

FUNCTION saveCantidadFinal(lcIdMvTrade, lcCantidadFinal) AS STRING
lcSqlQuery = "UPDATE MVTRADE SET RQ_CANTIDAD_FINAL = " + TRANSFORM(lcCantidadFinal) + ;
			 " WHERE IDMVTRADE = '" + TRANSFORM(lcIdMvTrade) + "'"

_CLIPTEXT = lcSqlQuery
IF SQLEXEC(ON, lcSqlQuery) != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al actualizar la cantidad final para el IdMvTrade " + ALLTRIM(TRANSFORM(lcIdMvTrade)) + ".")
ENDIF

ENDFUNC
