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
FUNCTION uploadFile(lcFileName, outRqData)

LOCAL outErrorMsg
TRY
	CREATE CURSOR outRqData( ;
		Cargar N(1, 0), ;
		CodProveedor N(12,2), ;
		NombreProveedor C(50), ;
		ISBN C(20), ;
		Titulo C(100), ;
		AUTOR C(50), ;
		Editorial C(50), ;
		Tema C(50), ;
		Precio N(12,2), ;
		Cantidad N(10,2), ;
		Sede C(50), ;
		Responsable N(10,0), ;
		Estado C(50) ;
		)

	lcLinesWithErrors = 0

	oExcel = CREATEOBJECT("Excel.Application")
	oWorkbook = oExcel.Workbooks.OPEN(lcFileName)
	oExcel.Visible = .T.
&&	oWorkbook.READONLY = .F.
	oSheet = oWorkbook.Sheets(1)

	* Agregar una nueva columna para los errores al final de la hoja
	lnLastCol = oSheet.UsedRange.COLUMNS.COUNT + 1
	oSheet.Cells(1, lnLastCol).VALUE = "Detalle del error"

	lcActualRow = 1
	outErrorMsg = ""

	FOR lnRow = 2 TO oSheet.UsedRange.ROWS.COUNT
		outErrorMsg = ""

		lcCodProveedor = getAndValidateNumericValue(oSheet.Cells(lnRow, 1).VALUE, oSheet.Cells(1, 1).VALUE, @outErrorMsg)
		lcNombreProveedor = getValue(TRANSFORM(oSheet.Cells(lnRow, 2).VALUE), oSheet.Cells(1, 2).VALUE, @outErrorMsg)
		
		lcISBN = getValue(TRANSFORM(oSheet.Cells(lnRow, 3).VALUE), oSheet.Cells(1, 3).VALUE, @outErrorMsg)
		validateISBN(lcISBN, @outErrorMsg)
		
		lcTitulo = getValue(TRANSFORM(oSheet.Cells(lnRow, 4).VALUE), oSheet.Cells(1, 4).VALUE, @outErrorMsg)
		lcAutor = getValue(TRANSFORM(oSheet.Cells(lnRow, 5).VALUE), oSheet.Cells(1, 5).VALUE, @outErrorMsg)
		lcEditorial = getValue(TRANSFORM(oSheet.Cells(lnRow, 6).VALUE), oSheet.Cells(1, 6).VALUE, @outErrorMsg)
		lcTema = getValue(TRANSFORM(oSheet.Cells(lnRow, 7).VALUE), oSheet.Cells(1, 7).VALUE, @outErrorMsg)
	
		lnPrecio = getAndValidateNumericValue(oSheet.Cells(lnRow, 8).VALUE, oSheet.Cells(1, 8).VALUE, @outErrorMsg)
		lnCantidad = getAndValidateNumericValue(oSheet.Cells(lnRow, 9).VALUE, oSheet.Cells(1, 9).VALUE, @outErrorMsg)

		lcSede = getValue(TRANSFORM(oSheet.Cells(lnRow, 10).VALUE), oSheet.Cells(1, 10).VALUE, @outErrorMsg)
		validateSede(lcSede, @outErrorMsg)
		
		lcResponsable = getAndValidateNumericValue(oSheet.Cells(lnRow, 11).VALUE, oSheet.Cells(1, 11).VALUE, @outErrorMsg)
		validateResponsable(lcResponsable, @outErrorMsg)
		
		lcEstado = getValue(oSheet.Cells(lnRow, 12).VALUE, oSheet.Cells(1, 12).VALUE, @outErrorMsg)

		IF EMPTY(outErrorMsg)
			oSheet.Cells(lcActualRow, lnLastCol).VALUE = ""

			INSERT INTO outRqData VALUES ( ;
				1, ;
				lcCodProveedor, ;
				lcNombreProveedor, ;
				lcISBN, ;
				lcTitulo, ;
				lcAutor, ;
				lcEditorial, ;
				lcTema, ;
				lnPrecio, ;
				lnCantidad, ;
				lcSede, ;
				lcResponsable, ;
				lcEstado ;
				)

		ELSE
			lcLinesWithErrors = lcLinesWithErrors + 1
			oSheet.Cells(lnRow, lnLastCol).VALUE = outErrorMsg
		ENDIF
	NEXT
	
	IF lcLinesWithErrors > 0
		lcErrorMessage = "Algunas filas en el archivo contienen errores de validaci�n." + CHR(13) + CHR(13) + "Revise el archivo Excel que se ha abierto para ver los detalles del error."
		ERROR(lcErrorMessage)
	ELSE
		MESSAGEBOX ('Requisiciones cargadas correctamente desde el archivo.', 64)
	ENDIF
	
	oWorkbook.CLOSE(.F.)
	oExcel.QUIT()
	
	RELEASE oSheet, oWorkbook, oExcel
	
ENDTRY

ENDFUNC

*---------------------------------------------------

FUNCTION getAndValidateNumericValue(lcData, lcColumnName, outErrorMsg) AS STRING
	RETURN getValue(lcData, lcColumnName, @outErrorMsg, .T.)
ENDFUNC

*---------------------------------------------------

FUNCTION getValue(lcData, lcColumnName, outErrorMsg, isNumericValidation) AS STRING
*!*	    MESSAGEBOX("Datos recibidos:" + CHR(13) + ;
*!*	                   "lcData: " + TRANSFORM(lcData) + CHR(13) + ;
*!*	                   "lcTypeReal: " + VARTYPE(lcData) + CHR(13) + ;
*!*	                   "lcColumnName: " + lcColumnName + CHR(13) + ;
*!*	                   "outErrorMsg antes: " + outErrorMsg)

    TRY
    	IF EMPTY(lcData) OR ISNULL(lcData)
			ERROR("Campo vac�o: " + lcColumnName)
			RETURN
        ENDIF        
    	
        IF isNumericValidation == .T.
		    IF(VARTYPE(lcData) != "N")
		    	ERROR("El campo debe ser num�rico: " + lcColumnName)
		    	RETURN
			ENDIF
		ENDIF
		
    CATCH TO oErr
	    buildErrorMessage(@outErrorMsg, oErr.Message)
    ENDTRY
    
	IF isNumericValidation == .T.
		RETURN CAST(lcData AS INTEGER)
	ELSE
	    RETURN lcData
	ENDIF
ENDFUNC

*---------------------------------------------------

FUNCTION validateISBN(lcISBN, outErrorMsg)
LOCAL lcValidation

lcSqlQuery = "SELECT CODIGO FROM MTMERCIA WHERE CODIGO = '" + ALLTRIM(TRANSFORM(lcISBN)) + "'"

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	ERROR("Error al validar el ISBN.")
ENDIF

SELECT lcValidation
GO TOP
IF EOF()
	buildErrorMessage(@outErrorMsg, "El ISBN no se encontr� en la tabla MTMERCIA")
ENDIF

USE IN SELECT ("lcValidation")

ENDFUNC

*---------------------------------------------------

FUNCTION validateSede(lcSede, outErrorMsg)
LOCAL lcValidation

lcSqlQuery = "SELECT CODCC FROM CENTCOS WHERE CODCC = '" + ALLTRIM(TRANSFORM(lcSede)) + "'"
_CLIPTEXT = lcSqlQuery

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	ERROR("Error al validar la sede.")
ENDIF

SELECT lcValidation
GO TOP
IF EOF()
	buildErrorMessage(@outErrorMsg, "La sede no se encontr� en la tabla CENTCOS")
ENDIF

USE IN SELECT ("lcValidation")

ENDFUNC

*---------------------------------------------------

FUNCTION validateResponsable(lcResponsable, outErrorMsg)
LOCAL lcValidation

lcSqlQuery = "SELECT CODCC FROM MTRESPON WHERE CODCC = '" + ALLTRIM(STR(lcResponsable)) + "'"

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	ERROR("Error al validar el responsable.")
ENDIF

SELECT lcValidation
GO TOP
IF EOF()
	buildErrorMessage(@outErrorMsg, "El responsable no se encontr� en la tabla MTRESPON")
ENDIF

USE IN SELECT ("lcValidation")

ENDFUNC

*---------------------------------------------------

FUNCTION buildErrorMessage(outErrorMsg, newError)
	outErrorMsg = IIF(!EMPTY(outErrorMsg), outErrorMsg + " | " + newError, newError)	
ENDFUNC

*---------------------------------------------------

FUNCTION saveRQ(lcCodProveedor, gCodUsuario, lcResponsable, lcSede, lcISBN, lcCantidad, lcPrecio) AS STRING
lcSqlQuery = "EXEC dbo.GuardarRequisicion '" + ;
					  TRANSFORM(lcCodProveedor) + ;
			 "', '" + TRANSFORM(gCodUsuario) + ;
			 "', '" + TRANSFORM(lcResponsable) + ;
			 "', '" + TRANSFORM (lcSede) + ;
			 "', '" + TRANSFORM (lcISBN) + ;
			 "', '" + TRANSFORM (lcCantidad) + ;
			 "', '" + TRANSFORM (lcPrecio) ;
			 + "'"
_CLIPTEXT = lcSqlQuery

IF SQLEXEC(ON, lcSqlQuery) != 1
	ERROR("Error al guardar la requisicion en la base de datos (dbo.GuardarRequisicion).")
ENDIF

ENDFUNC
