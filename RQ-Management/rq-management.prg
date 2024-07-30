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

updateRqStatus(lcIdMvTrade, 1)

ENDFUNC

*---------------------------------------------------

FUNCTION createOC(lcIdMvTrade)

updateRqStatus(lcIdMvTrade, 2)

ENDFUNC

*---------------------------------------------------

FUNCTION updateRqStatus(lcIdMvTrade, lcEstado)

lcSqlQuery = "UPDATE MVTRADE SET RQ_ESTADO = RQ_ESTADO + " + TRANSFORM(lcEstado) + ;
			 " WHERE IDMVTRADE = '" + TRANSFORM(lcIdMvTrade) + "'"

IF SQLEXEC(ON, lcSqlQuery) != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al actualizar el estado de la RQ para el registro IdMvTrade " + ALLTRIM(TRANSFORM(lcIdMvTrade)) + ".")
ENDIF

ENDFUNC

*---------------------------------------------------

FUNCTION getRqTipoDcto() AS INTEGER
LOCAL lcValidation

lcSqlQuery = "SELECT TIPODCTO FROM TIPODCTO WHERE DCTOMAE = 'RQ' AND X_CURRENT = 1"

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al consultar el tipo documento de requisiciones.")
ENDIF

SELECT lcValidation
GO TOP
RETURN lcValidation.TIPODCTO

USE IN SELECT ("lcValidation")

RETURN

ENDFUNC


