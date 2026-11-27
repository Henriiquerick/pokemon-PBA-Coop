## Versão do Mod: Alpha v0.0.1
# Pokémon Battle Advanced — Co-op Comunidade Alpha 1

Primeira edição para um grupo pequeno testar. Base Windows **0.6.2a**, Godot 4.7.1. Conexão por IP direto; não usa o matchmaking oficial. Os dois PCs precisam instalar esta mesma alpha.

## Instalar sem Python

1. Extraia o ZIP. Mantenha juntos os arquivos da pasta `coop_community`.
2. Feche o jogo anterior. Execute **Instalar.bat**. Se a exportação original não estiver perto do patch, uma janela pedirá a pasta que contém `PokemonBattleAdvanced.exe`, o PCK e as DLLs originais.
3. Aguarde a verificação e a criação de `PBA-Coop-Comunidade-Alpha1`, dentro da pasta original. Abra essa pasta e execute **Jogar-Coop.bat**.

São usados PowerShell e .NET já presentes no Windows. Não é preciso instalar Python, GDRETools ou o editor Godot. O patch não inclui o jogo completo. O instalador recusa uma build desconhecida, um PCK LAN como entrada e uma pasta de destino já existente.

Para escolher caminhos explicitamente, no PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\coop_community\Instalar.ps1 -Origem "C:\Jogos\PBA-original" -Destino "C:\Jogos\PBA-Coop-Comunidade-Alpha1" -MigrarDe "C:\Jogos\PBA-Coop-Battle-Fix"
```

Use uma pasta gravável, como Downloads. Não instale por cima de uma versão anterior. Cada PC migra seus próprios saves; não copie o perfil de um jogador para o outro.
## Como instalar:
1 - Baixar o winrar em 'Releases' dê preferencia para a última versão disponível

2- Extraia o arquivo na pasta com o jogo e seus componentes. Ex:
discord_game.sdk.dll
PokemonBattleAdvanced.exe
PokemonBattleAdvanced.exe

3- Abrir a pasta 'coop_comunity' após extrai-lá

4- Dentro da pasta 'coop_comunity' Executar o arquivo 'instalar.bat'. Este arquivo vai gerar uma outra pasta, chamada 'PBA-Coop-Comunidade-Alpha1'

5- Abra a pasta gerada depois execute o arquivo 'Jogar-Coop.bat'.

6- Garanta que você e seu amigo tenham RadminVPN para garantir a conexão via Lan, caso não tenham, é só realizar o download.

7- Dentro do jogo, já na interface do PBA Coop, o host vai escolher a opção 'Hospedar', não é necessário colocar o IP ainda.

8- O seu amigo deverá copiar o seu IP e Porta, que utiliza o padrão '24620'e então clicar em 'Entrar / Continuar como Guest'

9- Divirta-se, e reporte feedbacks para termos a melhoria do mod!

### Lembrando, este mod está em modelo experimental, recomendamos que não utilize seu save padrão, ou, que faça um Backup do mesmo para não perder seu progresso como solo player.

## Começar a jogar

No menu de **Jogar-Coop.bat**, um jogador escolhe hospedar; o outro informa o IP do anfitrião mostrado pelo Radmin VPN e escolhe entrar. Ambos precisam ter um Pokémon saudável para conectar. A porta padrão é **UDP 24620**. Se o Windows pedir autorização de rede para o jogo, permita na rede usada pelo Radmin.

Também há atalhos diretos. Dentro da pasta instalada:

```powershell
# PC anfitrião
.\Hospedar.bat

# PC convidado: substitua o número pelo IP real do anfitrião
.\Entrar.bat -IP xx.xxx.xx.xx
```

Para continuar o mesmo progresso sem conexão, use **Jogar-Sozinho.bat** ou “Continuar campanha localmente” no menu. Abrir o EXE diretamente entra no fluxo solo original, que possui um save separado.

Na primeira abertura sem perfil migrado, o launcher copia o `save.json` pessoal encontrado para o diretório isolado. O campo de caminho no menu permite importar outro save. A opção mais simples para começar do zero é obter o primeiro Pokémon e salvar no jogo original antes de importar. O fluxo “Nova campanha cooperativa” também foi mantido, mas o percurso completo do prólogo ainda depende de validação manual nesta alpha.

O perfil padrão fica em `userdata\coop\Godot\app_userdata\Pokémon Battle Advanced\coop_s3\profile.json`, com checksum e `.bak`. O autosave grava em pontos seguros. **F5** salva fora de luta, diálogo, evolução e outros fluxos ocupados. A abertura do mapa, do espectador e de uma troca também tenta salvar antes de bloquear os controles. Ao fechar durante uma luta, permanece o último checkpoint seguro.

## O que está integrado

- Exploração com presença do parceiro, Pokémon soltos, picnic e clima, herdada da versão validada pelos jogadores.
- Treinadores já integrados da Route 2 e ginásio de Brock em dupla, com reservas, foco, HP autoritativo e resultado individual. O convidado também pode solicitar encontros suportados quando ambos estão disponíveis no mesmo mapa carregado.
- Recompensas e flags nativas desses encontros. Vitórias antigas registradas de Brock, sem os prêmios, são reparadas ao abrir o perfil. Isso não transfere progresso para o save solo separado do EXE.
- Trocas entre amigos pela sessão e interface nativas do Cable Club, com recibos e recuperação. **F6** ou “Trocar LAN”, próximos e fora de fluxos ocupados. Haunter evolui por troca; golpes permanecem em inglês.

**Todas as batalhas do Rival permanecem singleplayer**, inclusive a da Route 22. Não foi acrescentada uma exceção para a Elite dos Quatro. Treinadores e ginásios fora da lista integrada, assim como as revanches/VS Seeker, seguem o fluxo solo. Esta alpha não transforma a campanha inteira em co-op.

## Mapa direto — F7

**F7**, o botão “Mapa” ou **Select/Back do controle no mundo** abre o mapa de Kanto, sem exigir o item Town Map.

- O marcador ciano identifica a região do parceiro.
- No mesmo mapa, o texto informa distância e deslocamento para leste/norte em metros, complementando o marcador/seta do minimapa.
- Em outro mapa, mostra a região/local informado pelo parceiro. Interiores são agrupados na cidade quando reconhecidos.
- É uma consulta: esse atalho não oferece viagem rápida, teleporte ou novos desbloqueios.

Use F7 ou o comando de voltar exibido para fechar. O ponto no mapa de Kanto é regional; não representa uma planta detalhada de cada rota/interior. Se a região não tiver correspondência no mapa, o nome ainda aparece no texto, sem inventar um marcador.

## Assistir à luta do parceiro — F8

Quando seu parceiro estiver numa batalha solo e você estiver livre, aparece “Assistir”. **F8** abre uma arena de visualização separada, com sprites do jogo, posições, HP e último golpe informado. Não controla a luta, não recebe dano, captura ou recompensas e não move seu personagem até o mapa do outro jogador.

F8, Esc ou o botão “Voltar” sai da observação. Ela fecha automaticamente quando a luta termina, a conexão cai ou o fluxo local muda. Nesta primeira versão, o cenário é neutro: não reproduz o mapa original, clima, áudio e todos os efeitos de golpes. A atualização visual de observação é de aproximadamente 10 Hz, com interpolação de posição. A simulação continua no PC de quem está enfrentando a batalha solo.

## Selvagens especiais em dupla e captura individual

Quando os dois jogadores estão livres, conectados e na mesma região/mapa, estes encontros fixos viram **dois Pokémon da mesma espécie e nível**, enfrentados pelos dois jogadores:

| Encontro | Local | Nível original |
|---|---|---|
| Raticate | Route 1 | 11 |
| Primeape | Route 22 | 15 |
| Pidgeotto | Route 2 | 15 |
| Nidorino | Pallet Woods | 15 |
| Butterfree | Viridian Forest | 15 |
| Beedrill | Viridian Forest | 15 |

Os demais selvagens continuam no formato original. Lendários, resgates e encontros de história não foram generalizados. Em dupla, os seis encontros acima usam somente os dois adversários principais; os adds menores de alguns encontros da floresta não são convocados. Em solo, as regras originais permanecem.

Para capturar:

1. Enfraqueça o Pokémon, sem derrotá-lo.
2. Use o **foco/mira original** para escolher qual adversário quer capturar — normalmente Tab/clique do analógico, conforme seus controles.
3. Pressione **F9**, clique em “Capturar alvo” ou use **Select/Back do controle durante esse encontro**. É usada a bola selecionada no jogo; se ela acabou, o seletor nativo procura outra bola disponível.
4. Uma captura é processada por vez. Aguarde terminar antes de lançar a próxima bola. Falhar não gasta sua cota de captura bem-sucedida.

O host calcula a chance pela rotina nativa, desconta a bola de quem lançou e aplica **uma captura bem-sucedida por jogador, por encontro**. O parceiro pode capturar o outro Pokémon. Quem já capturou pode ajudar a derrotar o restante, mas não capturar o segundo. Equipe cheia envia o recebido ao PC; se ambos estiverem lotados, o arremesso é recusado.

**As capturas são confirmadas no save ao vencer o encontro.** Derrota, aborto ou desconexão desfazem capturas e gastos de bolas desse encontro e mantêm o checkpoint, em vez de tentar uma transferência parcial. Ao vencer, os dois recebem a flag do encontro fixo, impedindo repeti-lo ao passar perto. Pokémon capturados não entram no cálculo de XP dos adversários derrotados. Não existe item de teste ou Master Ball gratuita na campanha; bolas garantidas aparecem somente nas fixtures automáticas de desenvolvimento.

O host mostra a animação de captura nativa. O guest recebe o estado e os avisos autoritativos; a reprodução completa dessa animação na outra tela ainda é uma limitação visual da alpha.

## PT-BR parcial

O catálogo cobre os diálogos principais iniciais de Oak/laboratório, encomenda/Pokédex, Rival inicial/Route 22, bloqueio após Brock e ginásio de Pewter, além de elementos comuns de menus, cabeçalhos, HUD e controles. Há variações de caixa/quebra de linha para os textos da build. Não é uma tradução integral da campanha nem dos NPCs secundários.

Nomes dos golpes permanecem em inglês. Não são alterados IDs de golpes, nomes de espécies, flags de missão ou conteúdo dos saves. O código e o catálogo estão em `src/pt_br.gd`, `src/pt_br.json` e `construir_traducao.py`.

## Teste e feedback

1. Confiram os próprios times/itens após importar e após fechar/reabrir. Continuem uma vez em solo pelo atalho correto.
2. Na Route 2/Brock, testem ataques, mira, troca manual, reservas e fim de batalha nos dois lados. Confirmem dinheiro/insígnia/TM uma única vez.
3. Abram F7 no mesmo mapa e em regiões diferentes. Sigam o marcador ciano e confiram distância/direção.
4. Um enfrenta um selvagem ou Rival em solo; o outro usa F8 e depois volta ao mapa.
5. Enfrentem Raticate/Primeape juntos. Cada um captura um alvo diferente com F9/Select. Tentem capturar um segundo com o mesmo jogador. Vençam, fechem e reabram os perfis.
6. Testem o gamepad físico: mover, atacar, foco, reservas, mapa e captura. Não deve controlar o Pokémon do outro PC.
7. Façam uma troca comum e, depois, uma por evolução. Em troca pendente após queda, reabram os mesmos perfis com o mesmo parceiro; preservem `trade_pending.json` e os backups.

Após fechar o jogo, execute **Coletar-Logs.bat**. Ele cria `feedback-DATA-HORA.zip` com logs e versão, sem incluir os saves. Envie o ZIP manualmente e descreva: versão, host/guest, mapa, ação, resultado esperado/observado e horário aproximado. Informe FPS/latência e se usava teclado ou controle. Imagens/vídeos ajudam nos problemas visuais.

## Reverter

Feche a alpha e volte à pasta anterior: ela não foi modificada. Progresso feito na alpha não retorna automaticamente à versão anterior.

Para restaurar apenas o PCK da nova instalação, execute **Restaurar.bat** com o jogo fechado. O backup é validado e conserva Thunder Stone/Haunter por troca. Depois abra o EXE diretamente; o launcher co-op recusa um PCK restaurado. `userdata` e os backups permanecem preservados.
