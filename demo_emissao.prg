/*
DEMO_EMISSAO.PRG - Harness manual: emite uma NFS-e em homologacao e, se
quiser, cancela em seguida. Pipeline tecnico (certificado/mTLS/assinatura
RSA-SHA256/gzip/JSON/schema) ja validado ponta-a-ponta no projeto irmao
C:\nota\dps_nacional. O que normalmente falta ajustar e o codigo de
tributacao nacional (DEMO_CTRIB_NAC) - precisa ser administrado pelo
municipio informado na data de competencia; confirme na tabela oficial.
*/

#include "nfse_nacional.ch"
#include "hbhash.ch"

#define DEMO_PFX_FILE      "D:\dps_nacional\tests\ENZZA COMERCIO LTDA_10229311000180_Senha_12345678.pfx"
#define DEMO_PFX_PASSWORD  "12345678"

#define DEMO_CNPJ_PRESTADOR    "14239311000199"
#define DEMO_IM_PRESTADOR      "99925999"
#define DEMO_EMAIL_PRESTADOR   "marceloalcarli@gmail.com"
#define DEMO_RAZAO_PRESTADOR   "Malc Gestão em Saude Ocupacional"
#define DEMO_COD_MUN           "3550308" // codigo IBGE - Sao Paulo/SP

// Endereco conforme cartao CNPJ
#define DEMO_CEP_PRESTADOR       "05801050"
#define DEMO_LOGR_PRESTADOR      "R DO SOSSEGO"
#define DEMO_NUMERO_PRESTADOR    "123"
#define DEMO_BAIRRO_PRESTADOR    "JARDIM MIRANTE"

#define DEMO_CNPJ_TOMADOR      "99967805000199"
#define DEMO_IM_TOMADOR        "2139678"
#define DEMO_RAZAO_TOMADOR     "TINTAS PIG LTDA"
#define DEMO_COD_MUN_TOMADOR   "3550308"
#define DEMO_CEP_TOMADOR       "04806000"
#define DEMO_LOGR_TOMADOR      "RUA DO SOSSEGO"
#define DEMO_NUMERO_TOMADOR    "SN"
#define DEMO_BAIRRO_TOMADOR    "CIDADE DUTRA"

#define DEMO_CTRIB_NAC         "010401" // Elaboracao de programas de computadores (bate com CNAE 6201-5-01)
#define DEMO_CTRIB_MUN         "001"     // teste: valor generico usado por municipios sem subclassificacao propria
#define DEMO_DESCRICAO_SERV    "Desenvolvimento de programas de computador sob encomenda"
#define DEMO_VALOR_SERVICO     100.00
#define DEMO_ALIQUOTA          2.00

/* Depois de emitir com sucesso, defina a chave aqui e rode NfseCancelaNFSe()
   (ver comentado no fim do Main) para testar o cancelamento. */
#define DEMO_CHAVE_PARA_CANCELAR ""

PROCEDURE Main()
   LOCAL oConfig, hDps, hRetorno

   IF Empty( DEMO_PFX_FILE )
      ? "Configure DEMO_PFX_FILE / DEMO_PFX_PASSWORD e os demais dados de teste no topo deste arquivo antes de rodar."
      wait
      RETURN
   ENDIF

   oConfig := TNfseConfig():New()
   oConfig:UseProducaoRestrita()
   oConfig:SetCertificadoPfx( DEMO_PFX_FILE, DEMO_PFX_PASSWORD )

   hDps := hb_Hash()
   hb_HSet( hDps, "nTpAmb",            NFSE_AMBIENTE_HOMOLOG )
   hb_HSet( hDps, "cCnpjPrestador",    DEMO_CNPJ_PRESTADOR )
   hb_HSet( hDps, "cEmailPrestador",   DEMO_EMAIL_PRESTADOR )
   hb_HSet( hDps, "cRazaoPrestador",   DEMO_RAZAO_PRESTADOR )
   hb_HSet( hDps, "cCodMunPrestacao",  DEMO_COD_MUN )
   hb_HSet( hDps, "nOpSimplesNacional", 3 ) // 1=Nao optante 2=MEI 3=ME/EPP
   hb_HSet( hDps, "cCodMunEndPrestador", DEMO_COD_MUN )
   hb_HSet( hDps, "cCepPrestador",      DEMO_CEP_PRESTADOR )
   hb_HSet( hDps, "cLogradouroPrestador", DEMO_LOGR_PRESTADOR )
   hb_HSet( hDps, "cNumeroPrestador",   DEMO_NUMERO_PRESTADOR )
   hb_HSet( hDps, "cBairroPrestador",   DEMO_BAIRRO_PRESTADOR )

   hb_HSet( hDps, "cCnpjCpfTomador",   DEMO_CNPJ_TOMADOR )
   hb_HSet( hDps, "cImTomador",        DEMO_IM_TOMADOR )
   hb_HSet( hDps, "cRazaoTomador",     DEMO_RAZAO_TOMADOR )
   hb_HSet( hDps, "cCodMunEndTomador", DEMO_COD_MUN_TOMADOR )
   hb_HSet( hDps, "cCepTomador",       DEMO_CEP_TOMADOR )
   hb_HSet( hDps, "cLogradouroTomador", DEMO_LOGR_TOMADOR )
   hb_HSet( hDps, "cNumeroTomador",    DEMO_NUMERO_TOMADOR )
   hb_HSet( hDps, "cBairroTomador",    DEMO_BAIRRO_TOMADOR )

   hb_HSet( hDps, "cTribNac",          DEMO_CTRIB_NAC )
   hb_HSet( hDps, "cTribMun",          DEMO_CTRIB_MUN )
   hb_HSet( hDps, "cDescricaoServico", DEMO_DESCRICAO_SERV )
   hb_HSet( hDps, "nValorServico",     DEMO_VALOR_SERVICO )
   hb_HSet( hDps, "nAliquota",         DEMO_ALIQUOTA )
   hb_HSet( hDps, "cSerie",            "00001" )
   hb_HSet( hDps, "nNumeroDps",        1 )
   hb_HSet( hDps, "dCompetencia",      Date() )

   ? "Emitindo NFS-e em homologacao..."
   ? "XML enviado:"
   ? NfseDpsGeraXml( hDps )
   ? ""
   hb_memowrit([xml_enviado.xml], NfseDpsGeraXml( hDps ))
   wait

   IF NfseEmiteNFSe( oConfig, hDps, @hRetorno )
      ? "OK - chaveAcesso:", hb_HGet( hRetorno, "chaveAcesso" )
      ? "idDps:", hb_HGet( hRetorno, "idDps" )
      ? "NFS-e XML:"
      ? hb_HGet( hRetorno, "nfseXml" )
      hb_memowrit([xml_retornto.xml], hb_HGet( hRetorno, "nfseXml" ))
   ELSE
      ? "FALHA - httpStatus:", hb_HGet( hRetorno, "httpStatus" )
      ? "erro:", hb_HGet( hRetorno, "erro" )
   ENDIF

   IF ! Empty( DEMO_CHAVE_PARA_CANCELAR )
      ? ""
      ? "Cancelando NFS-e", DEMO_CHAVE_PARA_CANCELAR, "..."
      IF NfseCancelaNFSe( oConfig, DEMO_CHAVE_PARA_CANCELAR, DEMO_CNPJ_PRESTADOR, ;
            1, "Nota emitida em teste de homologacao", @hRetorno )
         ? "OK - evento registrado. idPedidoRegistro:", hb_HGet( hRetorno, "idPedidoRegistro" )
      ELSE
         ? "FALHA - httpStatus:", hb_HGet( hRetorno, "httpStatus" )
         ? "erro:", hb_HGet( hRetorno, "erro" )
      ENDIF
   ENDIF
   wait
RETURN
