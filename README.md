# Click Seguro

Jogo educativo sobre ética digital e segurança na internet. Projeto de Extensão da UniFil, feito em Godot 4.6 e exportado para Web (HTML5).

## Estrutura

```
assets/
  audio/       Música e efeitos sonoros (criados para o jogo, sem direitos de terceiros)
  fonts/       IBM Plex Mono (textos) e Pixelify Sans (títulos e botões), licença OFL
  images/      Fundo, cabines e cadeados recortados do fundo, ícone
  shaders/     Efeito de tela de monitor (linhas, reflexo, bordas), só dentro da tela do PC
  sprites/     Quadros dos personagens, SpriteFrames (.tres) com as animações
               e máscaras (*_mask.png) que encaixam cada personagem no fundo
  ui/          theme.tres: o visual dos botões, painéis e textos em um único lugar
scenes/
  main_menu.tscn, game.tscn, end_screen.tscn
  components/stage.tscn             Cenário: fundo + personagens animados + cadeados
  components/scene_character.tscn   Personagem animado recortado pela máscara
scripts/
  autoload/    game_state.gd (resultado, recorde e opções salvas), audio.gd (sons),
               scene_transition.gd (fade entre telas)
  data/        challenges.gd: TODOS os desafios e textos de feedback
  ui/          challenge_view.gd (desenha o e-mail/mensagens/boleto etc.), stage.gd,
               scene_character.gd, typewriter_label.gd
  game.gd, main_menu.gd, end_screen.gd
```

## Como adicionar um desafio

Abra `scripts/data/challenges.gd`, copie um bloco `{ ... }` do mesmo tipo (`kind`) e edite. O comentário no topo do arquivo explica cada campo. Tipos disponíveis: `email`, `chat` (aplicativo de mensagens), `sms`, `call` (ligação), `file` (arquivo recebido), `login` (alerta de acesso), `qr` (cartaz com QR Code) e `boleto`.

- `clues`: `{ campo: "por que é pista" }`. Depois da resposta, o campo fica destacado e ganha uma etiqueta com a explicação (vermelha nos golpes; verde nas mensagens verdadeiras, explicando por que são confiáveis). O botão OUVIR também lê essas explicações.
- `legit: true`: a mensagem é verdadeira, e o certo é abrir ou responder.
- `best`: lista de ações que valem nota máxima. Nos golpes, DENUNCIAR e BLOQUEAR costumam estar juntas.
- `labels`: muda o texto de um botão só nessa situação (ex.: "PASSAR O CÓDIGO").
- `tip`: a dica que aparece no relatório final.

A cada partida o jogo sorteia 6 desafios, com 0 a 2 mensagens verdadeiras (para o jogador não decorar o padrão). Para mudar isso, altere `ROUND_SIZE`, `MIN_LEGIT_PER_ROUND` e `MAX_LEGIT_PER_ROUND`.

Se a mensagem não couber na tela, ela pode ser rolada (aparece o aviso "Tem mais abaixo").

## Acessibilidade

Na barra de tarefas do menu: **LETRA** (normal/grande, aumenta o texto das mensagens, do contexto, do feedback e do relatório) e **TEXTO** (normal/devagar/na hora, a velocidade com que o texto aparece). As escolhas ficam salvas. Durante a partida, **AJUDA** reabre o "Como jogar" e **MENU** volta ao menu (pede um segundo clique).

## Impacto e certificado

O `GameState` guarda um histórico neste navegador: partidas jogadas, golpes identificados e acertos por tipo de desafio. Ele aparece no menu e no fim do relatório. O botão **CERTIFICADO** da tela final mostra um certificado com o nome digitado, a data e os acertos da partida, para tirar print (útil como evidência para o relatório de extensão).

## Como mexer nas animações

Abra `assets/sprites/hacker_frames.tres` ou `defender_frames.tres` no Godot. O painel **SpriteFrames** mostra cada animação. Dá para trocar a ordem dos quadros, a velocidade (FPS) e quanto tempo cada quadro fica na tela.

Animações usadas pelo código:

- Hacker: `idle`, `hacking` (ameaça média), `dominating` (ameaça alta), `attack`, `blocked`, `defeated`, `victorious`
- Jogador: `working`, `protected`, `cautious`, `attacked`, `victory`, `defeat`

## Como o cenário é montado

O `stage.tscn` monta a cena a partir da imagem de fundo: a parte de cima (parede e monitor) aparece grande, e embaixo ficam as duas cabines (recortes do fundo, `booth_left.png` e `booth_right.png`) reduzidas, com os cadeados no meio. Dentro de cada cabine, o personagem animado fica exatamente em cima do desenho original, e uma máscara com bordas suaves (`clip_children`) mistura a animação com o cenário. Para mudar o tamanho dos personagens, altere o `scale` dos nós `LeftBooth` e `RightBooth`.

## Interface dentro da tela do computador

Em cada tela, o nó `Screen` fica exatamente em cima da tela do monitor desenhado no fundo. O conteúdo aparece como uma janela de programa (`Window`) e a pontuação fica na barra de tarefas (`Taskbar`). Se trocar a imagem de fundo, ajuste a posição do `Screen` para a nova tela.

## Som

Use `Audio.play("nome")` para tocar um efeito (lista em `scripts/autoload/audio.gd`). Os botões já tocam clique e hover sozinhos. O botão "SOM" na barra de tarefas liga e desliga tudo, e a escolha fica salva.

## Visual

Cores, bordas e fontes ficam em `assets/ui/theme.tres`. Os nós usam *Theme Type Variations* (`MonitorPanel`, `HudPanel`, `TitleLabel`, etc.), então uma mudança no tema vale para todas as telas.

## Testar a versão Web no celular

1. No Godot: **Projeto → Exportar... → Web → Exportar Projeto** (vai para `build/web/`).
2. No terminal, na pasta do projeto: `python3 servir_web.py`
3. No celular, no mesmo Wi-Fi, abra o endereço `https://...:8443` que o script mostrar. O aviso de "conexão não particular" é normal (certificado de teste): toque em **Avançado → Continuar**.

O Godot só roda no navegador com HTTPS (ou em `localhost`), por isso o `http://` pelo IP dá erro de "Secure Context".
