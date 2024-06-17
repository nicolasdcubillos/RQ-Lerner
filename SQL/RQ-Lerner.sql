USE AJOVECO_NE;

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
	SET @rqConsecut = (SELECT CONSECUT FROM CONSECUT WHERE TIPODCTO = 'RQ');

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
	@codProveedor,		/* Nit */
	@gCodUsuario,		/* Passwordin */
	@codProveedor,		/* Nitresp */
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
	@codProveedor,		/* Nit */
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
	MVTRADE.CANTIDAD
	FROM
	TRADE,
	MVTRADE,
	TIPODCTO,
	FNVOF_REPORTECATALOGO(YEAR(@fecha2), MONTH(@fecha2)) AS RCATALOGO
	WHERE
	TIPODCTO.DCTOMAE = 'RQ' AND
	TIPODCTO.TIPODCTO = 'RQ' AND
	TRADE.NRODCTO = MVTRADE.NRODCTO AND
	TRADE.TIPODCTO = MVTRADE.TIPODCTO AND
	TRADE.ORIGEN = MVTRADE.ORIGEN AND
	RCATALOGO.PRODUCTO = MVTRADE.PRODUCTO AND
	TRADE.FECING BETWEEN @fecha1 AND @fecha2
)

/* SELECT * FROM RQ_ConsolidadoRequisiciones('20240615', '20240617') */