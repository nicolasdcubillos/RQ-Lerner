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

FUNCTION uploadFile(lcFileName) AS CURSOR & && Carga el archivo de Excel y retorna un bool haciendo referencia al resultado

LOCAL outErrorMsg
TRY
	CREATE CURSOR lcRqData( ;
		CodProveedor C(20), ;
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

		lcCodProveedor = validateLine(oSheet.Cells(lnRow, 1).VALUE, "C", oSheet.Cells(1, 1).VALUE, @outErrorMsg)
		lcNombreProveedor = validateLine(oSheet.Cells(lnRow, 2).VALUE, "C", oSheet.Cells(1, 2).VALUE, @outErrorMsg)
		lcISBN = validateLine(oSheet.Cells(lnRow, 3).VALUE, "C", oSheet.Cells(1, 3).VALUE, @outErrorMsg)
		lcTitulo = validateLine(oSheet.Cells(lnRow, 4).VALUE, "C", oSheet.Cells(1, 4).VALUE, @outErrorMsg)
		lcAutor = validateLine(oSheet.Cells(lnRow, 5).VALUE, "C", oSheet.Cells(1, 5).VALUE, @outErrorMsg)
		lcEditorial = validateLine(oSheet.Cells(lnRow, 6).VALUE, "C", oSheet.Cells(1, 6).VALUE, @outErrorMsg)
		lcTema = validateLine(oSheet.Cells(lnRow, 7).VALUE, "C", oSheet.Cells(1, 7).VALUE, @outErrorMsg)
		lnPrecio = validateLine(oSheet.Cells(lnRow, 8).VALUE, "N", oSheet.Cells(1, 8).VALUE, @outErrorMsg)
		lnCantidad = validateLine(oSheet.Cells(lnRow, 9).VALUE, "N", oSheet.Cells(1, 9).VALUE, @outErrorMsg)
		lcSede = validateLine(oSheet.Cells(lnRow, 10).VALUE, "C", oSheet.Cells(1, 10).VALUE, @outErrorMsg)
		lcLibrero = validateLine(oSheet.Cells(lnRow, 11).VALUE, "C", oSheet.Cells(1, 11).VALUE, @outErrorMsg)
		lcEstado = validateLine(oSheet.Cells(lnRow, 12).VALUE, "C", oSheet.Cells(1, 12).VALUE, @outErrorMsg)

		IF EMPTY(outErrorMsg)
			oSheet.Cells(lcActualRow, lnLastCol).VALUE = ""

			INSERT INTO lcRqData VALUES ( ;
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

SELECT lcRqData
BROWSE
BROWSE
BROWSE


RETURN lcRqData

ENDFUNC

*---------------------------------------------------

FUNCTION validateLine(lcData, lcDataType, lcColumnName, outErrorMsg) AS STRING
    LOCAL lcValue
    MESSAGEBOX("Datos recibidos:" + CHR(13) + ;
                   "lcData: " + TRANSFORM(lcData) + CHR(13) + ;
                   "lcTypeReal: " + TYPE(lcData) + CHR(13) + ;
                   "lcDataType: " + lcDataType + CHR(13) + ;
                   "lcColumnName: " + lcColumnName + CHR(13) + ;
                   "outErrorMsg antes: " + outErrorMsg)

    TRY
        lcValue = IIF(VARTYPE(lcData) == lcDataType, lcData, "")

        IF EMPTY(lcValue)
            outErrorMsg = outErrorMsg + "Campo vacío o tipo incorrecto: " + lcColumnName + ". "
        ENDIF
    CATCH TO oErr
        IF NOT ISNULL(oErr)
            outErrorMsg = outErrorMsg + oErr.MESSAGE + STR(oErr.LINENO)
        ELSE
            outErrorMsg = outErrorMsg + "Error desconocido al validar el campo " + lcColumnName + ". "
        ENDIF
    ENDTRY

    RETURN lcValue
ENDFUNC


*---------------------------------------------------

FUNCTION getConsecutForRQs(lcData, lcDataType, lcColumnName, outErrorMsg) AS STRING &
lcSqlQuery = "SELECT * FROM CONSECUT WHERE TIPODCTO = 'RQ'"

TRY
	MESSAGEBOX('cachon')
CATCH TO lcException
	ERROR('Ocurrió un error consultando el consecutivo de requisiciones.')
	RETURN consecut
ENDTRY
ENDFUNC