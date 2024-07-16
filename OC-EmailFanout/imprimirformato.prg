********************************************************
* Imprime formatos del sistema
* Fecha  Modificacion 31-May-2012
* Fecha  Compilacion 31-May-2012
********************************************************
***PROGRAMA: ImprimirFormato.Prg
***FUNCION:  Selecciona la informacion para imprimir los nuevos formatos del sistema ATLAS
********************************************************************
***VERSION:  ESTE PROGRAMA SOLO APLICA PARA LA VERSION 2012
******************************************************************
Parameters pNombreFormato,pOrigen,pTipoDcto,pDocumentoInicial,pDocumentoFinal,pTipoSalida,pCodigoConsecutivo,pCopias

Formato=pNombreFormato
Store 1 To copiaActual
Public pNit,mNitResponsableRQ,mCodigoMonedaLocal,mCalculoValUn, mCalculoValUnNif

Public mTotalEfectivo,mTotalTarjetas ,mTotalCambio,LineasTot,mNroResol,mConsecIni,mConsecFin
PUBLIC mFileQR,mDatosCodigoQR,mgNitQR,mNitQR,mNetoQR,mMeuuid,a,mValIpoconsumoBebidas,mIpconsubeb,mIPsalud,mIPazucar


*** Nueva variable para el calculo del Impuesto de licores ADVALOREM
PUBLIC mValorADEM 
STORE 0 TO mIPsalud,mIPazucar
Store "" To pNit,mCodigoMonedaLocal
*copiaActual=pCopias

   
mCodigoMonedaLocal=oGenerica.Extraer_Variables(gConexEmp,gEmpresa,'CODMONEDALOCAL',gCodUsuario)
mCalculoValUnNif=oGenerica.Extraer_Variables(gConexEmp,gEmpresa,'CALCULOVALUNID',gCodUsuario)
mServicioAdvalorem=oGenerica.Extraer_Variables(gConexEmp,gEmpresa,'ADVALOREM',gCodUsuario)

Do Opcion With "CrearTablaTmpLogo With pNombreFormato"



*!*	mStrSQLx = " Select NroResol  " + ;
*!*		"		From Consecut "  + ;
*!*		"		Where Origen =?pOrigen And  "  + ;
*!*		"			  TipoDcto=?pTipoDcto And  "  + ;
*!*		"			  Codigocons=?pCodigoConsecutivo  "
*!*	If SQLExec(gConexEmp,mStrSQLx,"curResol")<=0
*!*		oGenerica.Mensajes("No es posible seleccionar los datos de la Resolución")
*!*		Return 0
*!*	Endif
*!*	Select curResol
*!*	Go Top

*!*	If !Eof()
*!*		mNroResol = Alltrim(curResol.NroResol)
*!*	Else
*!*		mNroResol = " "
*!*	Endif


mStrSQLx = " Select TIPODCTO,TIPODCTOFR,NroResol, ConsecIni, ConsecFin, " + ;
	"		Case When fhautoriz <> '19000101' Then	" + ;
	"			Cast(Year(fhautoriz) as Char(4)) + '-' + " + ;
	"			Case When Len(Month(fhautoriz)) = 1 Then '0' + Cast(Month(fhautoriz) as Char(1)) " + ;
	"				Else Cast(Month(fhautoriz) as Char(2)) End + '-' + " + ;
	"			Case When Len(Day(fhautoriz)) = 1 Then '0' + Cast(Day(fhautoriz) as Char(1)) " + ;
	"				Else Cast(Day(fhautoriz) as Char(2)) End " + ;
	"		Else '' End as FhAutoriz, "+;
	" Case When FvenReso <> '19000101' Then	"+;
	"			Cast(Year(FvenReso) as Char(4)) + '-' + "+;
	"			Case When Len(Month(FvenReso)) = 1 Then '0' + Cast(Month(FvenReso) as Char(1)) "+;
	"				Else Cast(Month(FvenReso) as Char(2)) End + '-' + "+;
	"			Case When Len(Day(FvenReso)) = 1 Then '0' + Cast(Day(FvenReso) as Char(1)) "+;
	"				Else Cast(Day(FvenReso) as Char(2)) End "+;
	"		Else '' End as FvenReso,  PrefijDIAN "+;
	"		From Consecut " + ;
	"		Where CodigoCons = ?pCodigoConsecutivo "

If SQLExec(gConexEmp,mStrSQLx,"curResol")<=0
	oGenerica.Mensajes("No es posible seleccionar los datos de la Resolución")
	Return 0
Endif


Select curResol
Go Top

If !Eof()
	mNroResol = Alltrim(curResol.NroResol)
	mfhautoriz= curResol.FhAutoriz
	mConsecIni = Str(curResol.ConsecIni)
	mConsecFin = Str(curResol.ConsecFin)
	mFvenReso=curResol.FvenReso
	mPrefijDian = ALLTRIM(curResol.PrefijDIAN )

Else
	mNroResol = " "
	mfhautoriz= " "
	mConsecIni = "0"
	mConsecFin = "0"
	mFvenReso=" "
	mPrefijDian = ""	
Endif

mTipoDct = pTipoDcto
********************************************************************


If Vartype(pDocumentoInicial)="C"
	mNroDocumentoIni  = Val(pDocumentoInicial)
	mNroDocumentoFin  = Val(pDocumentoFinal)
Else
	mNroDocumentoIni  = pDocumentoInicial
	mNroDocumentoFin  = pDocumentoFinal
Endif


pDocumentoInicial = mNroDocumentoIni
pDocumentoFinal   = mNroDocumentoFin

documentoMostrar = Alltrim(Str(pDocumentoInicial))



******************************************************************

Do While pDocumentoInicial <= pDocumentoFinal
	documentoMostrar = Alltrim(Str(pDocumentoInicial))

	***--------------------------------------------------------------------------------
	***/// P7132 - William Villada - Febrero DE 2012 - Se crea la siguiente consulta para verificar el tipo de documento correcto con
	***///        el cual se graban los documentos. Esta consulta se hace especialmente para los casos de las facturas remisionadas
	***///        las cuales cambian de tipo de documento. Esta consulta trae el tipo de documento con el cual se deben realizar las
	***///        demas consultas.

	If Used("cFacRem")
		Select cFacRem
		Use
	Endif


	***--------------------------------------------------------------------------------
	***/// P7367 - Johana Sepulveda - Abril 2012 - Se crea la siguiente consulta para verificar el tipo de documento correcto con
	***///        el cual se graban los documentos. Esta consulta se hace especialmente para los casos de las facturas remisionadas
	***///        las cuales cambian de tipo de documento. Esta consulta trae el tipo de documento con el cual se deben realizar las
	***///        demas consultas.

	***/// Esta variable toma el codigo del consecutivo que viene desde la pantalla FrmImprimirFormatoComercial
	***/// el cursor cConsecut se crea en ese formulario.
	*pCodigoConsecutivo=cConsecut.CodigoCons

	mStrSql="  Select distinct Trade.TipoDcto "+;
		"	From Trade Inner join Consecut "+;
		"		on Consecut.Origen = Trade.Origen and Consecut.TipodctoFR = Trade.TipoDcto "+;
		"			And Consecut.codigocons=?pCodigoConsecutivo and Consecut.Tipodcto=?mTipoDct "+;
		"			and Trade.NroDcto= ?documentoMostrar  and Trade.origen = 'COM' "

	If SQLExec(gConexEmp,mStrSql,"cFacRem")<=0
		oGenerica.Mensajes("No es posible seleccionar la tabla de consecutivos")
		Return 0
	Endif

	Select cFacRem
	Go Top
	If !Eof()
		pTipoDcto = cFacRem.TipoDcto
	Else
		pTipoDcto = mTipoDct
	Endif

	If gPais ="MX"
		mStrSQl_MEUUID=" SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADE' AND	COLUMN_NAME ='MEUUID' "
		If SQLExec(gConexEmp,mStrSQl_MEUUID,"cMEUUID") <=0
			oGenerica.Mensajes("No se realizo la consulta de SQL para extraer el campo MEUUID de TRADE")
			Return 0
		Endif

		Select cMEUUID
		Go Top
		If !Eof()
			mStrSql=" Select MEUUID,MECADORIG,MECANCELA,MEFALLO,MEFECHAT,MENOCERSAT,MESELLOCFD,MESELLOSAT,MEVERSION From Trade "+;
				" Where Origen=?pOrigen and Tipodcto=?pTipoDcto and Nrodcto=?documentoMostrar "
			If SQLExec(gConexEmp,mStrSql,"cListaCertificados") <=0
				oGenerica.Mensajes("No se realizo la consulta de SQL para extraer el campo MEUUID de TRADE")
				Return 0
			Endif
		Else
			mStrSql=" Select ' ' as MEUUID,' ' as MECADORIG,' ' as MECANCELA,' ' as MEFALLO,' ' as MEFECHAT,' ' as MENOCERSAT,' ' as MESELLOCFD,' ' as MESELLOSAT,' ' as MEVERSION From Trade "+;
				" Where Origen=?pOrigen and Tipodcto=?pTipoDcto and Nrodcto=?documentoMostrar "
			If SQLExec(gConexEmp,mStrSql,"cListaCertificados") <=0
				oGenerica.Mensajes("No se realizo la consulta de SQL para extraer el campo MEUUID de TRADE")
				Return 0
			Endif

		Endif
		Select cListaCertificados
		mMeuuid=Alltrim(cListaCertificados.Meuuid)

	Endif
	***--------------------------------------------------------------------------------



	mStrSql = " Select V.*,M.Nombre As NombrePais ,T.Nombre As NombreMoneda ,P.Emailp As Emailp, 							"+;
		" [dbo].[F_MonedaForm](?pOrigen,?pTipoDcto,?documentoMostrar) as Moneda,								"+;
		"[dbo].[F_Extraer_Variable]('CALLE',?gCodusuario,?gPais) As Titulo1, "+;
		" [dbo].[F_Extraer_Variable]('NROEXTERIOR',?gCodusuario,?gPais) As Titulo2, "+;
		" [dbo].[F_Extraer_Variable]('NROINTERIOR',?gCodusuario,?gPais) As Titulo3, "+;
		" [dbo].[F_Extraer_Variable]('COLONIA',?gCodusuario,?gPais) As Titulo4, "+;
		" [dbo].[F_Extraer_Variable]('CP',?gCodusuario,?gPais) As Titulo5, "+;
		" [dbo].[F_Extraer_Variable]('LOCALIDAD',?gCodusuario,?gPais) As Titulo6, "+;
		" [dbo].[F_Extraer_Variable]('CIUDAD',?gCodusuario,?gPais) As Titulo7, "+;
		" [dbo].[F_Extraer_Variable]('ESTADOMX',?gCodusuario,?gPais) As Titulo8, "+;
		" [dbo].[F_Extraer_Variable]('CABELN4',?gCodusuario,?gPais) As Titulo9, "+;
		" [dbo].[F_Extraer_Variable]('NUMAUTDONAT',?gCodusuario,?gPais) As NoAutDonat, "+;
		" [dbo].[F_Extraer_Variable]('FECAUTDONAT',?gCodusuario,?gPais) As FechaAutDonat, "+;
		" [dbo].[F_MonedaConceptosForm](?pOrigen,?pTipoDcto,?documentoMostrar,'BRUTO') as VALBRUTO,				"+;
		" [dbo].[F_MonedaConceptosForm](?pOrigen,?pTipoDcto,?documentoMostrar,'DESCUENTO') as VALDESCUENTO,		"+;
		" [dbo].[F_MonedaConceptosForm](?pOrigen,?pTipoDcto,?documentoMostrar,'IVA') as VALIVA ,				"+;
		" [dbo].[F_MonedaConceptosForm](?pOrigen,?pTipoDcto,?documentoMostrar,'RETEFUENTE') as VALRETEFUENTE ,	"+;
		" [dbo].[F_MonedaConceptosForm](?pOrigen,?pTipoDcto,?documentoMostrar,'IPOCONSUMO') as VALIPOCONSUMO ,	"+;
		" [dbo].[F_MonedaConceptosForm](?pOrigen,?pTipoDcto,?documentoMostrar,'RETEIVA') as VALRETEIVA ,		"+;
		" [dbo].[F_MonedaConceptosForm](?pOrigen,?pTipoDcto,?documentoMostrar,'RETEICA') as VALRETEICA ,		"+;
		" [dbo].[F_MonedaConceptosForm](?pOrigen,?pTipoDcto,?documentoMostrar,'RETCREE') as VALRETCREE ,		"+;
		" [dbo].[F_MonedaConceptosForm](?pOrigen,?pTipoDcto,?documentoMostrar,'NETO') as VALNETO,				"+;
		" (Cast(Year(v.Fecha) as Char(4)) + '-' + 																"+;
		" Case When Len(Month(v.Fecha)) = 1 Then '0' + Cast(Month(v.Fecha) as Char(1)) 							"+;
		" Else Cast(Month(v.Fecha) as Char(2)) End + '-' + 														"+;
		" Case When Len(Day(v.Fecha)) = 1 Then '0' + Cast(Day(v.Fecha) as Char(1))								"+;
		" Else Cast(Day(v.Fecha) as CHAR(2)) End + 'T' + v.Hora) as fechacerti, 								"+;
		" (Cast(Year(v.Fecha) as Char(4)) + '-' + 																"+;
		" Case When Len(Month(v.Fecha)) = 1 Then '0' + Cast(Month(v.Fecha) as Char(1)) 							"+;
		" Else Cast(Month(v.Fecha) as Char(2)) End + '-' + 														"+;
		" Case When Len(Day(v.Fecha)) = 1 Then '0' + Cast(Day(v.Fecha) as Char(1))								"+;
		" Else Cast(Day(v.Fecha) as CHAR(2)) End + 'T' + v.Hora) as fechaefechat, 								"+;
		"  (V.Impuestos/(case when V.tcambio = 0 then 1 else V.tcambio end)) as Impuesto,						"+;
		" P.CiudadPrv                                                                                           "+;
		"	From vComerCom V,Mtpaises M ,Mtmoneda T ,MtProcli P                 								"+;
		"	Where 																								"+;
		"	V.Nit   =  P.Nit And 																				"+;
		"	V.codmoneda = T.Codmoneda And 																		"+;
		"	P.Pais = M.Codigo  And																				"+;
		"   V.Origen = ?pOrigen And  																			"+;
		"	V.NroDcto=?documentoMostrar and 																	"+;
		"	V.TipoDcto=?pTipoDcto	"

	********************************************************************
	***VERSION:  ESTE PROGRAMA SOLO APLICA PARA LA VERSION 2012
	******************************************************************
	If SQLExec(gConexEmp,mStrSql,"curEncabezado")<=0
		oGenerica.Mensajes("No es posible seleccionar los datos del encabezado")
		Return 0
	Endif
	Select curEncabezado
	Go Top
	

	mNitResponsableRQ=curEncabezado.Nitresp

	If !Empty(curEncabezado.Nit)
		pNit=curEncabezado.Nit
	Else
		pNit=curEncabezado.Nitresp
	Endif



	If gPais ="MX"
		**********************************************************
		* Imprimir la informacion de la factura timbrada
		**********************************************************
		mStrSql = 	" select MECADORIG,MEFECHAT, "+;
			"		substring(MESELLOCFD,0,125) + ' ' + substring(MESELLOCFD,125,125)  as MESELLOCFD, "+;
			"		substring(MESELLOSAT,0,150) + ' ' + substring(MESELLOSAT,150,100)  as MESELLOSAT,MEUUID, MEXML "+;
			" From trade "  + ;
			" Where Origen =?pOrigen And  "  + ;
			" TipoDcto=?pTipoDcto And  "  + ;
			" NroDcto=?documentoMostrar  "

		If SQLExec(gConexEmp,mStrSql,"CurMedElect")<=0
			oGenerica.Mensajes("No es posible seleccionar los datos del timbrado de facturación electrónica")
			Return 0
		Endif
		Select CurMedElect
	Endif


	***---------------------------------------------------------------------
	***///-- Enero 2012 - La funcion F_MonedaMVForm selecciona la informacion por el tipo de moneda con la cual se grabó el documento.

*!*		mStrSql = " Select  M.* ,U.UNidad As CodUnidad,U.Nombre As NombreUnidad,[dbo].[F_MonedaMVForm](?pOrigen,?pTipoDcto,?documentoMostrar,M.idmvtrade) as ValorUnitario  " + ;
*!*			"		From MVTrade M,MtUnidad U "  + ;
*!*			"		Where Origen =?pOrigen And  "  + ;
*!*			"			  NroDcto=?documentoMostrar And M.UndVenta = U.Unidad  and M.TipoDcto=?pTipoDcto "

mStrSql = " Select  M.* ,U.UNidad As CodUnidad,U.Nombre As NombreUnidad,M.ValorUnit as ValorUnitario, MtMercia.Iva as IvaMer  " + ;
		"		From MVTrade M inner join MtUnidad U on  M.UndVenta = U.Unidad "  + ;
		"  			Inner Join MtMercia on MtMercia.Codigo = M.Producto "  + ;
		"		Where Origen =?pOrigen And  "  + ;
		"			  NroDcto=?documentoMostrar And M.TipoDcto=?pTipoDcto "


	If SQLExec(gConexEmp,mStrSql,"curMvto")<=0
		oGenerica.Mensajes("No es posible seleccionar los datos del movimiento")
		Return 0
	Endif


	Select curMvto
	Go Top

	
	IF mServicioAdvalorem <> ''
		Sum All ValorUnit To mValorADEM FOR Producto = mServicioAdvalorem 
	ELSE
		mValorADEM  = 0
	ENDIF
	DELETE ALL FOR producto=mServicioAdvalorem
	GO top 
	**Impuestos Saludables
	SUM ALL IPazucar * Cantidad TO mIPazucar
	SUM ALL (ValorUnit*Cantidad)*(IPsalud/100) TO mIPsalud
	**

	Select curEncabezado


	Do Case

		Case curEncabezado.Otramon = "N" And curEncabezado.Multimon = .F.   && Pesos
			mPalabra = numero(Abs(curEncabezado.valBruto - curEncabezado.valDescuento +curEncabezado.valIva + curEncabezado.VALIPOCONSUMO +  curEncabezado.IMPCIGARRI -  (curEncabezado.Valretefuente + curEncabezado.Valreteiva + curEncabezado.Valreteica)),Upper(curEncabezado.Moneda))
			*mPalabra = numero(Abs((CurEncabezado.valbruto+CurEncabezado.valiva-Curencabezado.valdescuento)-(CurEncabezado.valretefuente+CurEncabezado.valretcree+CurEncabezado.valreteiva+CurEncabezado.valreteica)))
		Case curEncabezado.Otramon = "S" And curEncabezado.Multimon  = .F. && Dolar - Otramoneda
			mPalabra = numero(Abs(curEncabezado.valBruto - curEncabezado.valDescuento +curEncabezado.valIva + curEncabezado.VALIPOCONSUMO +  curEncabezado.IMPCIGARRI - (curEncabezado.Valretefuente + curEncabezado.Valreteiva + curEncabezado.Valreteica)),Upper(curEncabezado.Moneda))

		Case curEncabezado.Otramon = "N" And curEncabezado.Multimon = .T.  && Multimoneda
			mPalabra = numero(Abs(curEncabezado.valBruto - curEncabezado.valDescuento+curEncabezado.valIva + curEncabezado.VALIPOCONSUMO +  curEncabezado.IMPCIGARRI - (curEncabezado.Valretefuente + curEncabezado.Valreteiva + curEncabezado.Valreteica)),Upper(curEncabezado.Moneda))

		Otherwise
			mPalabra = numero(Abs(curEncabezado.valBruto - curEncabezado.valDescuento +curEncabezado.valIva + curEncabezado.VALIPOCONSUMO +  curEncabezado.IMPCIGARRI - (curEncabezado.Valretefuente + curEncabezado.Valreteiva + curEncabezado.Valreteica)),Upper(curEncabezado.Moneda))

	Endcase


	Select curMvto
	Go Top

	***---------------------------------------------------------------------
	********************************************************************

	******************************************************************
	If curEncabezado.D1Fecha1 > 0

		Do Case
			Case curEncabezado.Otramon = "N" And curEncabezado.Multimon = .F.   && Pesos
				mValorDesc1 = (curEncabezado.Bruto - curEncabezado.Descuento)-((curEncabezado.Bruto - curEncabezado.Descuento) * (curEncabezado.D1Fecha1/100))
			Case curEncabezado.Otramon = "S" And curEncabezado.Multimon = .F. && Dolar - Otramoneda
				mValorDesc1 = (curEncabezado.XBruto - curEncabezado.XDescuento)-((curEncabezado.XBruto - curEncabezado.XDescuento) * (curEncabezado.D1Fecha1/100))
			Case curEncabezado.Otramon = "N" And curEncabezado.Multimon = .T.&& Multimoneda
				mValorDesc1 = (curEncabezado.ZBruto - curEncabezado.ZDescuento)-((curEncabezado.ZBruto - curEncabezado.ZDescuento) * (curEncabezado.D1Fecha1/100))
		Endcase

		mTextDesc1 = "Descuento por pronto pago "
		mTextDesc2 = "% cuyo valor es $:"
		mTextDesc3 = "Pague solo $ "
		mTextDesc4 = "Antes del "


	Else && Si no tiene descuento financiero
		mValorDesc1 = 0
		mTextDesc1 = ""
		mTextDesc2 = ""
		mTextDesc3 = ""
		mTextDesc4 = ""
	Endif


	mCodciudad=curEncabezado.CdCiiu
	mStrSql = " Select Nomciud From  MTCDDAN Where Codigo = ?mCodciudad "
	If SQLExec(gConexEmp,mStrSql,"curSucursales2")<=0
		Do errconex With " No se realizo la consulta para determinar las sucursales"
	Endif
	mNombreCiudad =curSucursales2.Nomciud


	****/// Validacion del codigo IVA. Si el movimiento tiene varios se deja vacio
	Select curMvto
	Go Top
	mlineas=Reccount()
	mIvaMvto=curMvto.IVA


	For A=1 To mlineas
		If curMvto.IVA <> mIvaMvto
			mIvaMvto= 0
			Exit
		ENDIF
		IF !EOF()
			SKIP
		endif
	Endfor

	***///
	*--******************************************************************--
	*--JAVIER OSPINA
	*--IMPUESTOS ADICIONALES 7070-7072
	*--AIU P6927
	*--12/ABRIL/2012
	*--Descripcion:
	*--Pivot dinamicos para imprimir los valores de impuestos
	*--Para los formatos de impresion se deja esta consulta
	*--en el programa imprimirformato de facturas para que arme
	*--el query dinamicamente dependiendo de los impuestos que se tengan
	*--configurados en el maestro de impuestos.
	*--******************************************************************--

	*--los parametros tipo de documento, # de dcto y origen son la base
	*--para la consulta dinamica ya que con estos datos se consulta en mvtrade
	*--los id de los impuestos asociados a la factura y poder construir el pivot
	*--dinamico de los impuestos con su porcentaje y el valor que le corresponde
	*--para esa factura.

	If gImpuestosComp=.T.

		mStrSql1 = " Declare @TipoDcto Char (20)  			"+;
			"	Declare @NroDcto Char (20)   					"+;
			"	Declare @Origen Char (20)   					"+;
			"	Declare @Sql varchar(MAX) 						"+;
			"	Declare @sql2 varchar(max)  					"+;
			"	Declare @Consulta_Iva2 Char (1000)    			"+;
			"	Declare @Consulta_Base2 Char (1000)   			"+;
			"	Declare @Porc_Iva2 Char (1000)   				"+;
			"	Declare @Base2 Char (1000)   					"+;
			"	Declare @Consulta_Iva Char (1000)  				"+;
			"	Declare @Consulta_Base Char (1000)  			"+;
			"	Declare @Porc_Iva Char (1000)   				"+;
			"	Declare @Base Char (1000)   					"+;
			"	Declare @Total_Iva Char (1000)   				"+;
			"	Declare @Total_Base Char (1000)   				"+;
			"	select @Total_Base=coalesce(Rtrim(@Total_Base)+', sum([Porcen_'+Rtrim(impuestos.CODIGO)+'])As [Porcen_','sum([Porcen_'+Rtrim(impuestos.CODIGO)+'])As [Porcen_')+ Rtrim(impuestos.CODIGO)+']'  	"+;
			"	From (	 	 															"+;
			"		  select Distinct convert(Char(5),CODIGO)As CODIGO  from Mtimpu   	"+;
			"		 ) impuestos   														"+;
			"			Order by CODIGO   												"+;
			"	select @Total_Iva=coalesce(Rtrim(@Total_Iva)+', sum([Valor_'+Rtrim(impuestos.CODIGO)+'])As [Valor_','sum([Valor_'+Rtrim(impuestos.CODIGO)+'])As [Valor_')+ Rtrim(impuestos.CODIGO)+']'   		"+;
			"	From ( 	 				 												"+;
			"		   select Distinct convert(Char(5),CODIGO)As CODIGO  from Mtimpu   	"+;
			"		 ) impuestos   														"+;
			"			Order by CODIGO   												"+;
			"	select @Consulta_Base=coalesce(Rtrim(@Consulta_Base)+', isnull(['+Rtrim(impuestos.CODIGO)+'],0)As [Porcen_','isnull(['+Rtrim(impuestos.CODIGO)+'],0)As [Porcen_')+ Rtrim(impuestos.CODIGO)+']'  "+;
			"	From (   																"+;
			"		 select Distinct convert(Char(5),CODIGO)As CODIGO  from Mtimpu   	"+;
			"		) impuestos   														"+;
			"		Order by CODIGO   													"+;
			"	select @Consulta_Iva=coalesce(Rtrim(@Consulta_Iva)+', isnull([-'+Rtrim(impuestos.CODIGO)+'],0)As [Valor_','isnull([-'+Rtrim(impuestos.CODIGO)+'],0)As [Valor_')+ Rtrim(impuestos.CODIGO) +']'  	"+;
			"	From (   																"+;
			"		 select Distinct convert(Char(5),CODIGO)As CODIGO  from Mtimpu 		"+;
			"		) impuestos   														"+;
			"		Order by CODIGO  													"+;
			"	select @Base=coalesce(Rtrim(@Base)+', ['+Rtrim(impuestos.CODIGO)+']','['+Rtrim(impuestos.CODIGO)+']')   			"+;
			"	From (   																											"+;
			"		 select Distinct convert(Char(5),CODIGO)As CODIGO  from Mtimpu   												"+;
			"		) impuestos   																									"+;
			"		Order by CODIGO   																								"+;
			"	select @Porc_Iva=coalesce(Rtrim(@Porc_Iva)+', [-'+Rtrim(impuestos.CODIGO)+']','[-'+Rtrim(impuestos.CODIGO)+']')   	"+;
			"	From (   																											"+;
			"		 select Distinct convert(Char(5),CODIGO)As CODIGO  from Mtimpu  												"+;
			"		) impuestos   																									"+;
			"		Order by CODIGO   																								"+;
			"	select @Consulta_Base2=coalesce(Rtrim(@Consulta_Base2)+', isnull([-'+Rtrim(impuestos.CODIGO)+'],0)As [Porcen_','isnull([-'+Rtrim(impuestos.CODIGO)+'],0)As [Porcen_')+ Rtrim(impuestos.CODIGO)+']'    "+;
			"	From (   																											"+;
			"	select Distinct convert(Char(5),CODIGO)As CODIGO  from Mtimpu   													"+;
			"		) impuestos   																									"+;
			"		Order by CODIGO 	 																							"+;
			"	select @Consulta_Iva2=coalesce(Rtrim(@Consulta_Iva2)+', isnull(['+Rtrim(impuestos.CODIGO)+'],0)As [Valor_','isnull(['+Rtrim(impuestos.CODIGO)+'],0)As [Valor_')+ Rtrim(impuestos.CODIGO) +']'  			"+;
			"	From (   																											"+;
			"		 select Distinct convert(Char(5),CODIGO)As CODIGO  from Mtimpu    												"+;
			"		) impuestos   																									"+;
			"		Order by CODIGO   																								"+;
			"	select @Base2=coalesce(Rtrim(@Base2)+', [-'+Rtrim(impuestos.CODIGO)+']','[-'+Rtrim(impuestos.CODIGO)+']')   		"+;
			"	From (																												"+;
			"		 select Distinct convert(Char(5),CODIGO)As CODIGO  from Mtimpu      											"+;
			"		) impuestos     																								"+;
			"		Order by CODIGO   																								"+;
			"	select @Porc_Iva2=coalesce(Rtrim(@Porc_Iva2)+', ['+Rtrim(impuestos.CODIGO)+']','['+Rtrim(impuestos.CODIGO)+']')     "+;
			"	From (     																											"+;
			"		 select Distinct convert(Char(5),CODIGO)As CODIGO  from Mtimpu    												"+;
			"		) impuestos     																								"+;
			"		Order by CODIGO  																								"


		mStrSQL2="	Set @TipoDcto = ?pTipoDcto															"+;
			"	Set @NroDcto = ?documentoMostrar 															"+;
			"	Set @Origen = ?pOrigen  																	"+;
			"	set @Sql =  'select '+rTrim(@Total_Base)+', '+rTrim(@Total_Iva)+' 	 						"+;
			"			From(    																			"+;
			"					SELECT   '+Rtrim(@Consulta_Base)+', '+ rTrim(@Consulta_Iva)+' 	 			"+;
			"					FROM(    																	"+;
			"					select codigoimp,   														"+;
			"					mvtradeimpu.porcentaje,  													"+;
			"						sum(case when 	mvtradeimpu.resta=1 then 								"+;
			"						(((mvtrade.Cantidad*mvtrade.ValorUnit)-  (mvtrade.Cantidad*mvtrade.ValorUnit)*(mvtrade.descuento/100) ) *(mvtradeimpu.porcentaje/100*-1))	"+;
			"						else    																																	"+;
			"						(((mvtrade.Cantidad*mvtrade.ValorUnit)-  (mvtrade.Cantidad*mvtrade.ValorUnit)*(mvtrade.descuento/100) ) *(mvtradeimpu.porcentaje/100))	 	"+;
			"					end) as total   															"+;
			"					from MVTRADE 																"+;
			"					inner join mvtradeimpu on mvtrade.idimpuesto=mvtradeimpu.idmvtrade 			"+;
			"					and mvtrade.origen='''+rTrim(@Origen)+'''   								"+;
			"					AND mvtrade.tipodcto='''+rTrim(@TipoDcto)+'''  								"+;
			"					AND mvtrade.nrodcto='''+rTrim(@NroDcto)+'''  								"+;
			"					group by codigoimp,baseiva,  												"+;
			"					mvtradeimpu.porcentaje  													"+;
			"					) As Tabla1 PIVOT    														"+;
			"					(sum(porcentaje)    														"+;
			"					FOR tabla1.codigoimp IN ('+rTrim(@Base)+', '+rTrim(@Porc_Iva)+')  			"+;
			"					) AS PivotTabla   															"+;
			"				UNION  '  																		"+;
			"		set @sql2 =	'SELECT  '+Rtrim(@Consulta_Base2)+', '+ rTrim(@Consulta_Iva2)+' 			"+;
			"					FROM(    																	"+;
			"					select codigoimp,   														"+;
			"					mvtradeimpu.porcentaje,   													"+;
			"						sum(case when 	mvtradeimpu.resta=1 then 								"+;
			"						(((mvtrade.Cantidad*mvtrade.ValorUnit)-  (mvtrade.Cantidad*mvtrade.ValorUnit)*(mvtrade.descuento/100) ) *(mvtradeimpu.porcentaje/100*-1))	"+;
			"						else    																																	"+;
			"						(((mvtrade.Cantidad*mvtrade.ValorUnit)-  (mvtrade.Cantidad*mvtrade.ValorUnit)*(mvtrade.descuento/100) ) *(mvtradeimpu.porcentaje/100)) 		"+;
			"						end) as total   														"+;
			"					from MVTRADE   																"+;
			"					inner join mvtradeimpu on mvtrade.idimpuesto=mvtradeimpu.idmvtrade  		"+;
			"					and mvtrade.origen='''+rTrim(@Origen)+'''    								"+;
			"				    AND mvtrade.tipodcto='''+rTrim(@TipoDcto)+'''    							"+;
			"				    AND mvtrade.nrodcto='''+rTrim(@NroDcto)+'''    								"+;
			"					group by codigoimp,baseiva,   												"+;
			"					mvtradeimpu.porcentaje   													"+;
			"					) As Tabla1 PIVOT (sum(TOTAL)   											"+;
			"					FOR tabla1.codigoimp IN ('+rTrim(@Base2)+', '+rTrim(@Porc_Iva2)+')   		"+;
			"					) AS TablaValorImpuestos    												"+;
			"					) TotalValorImpuestos '    													"+;
			"	exec (@Sql+@sql2)																			"


		mStrSql=mStrSql1+mStrSQL2

		If SQLExec(gConexEmp,mStrSql,"CurImpu")<=0
			oGenerica.Mensajes("No es posible seleccionar los datos de los impuestos")
			Return 0
		Endif
		Select CurImpu

	Endif

	********************************************************************
	*IMPRIMIR SERIES
	* Crear cursor de series que se maneja en el formato de series
	* El formato de series es específico y se llama "AnexoSeries.frx"
	******************************************************************

	* Validar si se selecciono Imprimir series en la captura de series
	If gImprimirSerie

		* Se forma el filtro del origen de series segun el origen del documento
		Do Case
				* Si es Factura o puntoVenta
			Case pOrigen  = "FAC"
				mFiltroOrigen   = " and S.origen in('DEVVE','VENTA') "

				* Si es Compra
			Case pOrigen  = "COM"
				mFiltroOrigen   = " and S.origen in('DEVCO','COMPRA') "

				* Si es Inventario, incluye traslados
			Case pOrigen  = "INV"
				mFiltroOrigen   = " and S.origen in('ENTRADA','SALIDA') "

		Endcase

		* Query para extraer la información de series
		* Se filtra para los que son COMPRA o DEVOLUCION DE COMPRA que son los asociados al modulo
		mStrSql = 	" Select S.codigo, M.Descripcio, S.serie, S.garantia, " + ;
			"		S.existe, S.origen, S.nrodcto, S.tipodcto, S.bodega, S.codcc, S.ordennro, S.tercero,S.codubica, S.procli " + ;
			"	From mtseries S inner join mtMercia M on S.codigo = M.Codigo " + ;
			"	Where S.NRODCTO = ?documentoMostrar and S.tipoDcto = ?pTipoDcto " +  mFiltroOrigen

		If SQLExec(gConexEmp,mStrSql,"curSeries")<=0
			oGenerica.Mensajes("No es posible seleccionar los datos de las series.")
			Return 0
		Endif

		* Usar variable para identificar el tipo de Documento, se usa para mostrar el titulo del formato
		Public gDocumentoOrigen

		Do Case
				* Si es Factura
			Case cConsecut.DctoMae = "FA"
				gDocumentoOrigen = "FACTURA DE COMPRA"

				* Si es Remisión
			Case cConsecut.DctoMae = "RE"
				gDocumentoOrigen = "REMISIÓN"

				* Si es Nota Crédito
			Case cConsecut.DctoMae = "NC"
				gDocumentoOrigen = "NOTA CRÉDITO"
		Endcase

	Endif

	* Llenar nombre del formato de anexo de series
	mFormatoSeries = "AnexoSeries.frx"

	* Verificar que se haya encotrado informacion de series para imprimir y que el formato exista
	* Se usa variable mImprimeSerie  para definir si se imprime o no el formato
	If Used("curSeries")
		Select curSeries
		Go Top

		If File(mFormatoSeries) And Reccount() > 0
			mImprimeSerie = .T.
		Else
			mImprimeSerie = .F.
		Endif

		Select curSeries
		Go Top
	Else
		mImprimeSerie = .F.
	Endif


	**************************************************************************************************
	********************************************************************
	***VERSION:  ESTE PROGRAMA SOLO APLICA PARA LA VERSION 2012
	******************************************************************
	Select curMvto
	Go Top
	LineasTot = Reccount()
	LineasFal = 19 - LineasTot
	For I = 1 To LineasFal
		Append Blank
		*replace nombre WITH "      "
	Next
	Select curEncabezado
	Go Top
	Select curMvto
	Go Top
	DELETE ALL FOR producto=""
	GO top

	* Parametros
	* 	1. pNombreFormato: Nombre del reporte con formato FRX
	*	2. pOrigen : Origen puede ser FAC,INV, COM , CAR, CXP
	*	3. pTipoDcto : Tipo de documento
	*	4. pDocumentoInicial : Documento inicial
	*	5. pDocumentoFinal : Documento Final
	* 	6. pTipoSalida Salida por
	* 			1. Impresora
	*			2. Pantalla
	*			3. PDF - Email

	* Realizar ciclo para imprimir un Rango

	********************************************************************
	***VERSION:  ESTE PROGRAMA SOLO APLICA PARA LA VERSION 2012
	******************************************************************

	Do Case
			* Si es por impresora
		Case pTipoSalida = 1
			For I=1 To pCopias&& Manejo de Copias

				copiaActual=I

				Report Format &pNombreFormato To Printer Noconsole

				* Validar si imprime anexo de series
				If mImprimeSerie
					* Configurar el cursor de series
					Select curSeries
					Go Top
					Report Format &mFormatoSeries To Printer Noconsole
				Endif
			Next
			* Si es por pantalla
		Case pTipoSalida = 2
			Report Format &pNombreFormato Preview

			* Validar si imprime anexo de series
			If mImprimeSerie
				* Configurar el cursor de series
				Select curSeries
				Go Top
				Report Format &mFormatoSeries Preview
			Endif

			* Si es por PDF -email
		Case pTipoSalida = 3

*!*				For I=1 To pCopias && Manejo de Copias
*!*					copiaActual=I

*!*					Do ActivarImpresoraPDF
*!*					Report Format &pNombreFormato To Printer Noconsole

*!*					* Validar si imprime anexo de series
*!*					If mImprimeSerie
*!*						* Configurar el cursor de series
*!*						Select curSeries
*!*						Go Top
*!*						Do ActivarImpresoraPDF
*!*						Report Format &mFormatoSeries To Printer Noconsole
*!*					Endif
*!*				Next

				For i=1 To pCopias
					copiaActual=i
					*GenerateFile(mDatosCodigoQR,mFileQR)

					***NOM - PTE  11925 - versión 2015 - Nombre del PDF y XML se manejan diferente y necesitan ser iguales
					***Jesús Marino Gómez Muñoz
					***30/11/2015
*!*						If gPais ="MX" OR  (gPais="CO" AND mHABILITAFACTURACIONE =.T.)

*!*							mArchivoXML = CrearArchivoXML(CurMedElect.MEXML,documentoMostrar,pTipoDcto)
*!*							**NOM - PTE  11925 - versión 2015 - Nombre del PDF y XML se manejan diferente y necesitan ser iguales
*!*							**Jesús Marino Gómez Muñoz
*!*							**13/10/2015
*!*							** Se haya el nombre utilizado para el  XML y se asigna al nombre del PDF
*!*							mPosCadena=Atcc("\",mArchivoXML,Occurs("\",mArchivoXML))
*!*							If CurMedElect.MEXML<>"" Then

*!*	*!*								mNombrePDFenvio=Substr(Upper(mArchivoXML),mPosCadena+1,Len(mArchivoXML)-(mPosCadena)-3)+"PDF"
*!*							Else
*!*								mNombrePDFenvio="FAC_"+pTipoDcto+"_"+documentoMostrar+".PDF"
*!*	*!*							Endif

*!*							* Modificado para enviar XML adicional al PDF en Nomina Electronica
*!*							mArchivoPDF = CrearArchivoPDF(pNombreFormato,.F.,.F.,mNombrePDFenvio,mNombrePDFenvio,oPDFListener)

*!*						Else
						mNombrePDFenvio=ALLTRIM(pNit)+"_"+pTipoDcto+documentoMostrar+".PDF"
						Do CrearArchivoPDF With pNombreFormato,.T.,.F.,mNombrePDFenvio,mNombrePDFenvio,.F.

*!*						Endif


					* Validar si imprime anexo de series
					If mImprimeSerie
						* Configurar el cursor de series
						Select curSeries
						Go Top
						Do CrearArchivoPDF With mFormatoSeries,.T.
					Endif
				Next

		Case pTipoSalida = 4

			* Parametros : 1. Nombre del Formato
			*			   2. .F. Indica que no se muestra por pantalla el PDF

			*mArchivoPDF = CrearArchivoPDF(pNombreFormato,.F.)
			mNombrePDFenvio=ALLTRIM(pNit)+"_"+pTipoDcto+documentoMostrar+".PDF"
			mArchivoPDF = CrearArchivoPDF(pNombreFormato,.F.,.F.,mNombrePDFenvio,mNombrePDFenvio,.F.)

			If Not Empty(mArchivoPDF)
				mEmailDestino = ObtenerEmail(pNit)
				getOtherEmails(pNit)
				*mEmailDestino = ObtenerEmail(curEncabezado.Nit)
				*mEmailDestino="ofima@ofima.com"

				If Not Empty(mEmailDestino)
					mAsunto = "Reporte Factura Cliente " + Alltrim(curEncabezado.CliNombre)
					mDetalleCuerpo = "Se anexa formato de factura "
					Do EnviaEmailReporte With mEmailDestino,mAsunto,mDetalleCuerpo,mArchivoPDF
					sendEmailToAditionalEmails(pNit, mAsunto, mDetalleCuerpo, mArchivoPDF)

					* Enviar E-mail de series
					* Validar si imprime anexo de series
					If mImprimeSerie
						* Configurar el cursor de series
						Select curSeries
						Go Top
						mArchivoPDFSeries = CrearArchivoPDF(mFormatoSeries,.F.)
						If Not Empty(mArchivoPDFSeries)
							mAsunto = "Reporte Anexo de series Cliente " + Alltrim(curEncabezado.CliNombre)
							mDetalleCuerpo = "Se anexa formato de Anexo de series "
							Do EnviaEmailReporte With mEmailDestino,mAsunto,mDetalleCuerpo,mArchivoPDFSeries
							sendEmailToAditionalEmails(pNit, mAsunto, mDetalleCuerpo, mArchivoPDF)
						Endif
					Endif
				Else
					Messagebox("El proveedor no tiene eMail configurado, no es posible enviar el correo al proveedor.",64,"Validar")
				Endif
			Else
				Messagebox("El archivo PDF se encuentra vacio",64,"Validar")
			Endif

	Endcase



	Select curMvto
	Select curEncabezado

	* Si usa el cursor de series cerrarlo
	If Used("curSeries")
		Select curSeries
		Use
	Endif


	pDocumentoInicial = pDocumentoInicial + 1
	documentoMostrar = pDocumentoInicial
	loop

Enddo


Function ObtenerEmail
	Parameters pNit


	mEmailEnviar = ""

	**************************************************************************************
	*Pendiente nro : 13083
	*Modificado por: Anderson Ramirez
	*Fecha : 10/05/2016
	*Funcion : valida el tipo de documento maestro para enviar correo y se cambia la consulta
	*para consultar dependiendo de donde se encutre el responsable de la requision
	*Tambien se comenta las lienas de codigo en donde obtiene el documento maestro
	*ya que lo obtiene de manera incorrecta

	*!*		mStrSql1="select dctomae from tipodcto where dctomae=?pTipoDcto"
	*!*		If SQLExec(gConexEmp,mStrSql1,'cLista')<=0
	*!*			oGenerica.Mensajes("No se ejecuto la conexión a la tabla TipoDcto")
	*!*		Endif
	*!*		Select cLista
	*!*		Go Top
	*!*		If !Eof()
	*!*			mEsRQ=cLista.DctoMae
	*!*		Else
	*!*			mEsRQ=""
	*!*		Endif

	mEsRQ = oGenerica.Extraer_dcto_maestro('COM',pTipoDcto)


	*If mEsRQ = ""
	If mEsRQ <> "RQ"

		mStrSql = " Select Mtprocli.Nit As Nit,Mtprocli.Emailp As emailp,' ' as EMAILP2 "+;
			" From Mtprocli Where Mtprocli.ESPROVEE='S' And Mtprocli.Nit=?pNit "
		*Almacena Nit del cliente
		mNitaux = pNit
	Else

		*!*	   		mstrsql =   " Select Mtnitres.Nitasigna As Nit,Mtnitres.Email As emailp "+;
		*!*	              " From  Mtnitres Where Mtnitres.Nitasigna=?mNitResponsableRQ "

		*!*			mStrSql=" SELECT Mtnitres.Nitasigna AS Nit "+;
		*!*				",Mtnitres.Email AS emailp "+;
		*!*				",MTPROCLI.EMAILP AS EMAILP2 "+;
		*!*				" FROM Mtnitres "+;
		*!*				" INNER JOIN MTPROCLI ON MTPROCLI.NIT = MTNITRES.NITASIGNA "+;
		*!*				" WHERE Mtnitres.Nitasigna =?mNitResponsableRQ "

		mStrSql=" If Exists(Select Mtnitres.Nitasigna From Mtnitres Where Mtnitres.Nitasigna = ?mNitResponsableRQ )		 "+;
			"         select Mtnitres.Nitasigna AS Nit ,Mtnitres.Email AS emailp,                                  		 "+;
			"         Isnull((Select Mtprocli.Emailp From Mtprocli where Nit = ?mNitResponsableRQ),' ') AS emailp2 		 "+;
			"           From Mtnitres where Mtnitres.Nitasigna = ?mNitResponsableRQ 									 "+;
			"      Else 																								 "+;
			" 		  Select Mtprocli.Nit AS Nit ,                                                                 		 "+;
			"         Isnull((Select Mtnitres.Email From Mtnitres where Nitasigna = ?mNitResponsableRQ),' ') AS emailp,  "+;
			" 		  Mtprocli.EMAILP AS emailp2                                                                         "+;
			" 	   		From Mtprocli where Mtprocli.Nit = ?mNitResponsableRQ                                            "

		*Almacena Nit del responsable
		mNitaux = mNitResponsableRQ
	Endif

	*Fin pendinete Nro : 13083
	***************************************************************************************

	If SQLExec(gConexEmp,mStrSql,"curDatos")<=0
		oGenerica.Mensajes("No es posible seleccionar los datos de email")
		Return ""
	Endif
	Select curDatos
	Go Top

	If mEsRQ <> "" And (Empty(curDatos.EMAILP) And curDatos.emailp2 <> "")
		mEmailEnviar =curDatos.emailp2
	Endif


	If mEsRQ <> "" And (!Empty(curDatos.EMAILP) And curDatos.emailp2="")
		mEmailEnviar =curDatos.EMAILP
	Endif

	If mEsRQ <> "" And (!Empty(curDatos.EMAILP) And curDatos.emailp2<>"")
		mEmailEnviar =curDatos.EMAILP
	Endif

	If mEsRQ <> "" And (Empty(curDatos.EMAILP) And curDatos.emailp2="")
		mEmailEnviar =""
	Endif


	If Empty(mEmailEnviar)
		mEmailEnviar = Inputbox("El Nit/Responsable: "+ Alltrim(mNitaux) +" no tiene correo asociado. Ingrese un correo para continuar ","Verificar Nit ")
	Endif


	Return mEmailEnviar
	
*---------------------------------------------------

FUNCTION sendEmailToAditionalEmails(pNit, mAsunto, mDetalleCuerpo, mArchivoPDF)

LOCAL lcEmails

lcSqlQuery = "SELECT XEMAIL1, XEMAIL2, XEMAIL3 FROM MTPROCLI WHERE NIT = '" + TRANSFORM(pNit) + "'"

IF SQLEXEC(gConexEmp, lcSqlQuery, "lcEmails") <= 0
		oGenerica.Mensajes("No se pudo obtener los datos de email adicionales para el NIT " + ALLTRIM(TRANSFORM(pNit)))
	RETURN ""
ENDIF

Do EnviaEmailReporte With lcEmails.XEMAIL1,mAsunto,mDetalleCuerpo,mArchivoPDF
Do EnviaEmailReporte With lcEmails.XEMAIL2,mAsunto,mDetalleCuerpo,mArchivoPDF
Do EnviaEmailReporte With lcEmails.XEMAIL3,mAsunto,mDetalleCuerpo,mArchivoPDF

ENDFUNC



							
							
	
	
