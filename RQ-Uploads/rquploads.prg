*/
*!*
*!*		Nombre: Cargue de Requisiciones desde Archivo Excel - Libreria Lerner
*!*
*!*		Autor: Nicolás David Cubillos
*!*
*!*		Contenido:
*!*
*!*		Fecha: 1 de junio de 2024
*!*
*/

*---------------------------------------------------
FUNCTION uploadFile(lcFileName, outRqData) AS CURSOR & && Carga el archivo de Excel y retorna un bool haciendo referencia al resultado

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
		Librero C(50), ;
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

		lcCodProveedor = validateLine(oSheet.Cells(lnRow, 1).VALUE, "N", oSheet.Cells(1, 1).VALUE, @outErrorMsg)
		lcNombreProveedor = validateLine(oSheet.Cells(lnRow, 2).VALUE, "C", oSheet.Cells(1, 2).VALUE, @outErrorMsg)
		
		lcISBN = validateLine(oSheet.Cells(lnRow, 3).VALUE, "C", oSheet.Cells(1, 3).VALUE, @outErrorMsg)
		validateISBN(lcCodProveedor, @outErrorMsg)
		
		lcTitulo = TRANSFORM(oSheet.Cells(lnRow, 4).VALUE)
		lcAutor = TRANSFORM(oSheet.Cells(lnRow, 5).VALUE)
		lcEditorial = TRANSFORM(oSheet.Cells(lnRow, 6).VALUE)
		lcTema = TRANSFORM(oSheet.Cells(lnRow, 7).VALUE)
		
		lnPrecio = validateLine(oSheet.Cells(lnRow, 8).VALUE, "N", oSheet.Cells(1, 8).VALUE, @outErrorMsg)
		lnCantidad = validateLine(oSheet.Cells(lnRow, 9).VALUE, "N", oSheet.Cells(1, 9).VALUE, @outErrorMsg)

		lcSede = validateLine(oSheet.Cells(lnRow, 10).VALUE, "C", oSheet.Cells(1, 10).VALUE, @outErrorMsg)
		validateSede(lcSede, @outErrorMsg)
		
		lcLibrero = validateLine(oSheet.Cells(lnRow, 11).VALUE, "C", oSheet.Cells(1, 11).VALUE, @outErrorMsg)
		lcEstado = validateLine(oSheet.Cells(lnRow, 12).VALUE, "C", oSheet.Cells(1, 12).VALUE, @outErrorMsg)

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
				lcLibrero, ;
				lcEstado ;
				)

		ELSE
			lcLinesWithErrors = lcLinesWithErrors + 1
			oSheet.Cells(lnRow, lnLastCol).VALUE = outErrorMsg
		ENDIF
	NEXT
	
	IF lcLinesWithErrors > 0
		lcErrorMessage = "Algunas filas en el archivo contienen errores de validación." + CHR(13) + "Revise el archivo Excel que se ha abierto para ver los detalles del error."
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

FUNCTION validateLine(lcData, lcDataType, lcColumnName, outErrorMsg) AS STRING
*!*	    MESSAGEBOX("Datos recibidos:" + CHR(13) + ;
*!*	                   "lcData: " + TRANSFORM(lcData) + CHR(13) + ;
*!*	                   "lcTypeReal: " + VARTYPE(lcData) + CHR(13) + ;
*!*	                   "lcDataType: " + lcDataType + CHR(13) + ;
*!*	                   "lcColumnName: " + lcColumnName + CHR(13) + ;
*!*	                   "outErrorMsg antes: " + outErrorMsg)

    TRY
	    IF(VARTYPE(lcData) != lcDataType)
		    ERROR("Campo con tipo de dato incorrecto: " + lcColumnName + " | ")
		ENDIF
		
		IF EMPTY(lcData)
			ERROR("Campo vacío: " + lcColumnName + " | ")
        ENDIF
    CATCH TO oErr
        outErrorMsg = outErrorMsg + oErr.Message
    ENDTRY

    RETURN lcData
ENDFUNC

*---------------------------------------------------

FUNCTION validateISBN(lcCodProveedor, outErrorMsg)
LOCAL lcValidation

lcSqlQuery = "SELECT CODIGO FROM MTMERCIA WHERE CODIGO = '" + TRANSFORM(lcCodProveedor) + "'"

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	ERROR("Error al validar el ISBN.")
ENDIF

SELECT lcValidation
GO TOP
IF EOF()
	outErrorMsg = outErrorMsg + "El ISBN no se encontró en la tabla MTMERCIA. |"
ENDIF

USE IN SELECT ("lcValidation")

ENDFUNC

*---------------------------------------------------

FUNCTION validateSede(lcSede, outErrorMsg)
LOCAL lcValidation

lcSqlQuery = "SELECT CODCC FROM CENTCOS WHERE CODCC = '" + TRANSFORM(lcSede) + "'"
_CLIPTEXT = lcSqlQuery

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	ERROR("Error al validar la sede.")
ENDIF

SELECT lcValidation
GO TOP
IF EOF()
	outErrorMsg = outErrorMsg + "La sede no se encontró en la tabla CENTCOS. |"
ENDIF

USE IN SELECT ("lcValidation")

ENDFUNC

*---------------------------------------------------

FUNCTION validateResponsable(lcResponsable, outErrorMsg)
LOCAL lcValidation

lcSqlQuery = "SELECT CODCC FROM MTRESPON WHERE CODCC = '" + TRANSFORM(lcResponsable) + "'"
_CLIPTEXT = lcSqlQuery

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	ERROR("Error al validar el responsable.")
ENDIF

SELECT lcValidation
GO TOP
IF EOF()
	outErrorMsg = outErrorMsg + "La sede no se encontró en la tabla MTRESPON. |"
ENDIF

USE IN SELECT ("lcValidation")

ENDFUNC

*---------------------------------------------------

FUNCTION getConsecutForRQs(lcData, lcDataType, lcColumnName, outErrorMsg) AS STRING &
lcSqlQuery = "SELECT * FROM CONSECUT WHERE TIPODCTO = 'RQ'"
TRY
	MESSAGEBOX('Not implemented.')
CATCH TO lcException
	ERROR('Ocurrió un error consultando el consecutivo de requisiciones.')
	RETURN consecut
ENDTRY
ENDFUNC

*---------------------------------------------------

FUNCTION saveRQ(lcData, lcDataType, lcColumnName, outErrorMsg) AS STRING &
lcSqlQuery = "SELECT * FROM CONSECUT WHERE TIPODCTO = 'RQ'"
IF SQLEXEC(ON, lcSqlQuery, "C_EMPLEADOS") != 1
	ERROR("Error al guardar la requisicion.")
ENDIF
ENDFUNC
