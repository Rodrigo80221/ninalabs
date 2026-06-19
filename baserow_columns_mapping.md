# Mapeamento de Colunas (Tabela 812614 - Posts)

Este documento contém o mapeamento completo das colunas (campos) da tabela de posts no Baserow (Database 234291 / Table 812614), contendo o nome da coluna, o ID (código) usado internamente pela API e o tipo de dado do campo.

| Código (ID) | Nome da Coluna | Tipo de Dado |
| :--- | :--- | :--- |
| **6963661** | DataHora | date |
| **6963716** | DiretorConteudo | long_text |
| **6963717** | Gestor | long_text |
| **6964775** | PrecisaNarrador | boolean |
| **6964777** | PrecisaMusicaDeFundo | boolean |
| **6964781** | TipoParaCriacaoDeImagens | text |
| **6964823** | ImagemDeAbertura | file |
| **6964993** | PossuiAtorNaImagemDeCapa | boolean |
| **6966274** | ImagensRestantes | file |
| **6966480** | ImagemDeReferencia | text |
| **6969404** | VideoMaker | long_text |
| **6970011** | VideoEditado | file |
| **6975660** | BackgroundMusic | file |
| **6975756** | DuracaoDoVideo | number |
| **6975911** | Narracao | long_text |
| **6975912** | AudioNarracao | file |
| **6993999** | EstrategistaDeConteudo | long_text |
| **7004890** | ArquivoLegenda | long_text |
| **7006491** | VideoComAudio | file |
| **7007172** | VideoComLegendaPT | file |
| **7012244** | DescricaoPost | long_text |
| **7028349** | idPostagemInstagram | number |
| **7037640** | ArquivoLegendaIngles | long_text |
| **7133863** | ArquivoLegendaOriginal | long_text |
| **7403505** | SecretariaJoyce | long_text |
| **7441568** | html2image | long_text |
| **8298716** | idInstagram | link_row |
| **8298718** | idConteudo | link_row |
| **8445020** | Status | text |
| **9017794** | idEmpresa | link_row |


### Dica de uso da API
Quando utilizar a API do Baserow com o parâmetro `?user_field_names=true`, as chaves do JSON virão exatamente como estão na coluna **Nome da Coluna** (ex: `json['ImagemDeAbertura']`). Caso utilize a API sem esse parâmetro, as chaves virão como `field_CODIGO` (exemplo: `json['field_6964823']` para a imagem de abertura).
