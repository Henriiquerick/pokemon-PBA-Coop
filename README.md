# S3 Fix — Pokémon soltos, minimapa, clima e XP

## Atualizar preservando o perfil

Feche os jogos S3 nos dois PCs. Extraia `PBA-Coop-S03-Fix-patch.zip` na pasta original 0.6.2a e execute:

```powershell
python .\coop_s03_fix\instalar_campanha.py --migrar-de ".\PBA-Coop-S03"
```

O instalador cria `PBA-Coop-S03-Fix` e copia os perfis da pasta S3 indicada, incluindo backups, sem modificar os arquivos anteriores. Se S3 estiver em outro local, indique o caminho completo em `--migrar-de`. Por padrão ele também procura `PBA-Coop-S03` ao lado do jogo original. Não importe novamente o save solo se quiser continuar o progresso cooperativo: use a migração. Não copie o perfil de um jogador para o outro.

Abra **`PBA-Coop-S03-Fix\COOPERATIVO.bat`** nos dois computadores. Hospede e entre pelo IP Radmin como antes. Ambos precisam desta versão. O instalador recusa migrar um perfil aberto pelo lançador ou substituir um destino já existente.

## O que mudou e como testar

1. **Pokémon soltos:** solte dois ou três Pokémon no mapa. O parceiro deve ver todos os que estão fora da Poké Bola na mesma área, até o limite do time. Recolha um e confirme que só a réplica correspondente desaparece. Repita no outro PC. As réplicas são visuais; não são Pokémon adicionados ao time do parceiro.
2. **Minimapa:** fica disponível ao ar livre em todos os saves desta instalação, inclusive solo, sem exigir Town Map. O inventário não recebe item extra. O ponto ciano indica o parceiro; se estiver fora do alcance do mapa, uma seta ciana aponta sua direção. Há também texto com área/distância. Em outra cena, o texto informa o outro mapa; interiores continuam sem o desenho de terreno do minimapa original. Desconectar deve remover o marcador.
3. **Chuva:** fiquem próximos no mesmo mapa quando chover. O guest deve manter a chuva entre atualizações, sem ligar apenas por alguns frames. Depois atravessem um portão e voltem. O host coordena as células climáticas; lugares distantes podem legitimamente ter chuva diferente e interiores mantêm as regras originais de cobertura.
4. **XP e fim do encontro:** vençam Ryan ou Drew ainda não concluído no perfil. Os participantes elegíveis recebem parcelas de um total de XP, com mensagem original de experiência. Aproximem-se novamente: o encontro não deve reiniciar. Fechem, reabram e repitam a aproximação; XP e conclusão devem permanecer. Treinadores já derrotados no save original também são respeitados.
5. **Nível e golpes:** se houver aumento de nível, confira nível e golpes depois de reabrir. Prompts de substituição de golpe ainda pendentes são guardados para recuperação. Modificadores nativos de Pokémon trocado são mantidos. Pokémon desmaiado segue a elegibilidade original de XP.

Vitórias antigas da arena de teste não recebem XP retroativo automaticamente. As batalhas co-op atuais ainda usam um Pokémon ativo de cada jogador; a divisão considera esses participantes. Não foram acrescentadas insígnias, dinheiro de treinador ou flags de história compartilhadas nesta correção. A adaptação completa da campanha e das reservas continua na S4.

## Logs e reversão

Envie o **`logs\menu.log` atual de cada PC**, indicando quem hospedou. Os arquivos de tentativas anteriores enviados nesta rodada não registravam uma conexão estabelecida; por isso não mostravam a chuva ou a batalha em conjunto. Logs antigos continuam com data/hora no nome. Os eventos `coop_xp`, `remote_companion_visible`, `weather_synced` e `[coop-save]` ajudam a conferir cada etapa.

Os saves permanecem em `userdata\NOME_DO_PERFIL\Godot\app_userdata\Pokémon Battle Advanced\coop_s3`. Antes de testar, pode guardar uma cópia dessa pasta com o jogo fechado.

Para reverter, feche o jogo e volte à pasta S3 anterior, que foi preservada, ou execute `python restaurar.py` dentro de `PBA-Coop-S03-Fix` para restaurar o PCK base dessa cópia. O progresso novo da Fix fica somente no perfil da Fix; a pasta S3 anterior mantém o estado anterior à atualização.
