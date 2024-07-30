*/
*!*
*!*		Nombre: Cargue de Requisiciones desde Archivo Excel - Libreria Lerner
*!*
*!*		Autor: Nicol�s David Cubillos
*!*
*!*		Contenido: Cargue de Requisiciones desde Archivo Excel - Libreria Lerner
*!*
*!*		Fecha: 1 de junio de 2024
*!*
*/

*---------------------------------------------------

FUNCTION saveData(lcIdMvTrade, lcCantidadFinal, lcCantidadOc)

lcSqlQuery = "UPDATE MVTRADE SET RQ_CANTIDAD_DESPACHO = " + TRANSFORM(lcCantidadFinal) + ", RQ_CANTIDAD_OC = " + TRANSFORM(lcCantidadOc) + ;
			 " WHERE IDMVTRADE = '" + TRANSFORM(lcIdMvTrade) + "'"

IF SQLEXEC(ON, lcSqlQuery) != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al actualizar la cantidad final para el IdMvTrade " + ALLTRIM(TRANSFORM(lcIdMvTrade)) + ".")
ENDIF

ENDFUNC

*---------------------------------------------------

FUNCTION sendToDispatch(lcIdMvTrade)

lcSqlQuery = "UPDATE MVTRADE SET RQ_ESTADO = 1" + ;
			 " WHERE IDMVTRADE = '" + TRANSFORM(lcIdMvTrade) + "'"

IF SQLEXEC(ON, lcSqlQuery) != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al hacer el paso a despacho (estado 1) para el registro IdMvTrade " + ALLTRIM(TRANSFORM(lcIdMvTrade)) + ".")
ENDIF

ENDFUNC

*---------------------------------------------------

FUNCTION createOC(lcIdMvTrade)

lcSqlQuery = "UPDATE MVTRADE SET RQ_ESTADO = 2" + ;
			 " WHERE IDMVTRADE = '" + TRANSFORM(lcIdMvTrade) + "'"

IF SQLEXEC(ON, lcSqlQuery) != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al crear la �rden de compra (estado 2) para el registro IdMvTrade " + ALLTRIM(TRANSFORM(lcIdMvTrade)) + ".")
ENDIF

ENDFUNC