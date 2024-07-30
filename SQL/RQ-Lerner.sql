USE LERNER;
/* USE LERNER_PLUS */

/* Creando el campo RQ_CANTIDAD_DESPACHO si no existe en MVTRADE */

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'MVTRADE' 
    AND COLUMN_NAME = 'RQ_CANTIDAD_DESPACHO'
)
BEGIN
    ALTER TABLE MVTRADE
    ADD RQ_CANTIDAD_DESPACHO NUMERIC;
END;

GO
/* Creando el campo RQ_CANTIDAD_OC si no existe en MVTRADE */

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'MVTRADE' 
    AND COLUMN_NAME = 'RQ_CANTIDAD_OC'
)
BEGIN
    ALTER TABLE MVTRADE
    ADD RQ_CANTIDAD_OC NUMERIC;
END;

GO
/* 
	Creando el campo RQ_ESTADO si no existe en MVTRADE 

	ESTADOS POSIBLES:
		0. RQ creada
		1. Enviado a despacho
		2. OC creada
		3. Enviado a despacho & OC creada
*/

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'MVTRADE' 
    AND COLUMN_NAME = 'RQ_ESTADO'
)
BEGIN
    ALTER TABLE MVTRADE
    ADD RQ_ESTADO NUMERIC;
END;


DROP PROCEDURE dbo.GuardarTradeRequisicion;
GO
DROP PROCEDURE dbo.GuardarMvTradeRequisicion;
GO
DROP PROCEDURE dbo.RQ_SaldoInventarioProducto;
GO
DROP FUNCTION [dbo].[RQ_ConsolidadoRequisiciones]
GO

/* 
	Function GuardarTradeRequisicion:
		Función que guarda una línea de requisición en Trade.
	Parámetros:
		Los necesarios para almacenar la información en Trade.
*/

CREATE PROCEDURE dbo.GuardarTradeRequisicion 
@codProveedor VARCHAR(255),
@gCodUsuario VARCHAR(255),
@codResponsable VARCHAR(255),
@codSede VARCHAR(255),
@codISBN VARCHAR(255),
@rqTipoDcto VARCHAR(255),
@rqConsecut INTEGER
AS
BEGIN

    INSERT INTO 
	TRADE 
	(
	ORIGEN, 
	TIPODCTO, 
	NRODCTO, 
	FECHA, 
	FECING, 
	HORA, 
	NIT, 
	PASSWORDIN,
	NITRESP,
	CODCC) 
	VALUES 
	(
	'COM',				/* Origen */
	@rqTipoDcto,		/* Tipodcto */
	@rqConsecut,		/* Nrodcto */
	GETDATE(),			/* Fecha */
	GETDATE(),			/* Fecing */
	(SELECT CONVERT(VARCHAR(8), GETDATE(), 108)),					/* Hora */
	(SELECT NIT FROM MTPROCLI WHERE CAST(DETALLE AS VARCHAR(255)) = @codProveedor),		/* Nit */
	@gCodUsuario,		/* Passwordin */
	@codResponsable,	/* Nitresp */
	@codSede			/* Codsede */
	);	
END;
GO

/* 
	Function GuardarMvTradeRequisicion:
		Función que guarda una línea de requisición en MvTrade.
	Parámetros:
		Los necesarios para almacenar la información en MvTrade.
*/

CREATE PROCEDURE dbo.GuardarMvTradeRequisicion
@codProveedor VARCHAR(255),
@gCodUsuario VARCHAR(255),
@codSede VARCHAR(255),
@codISBN VARCHAR(255),
@cantidad VARCHAR(255),
@precio NUMERIC(12, 2),
@rqTipoDcto VARCHAR(255),
@rqConsecut INTEGER
AS
BEGIN

    INSERT INTO 
	MVTRADE 
	(
	ORIGEN,			
	TIPODCTO,		
	NRODCTO,		
	FECHA, 
	FECING,
	NIT,
	PRODUCTO,
	NOMBRE,
	CANTIDAD,
	CANTORIG,
	RQ_CANTIDAD_DESPACHO,
	RQ_CANTIDAD_OC,
	CANVENTA,
	CODCC,
	TIPOMVTO,
	UNDBASE,
	UNDVENTA,
	VALORUNIT,
	VLRVENTA,
	PASSWORDIN,
	RQ_ESTADO) 
	VALUES 
	(
	'COM',				/* Origen */
	@rqTipoDcto,		/* Tipodcto */
	@rqConsecut,		/* Nrodcto */
	GETDATE(),			/* Fecha */
	GETDATE(),			/* Fecing */
	(SELECT NIT FROM MTPROCLI WHERE CAST(DETALLE AS VARCHAR(255)) = @codProveedor),		/* Nit */
	@codISBN,			/* Producto */
	(SELECT DESCRIPCIO FROM MTMERCIA WHERE CODIGO = @codISBN),		/* Nombre */
	@cantidad,			/* Cantidad */
	@cantidad,			/* Cantorig */
	@cantidad,			/* RQ_Cantidad_Despacho */
	@cantidad,			/* RQ_Cantidad_OC */
	@cantidad,			/* Canventa */
	@codSede,			/* Codcc */
	'0',				/* Tipomvto */
	(SELECT UNIDADMED FROM MTMERCIA WHERE CODIGO = @codISBN),		/* Undbase */
	(SELECT UNIDADMED FROM MTMERCIA WHERE CODIGO = @codISBN),		/* Undventa */
	@precio,			/* Valorunit */
	@precio,			/* Vlrventa */
	@gCodUsuario,		/* Passwordin */
	0);					/* RQ_Estado */

END;
GO

/* 
	Function GuardarTradeOC:
		Función que guarda una línea de órden de compra en Trade.
	Parámetros:
		Los necesarios para almacenar la información en Trade.
*/

CREATE PROCEDURE dbo.GuardarTradeOC
@codProveedor VARCHAR(255),
@gCodUsuario VARCHAR(255),
@codResponsable VARCHAR(255),
@codSede VARCHAR(255),
@codISBN VARCHAR(255),
@rqTipoDcto VARCHAR(255),
@rqConsecut INTEGER
AS
BEGIN

    INSERT INTO 
	TRADE 
	(
	ORIGEN, 
	TIPODCTO, 
	NRODCTO, 
	FECHA, 
	FECING, 
	HORA, 
	NIT, 
	PASSWORDIN,
	NITRESP,
	CODCC) 
	VALUES 
	(
	'COM',				/* Origen */
	@rqTipoDcto,		/* Tipodcto */
	@rqConsecut,		/* Nrodcto */
	GETDATE(),			/* Fecha */
	GETDATE(),			/* Fecing */
	(SELECT CONVERT(VARCHAR(8), GETDATE(), 108)),					/* Hora */
	(SELECT NIT FROM MTPROCLI WHERE CAST(DETALLE AS VARCHAR(255)) = @codProveedor),		/* Nit */
	@gCodUsuario,		/* Passwordin */
	@codResponsable,	/* Nitresp */
	@codSede			/* Codsede */
	);	
END;
GO

/* 
	Function RQ_ConsolidadoRequisiciones:
		Esta función retorna el consolidado de requisiciones dada una fecha inicial y final.
		Revisará si el estado de la RQ es cero o nulo, significa que la RQ no ha sido pasada a despacho y/o órden de compra.
	Parámetros:
		@fecha1: Fecha inicial de la consulta
		@fecha2: Fecha final de la consulta
		@rqTipoDcto: El tipo de documento sobre el cual se va a generar la consulta
*/

CREATE FUNCTION [dbo].[RQ_ConsolidadoRequisiciones]
(
	@fecha1 date,
	@fecha2 date,
	@rqTipoDcto VARCHAR(255)
)
Returns Table
AS
Return
(
	SELECT 
	CONVERT(VARCHAR, TRADE.FECING, 23) AS FECING,
	RTRIM(TRADE.TIPODCTO) AS TIPODCTO,
	RTRIM(TRADE.NRODCTO) AS NRODCTO,
	MVTRADE.IDMVTRADE,
	MVTRADE.PRODUCTO,
	MVTRADE.NOMBRE,
	TRADE.CODCC,
	TRADE.NIT AS RESPONSABLE,
	CAST(MVTRADE.CANTIDAD AS INTEGER) AS CANTIDAD,
	0 AS CHECKDESPACHO,
	CAST(MVTRADE.RQ_CANTIDAD_DESPACHO AS INTEGER) AS CANTIDAD_DESPACHO,
	0 AS CHECKOC,
	CAST(MVTRADE.RQ_CANTIDAD_OC AS INTEGER) AS CANTIDAD_OC
	FROM
	TRADE,
	MVTRADE
	WHERE
	TRADE.TIPODCTO = @rqTipoDcto AND
	TRADE.NRODCTO = MVTRADE.NRODCTO AND
	TRADE.TIPODCTO = MVTRADE.TIPODCTO AND
	TRADE.ORIGEN = MVTRADE.ORIGEN AND
	TRADE.FECING BETWEEN @fecha1 AND DATEADD(DAY, 1, @fecha2) AND
	MVTRADE.RQ_ESTADO IS NULL OR MVTRADE.RQ_ESTADO = 0
)

GO

/* 
	Procedure RQ_SaldoInventarioProducto:
		Este procedure consulta el saldo de inventario para las RQs encontradas en un rango de fechas y por medio de la 
		función PIVOT la retorna en columnas variables (columna por ubicación y su saldo de inventario).
		El número de columnas varía dependiendo de las sedes que se tengan creadas en el sistema.
	Parámetros:
		@fecha1: Fecha inicial de la consulta
		@fecha2: Fecha final de la consulta
		@rqTipoDcto: El tipo de documento sobre el cual se va a generar la consulta
*/

CREATE PROCEDURE [dbo].[RQ_SaldoInventarioProducto]
(
    @fecha1 DATE,
    @fecha2 DATE,
	@rqTipoDcto VARCHAR(255)
)
AS
BEGIN
    DECLARE @columns NVARCHAR(MAX), @sql NVARCHAR(MAX);
    DECLARE @year INT = YEAR(@fecha2);
    DECLARE @month INT = MONTH(@fecha2);

    -- Get the distinct GRUPO values and concatenate them into a string
    SELECT @columns = STUFF((
	SELECT DISTINCT ', ' + QUOTENAME(GRUPO)
	FROM TEMP_UBICACIONES
	FOR XML PATH(''), TYPE
	).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

    -- Build the dynamic SQL query
    SET @sql = N'
    SELECT ' + @columns + ', TIPODCTO, NRODCTO, PRODUCTO, IDMVTRADE
    FROM 
    (
        SELECT 
            Requisiciones.TIPODCTO,
            Requisiciones.NRODCTO,
            Requisiciones.PRODUCTO,
			Requisiciones.IDMVTRADE,
            UBIC.GRUPO,
            COALESCE(CAST(SUM(ISNULL(RCATALOGO.SALDO, 0)) AS INT), 0) AS SALDO
        FROM 
            (SELECT DISTINCT TIPODCTO, NRODCTO, PRODUCTO, IDMVTRADE
             FROM RQ_ConsolidadoRequisiciones(''' + CONVERT(NVARCHAR, @fecha1, 112) + ''', ''' + CONVERT(NVARCHAR, @fecha2, 112) + ''', ''' + @rqTipoDcto + ''')
            ) AS Requisiciones
        LEFT JOIN 
            FNVOF_REPORTECATALOGO(' + CAST(@year AS NVARCHAR(4)) + ', ' + CAST(@month AS NVARCHAR(2)) + ') RCATALOGO
        ON 
            Requisiciones.PRODUCTO = RCATALOGO.PRODUCTO
        LEFT JOIN 
            TEMP_UBICACIONES UBIC
        ON 
            RCATALOGO.UBICACION = UBIC.CODIGO
        GROUP BY 
            Requisiciones.TIPODCTO, Requisiciones.NRODCTO, Requisiciones.PRODUCTO, Requisiciones.IDMVTRADE, UBIC.GRUPO
    ) AS SourceTable
    PIVOT
    (
        MAX(SALDO)
        FOR GRUPO IN (' + @columns + N')
    ) AS PivotTable';

    -- Wrap the PIVOT result to replace NULLs with empty string
    SET @sql = N'
    SELECT ' + @columns + ',
           ISNULL(TIPODCTO, '''') AS TIPODCTO, 
           ISNULL(NRODCTO, '''') AS NRODCTO, 
           ISNULL(PRODUCTO, '''') AS PRODUCTO,
           ISNULL(IDMVTRADE, '''') AS IDMVTRADE
    FROM (' + @sql + N') AS Pivoted';

    -- Execute the dynamic SQL query
    EXEC sp_executesql @sql;
END;
GO

/*
	EXEC dbo.RQ_SaldoInventarioProducto '20240115', '20241030', 'RQ'

	SELECT TIPODCTO, NRODCTO FROM TRADE;

	SELECT TIPODCTO, NRODCTO, RQ_ESTADO FROM MVTRADE;

	DELETE FROM MVTRADE;

	DELETE FROM TRADE;

	SELECT TIPODCTO, NRODCTO, RQ_CANTIDAD_FINAL FROM MVTRADE 

CREATE TABLE TEMP_UBICACIONES (
    codigo VARCHAR(50) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    grupo VARCHAR(50) NOT NULL,
    sigla VARCHAR(50) NOT NULL,
    centrocosto VARCHAR(50) NOT NULL
);

SELECT 
SIGLA 
FROM 
TEMP_UBICACIONES 
WHERE
SIGLA NOT LIKE '%APLICA%'
GROUP BY 
SIGLA;
SELECT * FROM TEMP_UBICACIONES;
SELECT SIGLA FROM TEMP_UBICACIONES WHERE CODIGO = 'CA1'


SELECT GRUPO, SIGLA FROM TEMP_UBICACIONES GROUP BY GRUPO, SIGLA; 



SELECT 
UBIC.GRUPO,
SUM(SALDO)
FROM 
FNVOF_REPORTECATALOGO(2025, 05) RCATALOGO
RIGHT OUTER JOIN
TEMP_UBICACIONES UBIC ON RCATALOGO.UBICACION = UBIC.CODIGO
WHERE 
RCATALOGO.PRODUCTO = '076645906205-1667   '
GROUP BY
UBIC.GRUPO

SELECT GRUPO FROM TEMP_UBICACIONES GROUP BY GRUPO



SELECT 
    UBIC.GRUPO + REPLICATE(' ', 5) + CAST(SUM(SALDO) AS VARCHAR(20)) AS ConcatenatedResult
FROM 
    FNVOF_REPORTECATALOGO(2025, 05) RCATALOGO,
    TEMP_UBICACIONES UBIC
WHERE 
    RCATALOGO.PRODUCTO = '076645906205-1667   ' AND
    RCATALOGO.UBICACION = UBIC.CODIGO
GROUP BY
    UBIC.GRUPO
	

GO

	EXEC dbo.GuardarRequisicion '99', '123', '123', '001                                               ', 'SPV739596           ', '5', '12000'
	SELECT * FROM RQ_ConsolidadoRequisiciones('20240615', '20241026', 'RQ') 

	/*DROP TABLE RQ_EXCEL_CONFIG;*/

/*
CREATE TABLE RQ_EXCEL_CONFIG (
    COLUMN_NAME NVARCHAR(100),
    EXCLUDE_VALIDATIONS BIT,
    DATA_TYPE NVARCHAR(50),
    POSITION INT
);

INSERT INTO RQ_EXCEL_CONFIG (COLUMN_NAME, EXCLUDE_VALIDATIONS, DATA_TYPE, POSITION) VALUES
('cod proveedor', 0, 'I', 1),
('nombre proveedor', 0, 'C', 2),
('isbn', 0, 'C', 3),
('titulo', 0, 'C', 4),
('autor', 0, 'C', 5),
('editorial', 0, 'C', 6),
('tema', 0, 'C', 7),
('precio', 0, 'N', 8),
('cantidad', 0, 'I', 9),
('SEDE', 0, 'C', 10),
('LIBRERO', 0, 'C', 11),
('ESTADO', 0, 'C', 12);

SELECT * FROM RQ_EXCEL_CONFIG ORDER BY POSITION;
*/
*/