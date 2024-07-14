USE LERNER;

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

DROP PROCEDURE dbo.GuardarRequisicion;
GO
DROP PROCEDURE dbo.RQ_SaldoInventarioProducto;
GO
DROP FUNCTION [dbo].[RQ_ConsolidadoRequisiciones]
GO

CREATE PROCEDURE dbo.GuardarRequisicion 
@codProveedor VARCHAR(255),
@gCodUsuario VARCHAR(255),
@codResponsable VARCHAR(255),
@codSede VARCHAR(255),
@codISBN VARCHAR(255),
@cantidad VARCHAR(255),
@precio NUMERIC(12, 2)
AS
BEGIN
	DECLARE @rqConsecut INTEGER;
	SET @rqConsecut = (SELECT CONSECUT FROM CONSECUT WHERE TIPODCTO = 'RQ') + 1;

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
	'RQ',				/* Tipodcto */
	@rqConsecut,		/* Nrodcto */
	GETDATE(),			/* Fecha */
	GETDATE(),			/* Fecing */
	(SELECT CONVERT(VARCHAR(8), GETDATE(), 108)),					/* Hora */
	(SELECT NIT FROM MTPROCLI WHERE CAST(DETALLE AS VARCHAR(255)) = @codProveedor),		/* Nit */
	@gCodUsuario,		/* Passwordin */
	@codResponsable,	/* Nitresp */
	@codSede			/* Codsede */
	);

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
	CODCC,
	TIPOMVTO,
	UNDBASE,
	UNDVENTA,
	VALORUNIT,
	VLRVENTA,
	PASSWORDIN) 
	VALUES 
	(
	'COM',				/* Origen */
	'RQ',				/* Tipodcto */
	@rqConsecut,		/* Nrodcto */
	GETDATE(),			/* Fecha */
	GETDATE(),			/* Fecing */
	(SELECT NIT FROM MTPROCLI WHERE CAST(DETALLE AS VARCHAR(255)) = @codProveedor),		/* Nit */
	@codISBN,			/* Producto */
	(SELECT DESCRIPCIO FROM MTMERCIA WHERE CODIGO = @codISBN),		/* Nombre */
	@cantidad,			/* Cantidad */
	@cantidad,			/* Cantorig */
	@codSede,			/* Codcc */
	'0',				/* Tipomvto */
	(SELECT UNIDADMED FROM MTMERCIA WHERE CODIGO = @codISBN),		/* Undbase */
	(SELECT UNIDADMED FROM MTMERCIA WHERE CODIGO = @codISBN),		/* Undventa */
	@precio,			/* Valorunit */
	@precio,			/* Vlrventa */
	@gCodUsuario);		/* Passwordin */

	UPDATE CONSECUT SET CONSECUT = CONSECUT + 1 WHERE TIPODCTO = 'RQ';
END;

/* 
	EXEC dbo.GuardarRequisicion '99.00', '123', '123.00', '001', 'SPV739596           ', '2.00', '66000.00'
*/

GO

CREATE FUNCTION [dbo].[RQ_ConsolidadoRequisiciones]
(
	@fecha1 date,
	@fecha2 date
)
Returns Table
AS
Return
(
	SELECT 
	1 AS CHECKENVIAR,
	TRADE.FECING,
	TRADE.TIPODCTO,
	TRADE.NRODCTO,
	MVTRADE.PRODUCTO,
	MVTRADE.NOMBRE,
	TRADE.CODCC,
	TRADE.NIT AS RESPONSABLE,
	CAST(MVTRADE.CANTIDAD AS INTEGER) AS CANTIDAD,
	CAST(MVTRADE.CANTIDAD AS INTEGER) AS CANTIDAD_FINAL
	FROM
	TRADE,
	MVTRADE,
	TIPODCTO
	WHERE
	TIPODCTO.DCTOMAE = 'RQ' AND
	TIPODCTO.TIPODCTO = 'RQ' AND
	TRADE.NRODCTO = MVTRADE.NRODCTO AND
	TRADE.TIPODCTO = MVTRADE.TIPODCTO AND
	TRADE.ORIGEN = MVTRADE.ORIGEN AND
	TRADE.FECING BETWEEN @fecha1 AND DATEADD(DAY, 1, @fecha2)
)

/* 

	EXEC dbo.GuardarRequisicion '99', '123', '123', '001                                               ', 'SPV739596           ', '5', '12000'
	SELECT * FROM RQ_ConsolidadoRequisiciones('20240615', '20240626') 
*/

GO
/*
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

*/

CREATE PROCEDURE [dbo].[RQ_SaldoInventarioProducto]
(
    @fecha1 DATE,
    @fecha2 DATE
)
AS
BEGIN
    DECLARE @columns NVARCHAR(MAX), @sql NVARCHAR(MAX);
    DECLARE @year INT = YEAR(@fecha2);
    DECLARE @month INT = MONTH(@fecha2);

    -- Get the distinct GRUPO values and concatenate them into a string
    SELECT @columns = STRING_AGG(QUOTENAME(GRUPO), ', ') 
    FROM (SELECT DISTINCT GRUPO FROM TEMP_UBICACIONES) AS Groups;

    -- Build the dynamic SQL query
    SET @sql = N'
    SELECT ' + @columns + ', TIPODCTO, NRODCTO, PRODUCTO
    FROM 
    (
        SELECT 
            Requisiciones.TIPODCTO,
            Requisiciones.NRODCTO,
            Requisiciones.PRODUCTO,
            UBIC.GRUPO,
            COALESCE(SUM(ISNULL(RCATALOGO.SALDO, 0)), 0) AS SALDO
        FROM 
            (SELECT DISTINCT TIPODCTO, NRODCTO, PRODUCTO 
             FROM RQ_ConsolidadoRequisiciones(''' + CONVERT(NVARCHAR, @fecha1, 112) + ''', ''' + CONVERT(NVARCHAR, @fecha2, 112) + ''')
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
            Requisiciones.TIPODCTO, Requisiciones.NRODCTO, Requisiciones.PRODUCTO, UBIC.GRUPO
    ) AS SourceTable
    PIVOT
    (
        MAX(SALDO)
        FOR GRUPO IN (' + @columns + N')
    ) AS PivotTable';

    -- Execute the dynamic SQL query
    EXEC sp_executesql @sql;
END;
GO



/*
	SELECT * FROM RQ_ConsolidadoRequisiciones('20240615', '20240626')  ORDER BY NRODCTO
	EXEC dbo.RQ_SaldoInventarioProducto '20240615', '20240626'
*/
