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

lcSqlQuery = "UPDATE MVTRADE SET RQ_ESTADO = ISNULL(RQ_ESTADO, 0) + " + TRANSFORM(lcEstado) + ;
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

FOR i = lcStartAsignaciones TO lcStartAsignaciones + lcTotalAsignaciones - 1
	lcColumnName = FIELD(i, "outRqData")
	lcColumnValue = EVAL("outRqData." + lcColumnName)
	IF (lcColumnValue != 0)
		lcValidation = 1
		EXIT
	ELSE
		IF (lcColumnValue < 0)
			ERROR(CHR(13) + CHR(13) + "Una o más cantidades asignadas a una ubicación contienen valores negativos." + CHR(13) + CHR(13) + "Revise la información ingresada e intente nuevamente.")
		ENDIF
	ENDIF
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
lcCantidadTotal = 0
GO TOP
SCAN

	saveData(outRqData.IDMVTRADE2, outRqData.CANTIDAD_O) && Irá a guardar la cantidad editable indiferentemente de si se crea OC o no
	lcCodProveedString = TRANSFORM(outRqData.CodProveed)
	IF outRqData.CHECKOC == 1
		TRY
			ocConsecutAssigned = oCodProveedorCollection.ITEM(lcCodProveedString)
		CATCH
			ocConsecutAssigned = getOCConsecut()
			lcLastGenerated = ocConsecutAssigned

			IF lcFirstGenerated == 0
				lcFirstGenerated = ocConsecutAssigned
			ENDIF

			oCodProveedorCollection.ADD(ocConsecutAssigned, lcCodProveedString)

			saveTrade(outRqData.CodProveed, ;
				gCodUsuario, ;
				0, ;
				outRqData.CODCC, ;
				outRqData.PRODUCTO_A, ;
				ocConsecutAssigned)

			updateOCConsecut()
		ENDTRY

		FOR i = lcStartAsignaciones TO lcStartAsignaciones + lcTotalAsignaciones - 1
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
					
		    	lcCantidadTotal = lcCantidadTotal + lcCantidad
			ENDIF
		NEXT
		
		lcBruto = lcCantidadTotal * outRqData.VALORUNIT
		updateRqTotals(ocConsecutAssigned, lcBruto)

		updateRqStatus(outRqData.IdMvTrade_, 2)

		lcOcCreated = lcOcCreated + 1
		
	ENDIF

ENDSCAN

ENDFUNC

*---------------------------------------------------

FUNCTION updateRqTotals(ocConsecutAssigned, lcBruto) AS INTEGER
LOCAL lcValidation

lcSqlQuery = "UPDATE TRADE SET BRUTO = " + ALLTRIM(TRANSFORM(lcBruto)) + " WHERE TIPODCTO = '" + ocTipoDctoMae + "' AND NRODCTO = " + ALLTRIM(TRANSFORM(ocConsecutAssigned))

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al actualizar el total (campo BRUTO) para una órden de compra.")
ENDIF

USE IN SELECT ("lcValidation")

RETURN

ENDFUNC


*---------------------------------------------------

FUNCTION getCodCcByNombreGrupo(lcNombreGrupo) AS INTEGER
LOCAL lcValidation

lcSqlQuery = "SELECT CODCC FROM X_SIGLAUBICA WHERE GRUPO = '" + lcNombreGrupo + "'"

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al consultar el centro de costo para el grupo " + lcNombreGrupo + ".")
ENDIF

SELECT lcValidation
GO TOP
RETURN lcValidation.CODCC

USE IN SELECT ("lcValidation")

ENDFUNC

*---------------------------------------------------

FUNCTION getRQs(lcForm)

IF lcBusqueda = .T.
	lcErrorMessage = "Para realizar una nueva búsqueda, cierre y vuelva a abrir la pantalla."
	ERROR(lcErrorMessage)
ENDIF

IF lcForm.Optiongroup1.VALUE = 1
	WAIT WINDOW "Consultando información de requisiciones para el periodo seleccionado..." NOWAIT

	lcSqlQueryConsolidado = "SELECT * FROM RQ_ConsolidadoRequisiciones('" + ;
		TRANSFORM(FECHAINICIAL) + "', '" + ;
		TRANSFORM(FECHAFINAL) +  "', '" + ;
		TRANSFORM(rqTipoDctoMae) + "') " + ;
		"ORDER BY IDMVTRADE"

	lcSqlQuerySaldo = "EXEC dbo.RQ_SaldoInventarioProducto '" + TRANSFORM(FECHAINICIAL) + "', '" + TRANSFORM(FECHAFINAL) + "', '" + TRANSFORM(rqTipoDctoMae) + "'"

ELSE IF THISFORM.Optiongroup1.VALUE = 2

	lcSqlQueryConsolidado = "SELECT * FROM RQ_ConsolidadoRequisicionesRango('" + ;
		TRANSFORM(DESDE) + "', '" + ;
		TRANSFORM(HASTA) +  "', '" + ;
		TRANSFORM(rqTipoDctoMae) + "') " + ;
		"ORDER BY IDMVTRADE"

	lcSqlQuerySaldo = "EXEC dbo.RQ_SaldoInventarioProducto '1999.01.01', '3000.01.01', '" + TRANSFORM(rqTipoDctoMae) + "'"

	WAIT WINDOW "Consultando información de requisiciones para el rango de documentos seleccionado..." NOWAIT
ENDIF

IF SQLEXEC(ON, lcSqlQueryConsolidado, "lcRQConsolidadoRequisiciones") != 1
	_CLIPTEXT = lcSqlQuery
	ERROR ("Error al realizar la consulta de consolidado de requisiciones.")
ENDIF

* Consultando el stored RQ_SaldoInventarioProducto

IF SQLEXEC(ON, lcSqlQuerySaldo, "lcRQSaldoInventarioProducto") != 1
	_CLIPTEXT = lcSqlQuery
	ERROR ("Error al realizar la consulta de saldo de inventarios.")
ENDIF

* Iterar sobre el cursor lcRQSaldoInventarioProducto
IF USED("lcRQSaldoInventarioProducto")
	SELECT lcRQSaldoInventarioProducto
	SCAN
		FOR i = 1 TO FCOUNT()
			lcFieldName = FIELD(i)
			* Reemplazar NULL con cadena vacía
			IF ISNULL(EVAL(lcFieldName))
				REPLACE (lcFieldName) WITH 0
			ELSE
				* Formatear campos numéricos como enteros
				IF TYPE(lcFieldName) == "N"
					REPLACE (lcFieldName) WITH INT(EVAL(lcFieldName))
				ENDIF
			ENDIF
		ENDFOR
	ENDSCAN
ENDIF

* Creando el cursor
countColumnasConsolidado = FLDCOUNT("lcRQConsolidadoRequisiciones")
countColumnasSaldos = FLDCOUNT("lcRQSaldoInventarioProducto")
lnTotal = countColumnasConsolidado + countColumnasSaldos - 4 && Quitando los campos que se usan en la t2 para cruzar TIPODCTO, NRODCTO, PRODUCTO Y IDMVTRADE

* Inicializar una cadena para el comando CREATE CURSOR
lcCreateCursor = "CREATE CURSOR curGenerico ("

* Agregar dinámicamente los campos al comando CREATE CURSOR
FOR i = 1 TO countColumnasConsolidado
	lcFieldName = "Field" + TRANSFORM(i)
	lcCreateCursor = lcCreateCursor + lcFieldName + " C(10), "
ENDFOR

FOR i = 1 TO countColumnasSaldos
	lcFieldName = "Field" + TRANSFORM(countColumnasConsolidado + i)
	lcCreateCursor = lcCreateCursor + lcFieldName + " C(10)"
	IF i < countColumnasSaldos
		lcCreateCursor = lcCreateCursor + ", "
	ENDIF
ENDFOR

lcCreateCursor = lcCreateCursor + ")"

&& Ejecutar el comando CREATE CURSOR dinámico

&lcCreateCursor

SELECT * ;
	FROM lcRQConsolidadoRequisiciones t1, lcRQSaldoInventarioProducto t2 ;
	WHERE t1.TIPODCTO = t2.TIPODCTO AND t1.nrodcto = t2.nrodcto AND t1.producto = t2.producto AND t1.idmvtrade = t2.idmvtrade ;
	INTO CURSOR outRqDataTemp

IF USED("outRqData")
	USE IN outRqData
ENDIF

IF FILE("tempTable.dbf")
	ERASE tempTable.DBF
ENDIF

SELECT outRqDataTemp
COPY TO tempTable
USE tempTable IN 0 ALIAS outRqData

SELECT outRqData
GO TOP

IF EOF()
	ERROR ("No se encontraron requisiciones para el filtro ingresado.")
ENDIF

lcBusqueda = .T.

AFIELDS(lcFieldsTb2, "lcRQSaldoInventarioProducto")

lcForm.rqData.COLUMNCOUNT = lcForm.rqData.COLUMNCOUNT + (countColumnasSaldos) && *2 porque se ponen las asignaciones y los saldos también
lcForm.rqData.RECORDSOURCE = ""

FOR lnColumn = 1 TO countColumnasSaldos

	lcNombreGrupo = lcFieldsTb2[lnColumn, 1]
	lcColor = RGB(206, 231, 230)
	lcText = " - Existencias"
	lcReadOnly = .T.
	lcBold = .T.

	lcNombreGrupo = STRTRAN(lcNombreGrupo, "_", " ")
	lcCodCc = getCodCcByNombreGrupo(lcNombreGrupo)
	lcHeaderCaption = lcNombreGrupo + lcText

	SELECT outRqData

	lcForm.rqData.COLUMNS(lnColumn + countColumnasConsolidado).FONTBOLD = lcBold
	lcForm.rqData.COLUMNS(lnColumn + countColumnasConsolidado).Header1.CAPTION = lcHeaderCaption  && Establece el texto del encabezado
	lcForm.rqData.COLUMNS(lnColumn + countColumnasConsolidado).Header1.BACKCOLOR = lcColor && Establece el color
	lcForm.rqData.COLUMNS(lnColumn + countColumnasConsolidado).Header1.FONTBOLD = .T.  && Establece negrita para el encabezado
	lcForm.rqData.COLUMNS(lnColumn + countColumnasConsolidado).Header1.FONTNAME = "Tahoma"  && Establece la fuente del encabezado
	lcForm.rqData.COLUMNS(lnColumn + countColumnasConsolidado).Header1.FONTSIZE = 8  && Establece el tamaño de la fuente del encabezado
	lcForm.rqData.COLUMNS(lnColumn + countColumnasConsolidado).Header1.ALIGNMENT = 2  && Establece la alineación centrada del encabezado
	lcForm.rqData.COLUMNS(lnColumn + countColumnasConsolidado).WIDTH = 200 && Establece el width para la lectura del saldo de inventario
	lcForm.rqData.COLUMNS(lnColumn + countColumnasConsolidado).Text1.FONTBOLD = .F.  && Establece negrita para el encabezado
	lcForm.rqData.COLUMNS(lnColumn + countColumnasConsolidado).ALIGNMENT = 2  && Establece la alineación centrada de toda la columna
	lcForm.rqData.COLUMNS(lnColumn + countColumnasConsolidado).READONLY = lcReadOnly  && Readonly
	&&BINDEVENT(lcForm.rqData.Columns(lnColumn + countColumnasConsolidado).Text1, "LostFocus", lcForm, "calculateTotalAssigned")

	collectionUbicaciones.ADD(lcCodCc, lcHeaderCaption)
	lcNombreGrupoAsignacion = lcNombreGrupo + " - Asignación"
	collectionUbicaciones.ADD(lcCodCc, lcNombreGrupoAsignacion)

ENDFOR

lcForm.rqData.COLUMNCOUNT = lnTotal
lcForm.rqData.RECORDSOURCE = outRqData
lcForm.checkall.VISIBLE = .T.
lcForm.uncheckall.VISIBLE = .T.
lcForm.generarOC.ENABLED = .T.
lcForm.guardar.ENABLED = .T.

ENDFUNC