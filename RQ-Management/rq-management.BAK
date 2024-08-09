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

FUNCTION saveData(lcIdMvTrade, lcCantidadOc)

lcSqlQuery = "UPDATE MVTRADE SET RQ_CANTIDAD_OC = " + TRANSFORM(lcCantidadOc) + ;
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

FUNCTION updateRqStatus(lcIdMvTrade, lcEstado)

lcSqlQuery = "UPDATE MVTRADE SET RQ_ESTADO = RQ_ESTADO + " + TRANSFORM(lcEstado) + ;
	" WHERE IDMVTRADE = '" + TRANSFORM(lcIdMvTrade) + "'"

IF SQLEXEC(ON, lcSqlQuery) != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al actualizar el estado de la RQ para el registro IdMvTrade " + ALLTRIM(TRANSFORM(lcIdMvTrade)) + ".")
ENDIF

ENDFUNC

*---------------------------------------------------

FUNCTION getRqTipoDcto()
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

*---------------------------------------------------

FUNCTION getOcTipoDcto()
LOCAL lcValidation

lcSqlQuery = "SELECT TIPODCTO FROM TIPODCTO WHERE DCTOMAE = 'OR' AND X_CURRENT = 1"

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

*---------------------------------------------------

FUNCTION getOCConsecut() AS INTEGER
LOCAL lcValidation

lcSqlQuery = "SELECT CONSECUT + 1 AS CONSECUT FROM CONSECUT WHERE TIPODCTO = '" + ocTipoDctoMae + "'"

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al consultar el consecutivo de órdenes de compra.")
ENDIF

SELECT lcValidation
GO TOP
RETURN lcValidation.CONSECUT

USE IN SELECT ("lcValidation")

RETURN

ENDFUNC


*---------------------------------------------------

FUNCTION saveMvTrade(lcCodProveedor, gCodUsuario, lcCodSede, lcISBN, lcCantidad, lcPrecio, rqConsecutAssigned) AS STRING

lcSqlQuery = "EXEC dbo.GuardarMvTradeRequisicion '" + ;
	TRANSFORM(lcCodProveedor) + ;
	"', '" + TRANSFORM(gCodUsuario) + ;
	"', '" + TRANSFORM(lcCodSede) + ;
	"', '" + TRANSFORM(lcISBN) + ;
	"', '" + TRANSFORM(lcCantidad) + ;
	"', '" + TRANSFORM(lcPrecio) + ;
	"', '" + TRANSFORM(ocTipoDctoMae) + ;
	"', '" + TRANSFORM(ocConsecutAssigned) ;
	+ "'"

IF SQLEXEC(ON, lcSqlQuery) != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al guardar la requisicion en la base de datos (dbo.GuardarMvTradeRequisicion) para órdenes de compra.")
ENDIF

ENDFUNC

*---------------------------------------------------

FUNCTION saveTrade(lcCodProveedor, gCodUsuario, lcCodResponsable, lcCodSede, lcISBN, rqConsecutAssigned) AS STRING

lcSqlQuery = "EXEC dbo.GuardarTradeRequisicion '" + ;
	TRANSFORM(lcCodProveedor) + ;
	"', '" + TRANSFORM(gCodUsuario) + ;
	"', '" + TRANSFORM(lcCodResponsable) + ;
	"', '" + TRANSFORM(lcCodSede) + ;
	"', '" + TRANSFORM(lcISBN) + ;
	"', '" + TRANSFORM(ocTipoDctoMae) + ;
	"', '" + TRANSFORM(ocConsecutAssigned) ;
	+ "'"

IF SQLEXEC(ON, lcSqlQuery) != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al guardar la requisicion en la base de datos (dbo.GuardarTradeRequisicion) para órdenes de compra.")
ENDIF

ENDFUNC

*---------------------------------------------------

FUNCTION updateOCConsecut()
LOCAL lcValidation

lcSqlQuery = "UPDATE CONSECUT SET CONSECUT = CONSECUT + 1 WHERE TIPODCTO = '" + ocTipoDctoMae + "'"

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al actualizar el consecutivo de órdenes de compra.")
ENDIF

USE IN SELECT ("lcValidation")

RETURN

ENDFUNC

*---------------------------------------------------

FUNCTION validateOCLine()
lcValidation = 0

FOR i = countColumnasConsolidado + 2 TO lnTotal && + 2 para pararse en el primer valor a asignar de los saldos.
	lcColumnName = FIELD(i, "outRqData")
	lcColumnValue = EVAL("outRqData." + lcColumnName)
	IF (lcColumnValue != 0)
		lcValidation = 1
		EXIT
	ELSE IF (lcColumnValue < 0)
		ERROR(CHR(13) + CHR(13) + "Una o más cantidades asignadas a una ubicación contienen valores negativos." + CHR(13) + CHR(13) + "Revise la información ingresada e intente nuevamente.")
	ENDIF
	i = i + 1
NEXT

IF lcValidation == 0
	ERROR(CHR(13) + CHR(13) + "Debe indicar la distribución de la órden de compra en las ubicaciones para todas las órdenes de compra seleccionadas usando los campos 'Asignación'.")
ENDIF

ENDFUNC
*---------------------------------------------------

FUNCTION validateDataToSave()
SELECT outRqData
GO TOP
SCAN
	IF outRqData.CHECKOC == 1 
		validateOCLine()
	ENDIF
ENDSCAN

ENDFUNC

*---------------------------------------------------

FUNCTION saveOC(lcForm) AS STRING

SELECT outRqData
GO TOP
SCAN
	
	saveData(outRqData.IDMVTRADE2, outRqData.CANTIDAD_O) && Irá a guardar la cantidad editable indiferentemente de si se crea OC o no

	IF outRqData.CHECKOC == 1
		TRY
			ocConsecutAssigned = oCodProveedorCollection.ITEM(outRqData.CodProveed)
		CATCH
			ocConsecutAssigned = getOCConsecut()
			lcLastGenerated = ocConsecutAssigned
			
			IF lcFirstGenerated == 0
				lcFirstGenerated = ocConsecutAssigned
			ENDIF

			oCodProveedorCollection.ADD(ocConsecutAssigned, outRqData.CodProveed)

			saveTrade(outRqData.CodProveed, ;
				gCodUsuario, ;
				0, ;
				outRqData.CODCC, ;
				outRqData.PRODUCTO_A, ;
				ocConsecutAssigned)

			updateOCConsecut()
		ENDTRY

		FOR i = countColumnasConsolidado + 2 TO lnTotal && + 2 para pararse en el primer valor a asignar de los saldos.
			lcColumnName = FIELD(i, "outRqData")
			lcCantidad = EVAL("outRqData." + lcColumnName)
			IF (lcCantidad != 0)
				lcCodCcGrupo = collectionUbicaciones.ITEM(lcForm.rqData.COLUMNS(i).Header1.CAPTION)
				
				saveMvTrade(outRqData.CodProveed, ;
					gCodUsuario, ;
					lcCodCcGrupo, ; 
					outRqData.PRODUCTO_A, ;
					lcCantidad, ;
					outRqData.VALORUNIT, ;
					ocConsecutAssigned)
			ENDIF
			i = i + 1
		NEXT

		updateRqStatus(outRqData.IdMvTrade_, 2)

		lcOcCreated = lcOcCreated + 1
	ENDIF

ENDSCAN

ENDFUNC

*---------------------------------------------------

FUNCTION getCodCcByNombreGrupo(lcNombreGrupo) AS INTEGER
LOCAL lcValidation

RETURN 0
*!*	lcSqlQuery = "SELECT CONSECUT + 1 AS CONSECUT FROM CONSECUT WHERE TIPODCTO = '" + ocTipoDctoMae + "'"

*!*	IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
*!*		_CLIPTEXT = lcSqlQuery
*!*		ERROR("Error al consultar el consecutivo de órdenes de compra.")
*!*	ENDIF

*!*	SELECT lcValidation
*!*	GO TOP
*!*	RETURN lcValidation.CONSECUT

*!*	USE IN SELECT ("lcValidation")

*!*	RETURN

ENDFUNC

