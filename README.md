# Módulo NFS-e Nacional (Harbour / xHarbour) - Versão Avançada

Biblioteca e conjunto de utilitários em **Linguagem Harbour** para integração corporativa completa com a **NFS-e Nacional** (Padrão Sped / Sefin Nacional). Esta versão expandida cobre todo o ciclo de vida do documento fiscal: geração de DPS, assinatura digital avançada RSA-SHA256 (XMLDSig) - Não utiliza CAPICOM.DLL, transmissão via REST API com mTLS, gerenciamento de eventos fiscais, validação prévia de schemas e geração local de DANFSe em PDF.

---

## 🚀 Funcionalidades Expandidas

* **Geração Avançada de XML da DPS**: Montagem estruturada da tag `<DPS>` com suporte a múltiplos itens de serviço, retenções de tributos federais (PIS, COFINS, INSS, IRRF, CSLL) e deduções legais.
* **Assinatura Digital XMLDSig (RSA-SHA256)**: Implementação nativa de Canonicalização (C14N) e assinatura utilizando a CryptoAPI do Windows (`ncrypt.dll` / `crypt32.dll`), com suporte completo a arquivos `.pfx` com senha e certificados instalados no repositório do Windows.
* **Comunicação REST com mTLS e Compressão**: Envio via HTTPS com autenticação mútua baseada em certificado digital, suporte a payload compactado via GZip e codificação Base64.
* **Gestão de Eventos Fiscais**:
  * Emissão de eventos de cancelamento de NFS-e (Código de Evento `101101`).
  * Consulta e rastreamento de eventos vinculados à chave de acesso.
* **Consultas e Recuperação de Dados**:
  * Consulta de NFS-e por Chave de Acesso.
  * Consulta de Status de Processamento de Lote / DPS por ID.
  * Download automatizado do XML da NFS-e autorizada.
* **Validação de Schema XSD**: Validação prévia da estrutura da DPS antes da transmissão, evitando rejeições desnecessárias na Sefin.
* **Impressão Local de DANFSe (PDF)**:
  * Gerador de DANFSe em PDF otimizado via **HaruPDF** (`harupdf`) e **hbzebra** (geração nativa de códigos de barras Code 128 e QR Code fiscal).
  * Totalmente independente de serviços externos ou páginas governamentais instáveis.

---

## 📁 Estrutura Detalhada do Projeto

| Arquivo | Descrição |
| :--- | :--- |
| `demo_emissao.prg` | Exemplo completo e orquestrado: configuração, montagem, validação, assinatura, envio, consulta e impressão. |
| `nfse_config.prg` | Classe `TNfseConfig` para gestão de ambientes (Produção / Homologação) e certificados digitais. |
| `nfse_dps_gera.prg` | Módulo gerador da estrutura XML da DPS com tributos federais e municipais. |
| `nfse_assina.prg` | Assinador XMLDSig RSA-SHA256 com rotinas de C14N embarcadas (`#pragma BEGINDUMP`). |
| `nfse_envio.prg` | Camada de transmissão HTTP/REST, tratamento de headers e requisições seguras. |
| `nfse_consulta.prg` | Funções para consulta por chave, ID de DPS e verificação de eventos. |
| `nfse_eventos.prg` | Módulo dedicado a eventos fiscais (Cancelamento e Substituição). |
| `nfse_validacao.prg` | Validador de XML contra os schemas XSD oficiais da NFS-e Nacional. |
| `dps_danfe_pdf.prg` | Renderizador local do DANFSe em PDF utilizando `harupdf` e `hbzebra`. |

---

## 💻 Exemplo de Uso Completo

```harbour
#include "nfse_nacional.ch"

PROCEDURE Main()
   LOCAL oConfig, hDps, hRetorno

   // 1. Configuração do Ambiente e Certificado PFX
   oConfig := TNfseConfig():New()
   oConfig:SetAmbiente( NFSE_AMBIENTE_HOMOLOGACAO ) // Homologação
   oConfig:SetCertificadoPfx( "C:\certificados\empresa_digital.pfx", "123456" )

   // 2. Preenchimento estruturado dos dados da DPS
   hDps := hb_Hash()
   hb_HSet( hDps, "nTpAmb",             NFSE_AMBIENTE_HOMOLOG )
   hb_HSet( hDps, "cCnpjPrestador",     "14239311000199" )
   hb_HSet( hDps, "cRazaoPrestador",    "Minha Empresa de Software LTDA" )
   hb_HSet( hDps, "cCodMunPrestacao",   "3550308" ) // São Paulo / SP
   hb_HSet( hDps, "nOpSimplesNacional", 3 )       // Regime de Tributação

   // Dados do Tomador
   hb_HSet( hDps, "cCnpjCpfTomador",    "99967805000199" )
   hb_HSet( hDps, "cRazaoTomador",      "Cliente Homologação S/A" )
   hb_HSet( hDps, "cEmailTomador",      "financeiro@clienteteste.com" )

   // Detalhes do Serviço e Valores
   hb_HSet( hDps, "cTribNac",           "010401" ) // Código de Tributação Nacional
   hb_HSet( hDps, "cDescricaoServico",  "Desenvolvimento e licenciamento de software customizado." )
   hb_HSet( hDps, "nValorServico",      1500.00 )
   hb_HSet( hDps, "nAliquota",          2.00 )
   hb_HSet( hDps, "nValorIss",          30.00 )
   
   // Retenções Federais (Opcional)
   hb_HSet( hDps, "nValorPis",          0.00 )
   hb_HSet( hDps, "nValorCofins",       0.00 )

   hb_HSet( hDps, "cSerie",             "00001" )
   hb_HSet( hDps, "nNumeroDps",         125 )
   hb_HSet( hDps, "dCompetencia",       Date() )

   // 3. Validação prévia de Schema XSD
   IF !NfseValidaSchema( hDps )
      ? "Erro de Validação XSD:", NfseGetUltimoErro()
      RETURN
   ENDIF

   // 4. Emissão Síncrona com Assinatura e Envio
   IF NfseEmiteNFSe( oConfig, hDps, @hRetorno )
      ? "========================================"
      ? " NFS-e AUTORIZADA COM SUCESSO!"
      ? "========================================"
      ? "Chave de Acesso:", hb_HGet( hRetorno, "chaveAcesso" )
      ? "Número da NFS-e:", hb_HGet( hRetorno, "numeroNfse" )
      ? "Protocolo     :", hb_HGet( hRetorno, "protocolo" )
      
      // 5. Gera o DANFSe em PDF localmente com QR Code
      DpsDanfePdf( hDps, hb_HGet( hRetorno, "chaveAcesso" ), hRetorno, "DANFSE_" + hb_HGet( hRetorno, "numeroNfse" ) + ".pdf" )
      
   ELSE
      ? "========================================"
      ? " FALHA NA EMISSÃO DA NFS-E"
      ? "========================================"
      ? "HTTP Status :", hb_HGet( hRetorno, "httpStatus" )
      ? "Código Erro :", hb_HGet( hRetorno, "codigoErro" )
      ? "Mensagem    :", hb_HGet( hRetorno, "mensagem" )
   ENDIF
RETURN

```

<div align="center">

<b>Marcelo A. L. Carli</b><br>
Malc Informática — Gestão em Saúde Ocupacional<br>
📍 Marília/SP — Capital Nacional do Alimento ®<br>
🌐 <a href="https://malc-informatica.ueniweb.com" target="_blank">malc-informatica.ueniweb.com</a><br>
📧 <a href="mailto:marceloalcarli@gmail.com">marceloalcarli@gmail.com</a><br>
📱 Instagram: <a href="https://instagram.com/malcarli25" target="_blank">@malcarli25</a>

</div>
