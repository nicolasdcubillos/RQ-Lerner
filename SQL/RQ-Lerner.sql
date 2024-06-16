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
	(SELECT NIT FROM MTPROCLI WHERE CODALTERNO = @codProveedor),	/* Nit | No es lógico el requerimiento */
	@gCodUsuario,		/* Passwordin */
	0,					/* Nitresp | Arreglar, quemado porque no es lógico el requerimiento en el Word */
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
	(SELECT NIT FROM MTPROCLI WHERE CODALTERNO = @codProveedor),	/* Nit | No es lógico el requerimiento */
	@codISBN,			/* Producto */
	(SELECT DESCRIPCIO FROM MTMERCIA WHERE CODIGO = @codISBN),		/* Nombre */
	@cantidad,			/* Cantidad */
	@cantidad,			/* Cantorig */
	@codSede,			/* Codcc */
	'0',				/* Tipomvto */
	(SELECT UNDCONVERS FROM MTMERCIA WHERE CODIGO = @codISBN),		
	(SELECT UNDCONVERS FROM MTMERCIA WHERE CODIGO = @codISBN),		
	@precio,			/* Valorunit */
	@precio,			/* Vlrventa */
	@gCodUsuario);		/* Passwordin */

	UPDATE CONSECUT SET CONSECUT = CONSECUT + 1 WHERE TIPODCTO = 'RQ';
END;

GO

/* 
	EXEC dbo.GuardarRequisicion '99.00', '123', '123.00', '001                                               ', 'SPV739596           ', '2.00', '66000.00'
*/