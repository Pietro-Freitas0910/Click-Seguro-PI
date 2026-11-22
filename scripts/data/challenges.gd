class_name Challenges
## Banco de desafios. A cada partida o jogo sorteia ROUND_SIZE deles.
##
## Campos de cada desafio:
##   id        -> nome único
##   kind      -> como aparece na tela: "email", "chat", "sms", "call", "file", "login"
##   title     -> nome curto (aparece no relatório final)
##   prompt    -> contexto/pergunta mostrado acima da mensagem
##   content   -> o que aparece dentro do "aplicativo" (depende do kind, veja challenge_view.gd)
##   clues     -> campos do content que são pistas; ficam destacados depois da resposta
##   legit     -> true se a mensagem é verdadeira (não é golpe)
##   labels    -> (opcional) texto diferente para algum botão nesta situação
##   best / safe / neutral -> classificação das ações (o que sobrar é inseguro e tira vida)
##   feedback  -> explicação curta para cada ação
##   tip       -> dica de prevenção mostrada no relatório final

const ACTIONS: Array[String] = ["Abrir", "Ignorar", "Denunciar", "Bloquear"]
const DEFAULT_LABELS: Dictionary = {
	"Abrir": "ABRIR",
	"Ignorar": "IGNORAR",
	"Denunciar": "DENUNCIAR",
	"Bloquear": "BLOQUEAR",
}
const ROUND_SIZE: int = 6
## Quantas mensagens verdadeiras entram em cada partida.
const LEGIT_PER_ROUND: int = 1

const BANK: Array[Dictionary] = [
	{
		"id": "email_banco",
		"kind": "email",
		"title": "E-mail falso do banco",
		"prompt": "Chegou um e-mail dizendo ser do seu banco.",
		"content": {
			"from_name": "Banco Seguro S.A.",
			"from_addr": "atendimento@bancoseguro-alerta.xyz",
			"subject": "URGENTE: sua conta será BLOQUEADA hoje",
			"body": "Prezado cliente, detectamos irregularidades. Para evitar o bloqueio, confirme sua senha em até 2 horas no link abaixo.",
			"link": "bancoseguro-alerta.xyz/confirmar-senha",
		},
		"clues": ["from_addr", "subject", "link"],
		"labels": {"Abrir": "CLICAR NO LINK"},
		"best": "Denunciar",
		"safe": ["Bloquear"],
		"neutral": ["Ignorar"],
		"feedback": {
			"Denunciar": "O endereço é estranho, há pressa e pedem senha: é golpe. Denunciar protege outras pessoas.",
			"Bloquear": "Bloquear o remetente é seguro, mas denunciar também ajuda a derrubar o golpe.",
			"Ignorar": "Não clicar já evita o golpe, mas denunciar seria mais completo.",
			"Abrir": "O link leva a um site falso que rouba sua senha.",
		},
		"tip": "Banco nunca pede senha por e-mail. Desconfie de pressa e de endereços estranhos. Na dúvida, abra o aplicativo oficial do banco.",
	},
	{
		"id": "chat_premio",
		"kind": "chat",
		"title": "Prêmio falso no WhatsApp",
		"prompt": "Um número desconhecido mandou mensagem no WhatsApp.",
		"content": {
			"contact": "+55 11 9 8765-0000",
			"messages": [
				"PARABÉNS!!! Você foi sorteado e ganhou R$ 5.000 no Sorteio Premiado!",
				"Para receber, envie seu CPF e o código de 6 números que chegou por SMS.",
			],
		},
		"clues": ["contact", "messages"],
		"labels": {"Abrir": "ENVIAR DADOS"},
		"best": "Denunciar",
		"safe": ["Bloquear"],
		"neutral": ["Ignorar"],
		"feedback": {
			"Denunciar": "Prêmio de sorteio que você não participou + pedido de código = golpe. Denunciar ajuda a derrubar o número.",
			"Bloquear": "Bloquear impede novas mensagens desse número.",
			"Ignorar": "Ignorar evita o golpe, mas o número continua enganando outras pessoas.",
			"Abrir": "Com o código do SMS, o golpista consegue roubar o seu WhatsApp.",
		},
		"tip": "Nunca passe códigos recebidos por SMS. Ninguém ganha prêmio de sorteio em que não se inscreveu.",
	},
	{
		"id": "chat_parente",
		"kind": "chat",
		"title": "Falso parente pedindo Pix",
		"prompt": "Alguém dizendo ser seu filho mandou mensagem de um número novo.",
		"content": {
			"contact": "+55 21 9 9123-4567",
			"messages": [
				"Oi mãe, troquei de número! Salva esse.",
				"Tô com um problema no banco, consegue fazer um Pix de R$ 1.800 pra um amigo? Te devolvo amanhã.",
			],
		},
		"clues": ["contact", "messages"],
		"labels": {"Abrir": "FAZER O PIX"},
		"best": "Bloquear",
		"safe": ["Denunciar"],
		"neutral": ["Ignorar"],
		"feedback": {
			"Bloquear": "Número novo pedindo dinheiro é o golpe do falso parente. Bloqueie e ligue para o número antigo do seu filho.",
			"Denunciar": "Denunciar também ajuda. Depois, confirme ligando para o número antigo.",
			"Ignorar": "Não pagar evita o prejuízo, mas confirme com a família por outro meio.",
			"Abrir": "O dinheiro vai para o golpista e dificilmente volta.",
		},
		"tip": "Se um parente pedir dinheiro de um número novo, ligue para o número antigo ou pergunte algo que só ele saberia.",
	},
	{
		"id": "sms_correios",
		"kind": "sms",
		"title": "SMS de entrega com taxa",
		"prompt": "Você recebeu um SMS sobre uma encomenda.",
		"content": {
			"sender": "40028",
			"text": "CORREIOS: sua encomenda foi retida. Pague a taxa de R$ 9,90 para liberar: corr3ios-entrega.top/taxa",
		},
		"clues": ["text"],
		"labels": {"Abrir": "PAGAR A TAXA"},
		"best": "Denunciar",
		"safe": ["Bloquear"],
		"neutral": ["Ignorar"],
		"feedback": {
			"Denunciar": "O link imita o nome dos Correios com letras trocadas. Denunciar ajuda a operadora a bloquear.",
			"Bloquear": "Bloquear o número é seguro.",
			"Ignorar": "Ignorar evita o golpe, mas denunciar seria melhor.",
			"Abrir": "O site falso rouba os dados do seu cartão.",
		},
		"tip": "Confira encomendas só no site ou aplicativo oficial. Links com letras trocadas (corr3ios) são falsos.",
	},
	{
		"id": "file_exe",
		"kind": "file",
		"title": "Arquivo com vírus",
		"prompt": "Um contato desconhecido mandou um arquivo.",
		"content": {
			"sender": "desconhecido_2024",
			"message": "olha essas fotos da festa kkkk abre logo",
			"file_name": "fotos_festa.exe",
			"file_size": "2,4 MB",
		},
		"clues": ["file_name", "sender"],
		"labels": {"Abrir": "ABRIR ARQUIVO"},
		"best": "Denunciar",
		"safe": ["Bloquear"],
		"neutral": ["Ignorar"],
		"feedback": {
			"Denunciar": "Foto não termina em .exe! É um programa disfarçado. Denunciar ajuda a impedir o vírus.",
			"Bloquear": "Bloquear evita novas tentativas desse remetente.",
			"Ignorar": "Não abrir já protege, mas denunciar é melhor.",
			"Abrir": "Arquivos .exe instalam programas. Esse poderia sequestrar seu computador.",
		},
		"tip": "Fotos terminam em .jpg ou .png. Nunca abra arquivos .exe, .bat ou .scr que você não esperava.",
	},
	{
		"id": "call_suporte",
		"kind": "call",
		"title": "Ligação pedindo código",
		"prompt": "Você está recebendo uma ligação.",
		"content": {
			"caller": "Suporte Técnico",
			"number": "0800 000 0000",
			"speech": "Olá, aqui é do suporte do seu aplicativo. Para proteger sua conta, me diga o código que acabamos de enviar.",
		},
		"clues": ["speech"],
		"labels": {"Abrir": "PASSAR O CÓDIGO"},
		"best": "Bloquear",
		"safe": ["Denunciar"],
		"neutral": ["Ignorar"],
		"feedback": {
			"Bloquear": "Suporte de verdade nunca pede o código. Bloquear o número corta a tentativa.",
			"Denunciar": "Denunciar o número também ajuda outras pessoas.",
			"Ignorar": "Não passar o código protege você, mas bloquear é melhor.",
			"Abrir": "Com esse código, o golpista entra na sua conta.",
		},
		"tip": "Códigos de verificação são só seus. Nenhuma empresa liga pedindo esse número.",
	},
	{
		"id": "login_estranho",
		"kind": "login",
		"title": "Login de outro lugar",
		"prompt": "Seu e-mail mostrou um alerta. Você está em casa, no seu computador.",
		"content": {
			"service": "Conta de E-mail",
			"device": "Computador desconhecido",
			"location": "Lagos, Nigéria",
			"time": "agora mesmo",
		},
		"clues": ["location", "device"],
		"labels": {"Abrir": "FUI EU", "Bloquear": "NÃO FUI EU"},
		"best": "Bloquear",
		"safe": ["Denunciar"],
		"neutral": ["Ignorar"],
		"feedback": {
			"Bloquear": "Não foi você, então alguém tem sua senha. Bloqueie e troque a senha.",
			"Denunciar": "Avisar o serviço ajuda, mas também troque sua senha agora.",
			"Ignorar": "Sem agir, o invasor continua dentro da sua conta.",
			"Abrir": "Você acabou de liberar o acesso para um invasor.",
		},
		"tip": "Ative a verificação em duas etapas e use senhas diferentes em cada site.",
	},
	{
		"id": "email_promo",
		"kind": "email",
		"title": "Promoção boa demais",
		"prompt": "Chegou uma promoção no seu e-mail.",
		"content": {
			"from_name": "Ofertas Mega Loja",
			"from_addr": "promo@megaloja-ofertas.click",
			"subject": "Celular de R$ 4.000 por R$ 199 - só hoje!",
			"body": "Últimas 3 unidades! Pague no Pix agora e garanta o seu. Promoção válida por 15 minutos.",
			"link": "megaloja-ofertas.click/pix",
		},
		"clues": ["subject", "body", "from_addr"],
		"labels": {"Abrir": "COMPRAR"},
		"best": "Denunciar",
		"safe": ["Bloquear"],
		"neutral": ["Ignorar"],
		"feedback": {
			"Denunciar": "Preço impossível + pressa + só Pix = loja falsa. Denunciar ajuda outras pessoas.",
			"Bloquear": "Bloquear o remetente é seguro.",
			"Ignorar": "Não comprar evita o prejuízo.",
			"Abrir": "O produto nunca chega e o Pix não tem como ser cancelado.",
		},
		"tip": "Desconfie de preço muito abaixo do normal e de lojas que só aceitam Pix com prazo curto.",
	},
	{
		"id": "call_banco",
		"kind": "call",
		"title": "Falsa central do banco",
		"prompt": "Você está recebendo uma ligação.",
		"content": {
			"caller": "Central do Banco",
			"number": "(11) 4000-1234",
			"speech": "Identificamos uma compra de R$ 3.200 no seu cartão. Para cancelar, instale o aplicativo que vamos mandar por mensagem.",
		},
		"clues": ["speech"],
		"labels": {"Abrir": "INSTALAR APP"},
		"best": "Bloquear",
		"safe": ["Denunciar"],
		"neutral": ["Ignorar"],
		"feedback": {
			"Bloquear": "Banco não pede para instalar aplicativo por telefone. Desligue e ligue você mesmo para o número do cartão.",
			"Denunciar": "Denunciar ajuda. Depois, ligue para o número que está atrás do seu cartão.",
			"Ignorar": "Não instalar protege você, mas confirme com o banco pelo número oficial.",
			"Abrir": "Esse aplicativo dá ao golpista o controle do seu celular.",
		},
		"tip": "Se o banco ligar, desligue e ligue você mesmo para o número oficial atrás do cartão.",
	},
	# --- Mensagens VERDADEIRAS (não são golpe) ---
	{
		"id": "legit_neto",
		"kind": "chat",
		"title": "Mensagem do neto",
		"prompt": "Seu neto, salvo nos contatos há anos, mandou mensagem.",
		"content": {
			"contact": "Pedro (neto)",
			"messages": [
				"Oi vó! Domingo eu chego pro almoço, tá?",
				"Vou levar aquele bolo que a senhora gosta!",
			],
		},
		"clues": [],
		"legit": true,
		"labels": {"Abrir": "RESPONDER"},
		"best": "Abrir",
		"safe": [],
		"neutral": ["Ignorar", "Denunciar", "Bloquear"],
		"feedback": {
			"Abrir": "Contato conhecido, sem pedir dinheiro, dados ou códigos. Pode responder tranquila!",
			"Ignorar": "Não era golpe! Contato conhecido, sem pedir nada.",
			"Denunciar": "Não era golpe! Nem toda mensagem é perigosa.",
			"Bloquear": "Não era golpe! Você bloqueou seu próprio neto.",
		},
		"tip": "Nem tudo é golpe: contato conhecido, sem pedir dinheiro, senha ou código, é seguro.",
	},
	{
		"id": "legit_codigo",
		"kind": "sms",
		"title": "Código que você pediu",
		"prompt": "Você acabou de pedir um código para entrar no aplicativo do banco, no seu celular.",
		"content": {
			"sender": "BANCO",
			"text": "Seu código de acesso é 482913. Não compartilhe com ninguém.",
		},
		"clues": [],
		"legit": true,
		"labels": {"Abrir": "USAR O CÓDIGO"},
		"best": "Abrir",
		"safe": [],
		"neutral": ["Ignorar", "Denunciar", "Bloquear"],
		"feedback": {
			"Abrir": "Foi você que pediu o código, e ele só vai ser usado por você. Correto!",
			"Ignorar": "Não era golpe! Foi você mesmo que pediu o código.",
			"Denunciar": "Não era golpe! O código foi pedido por você.",
			"Bloquear": "Não era golpe! Agora você não recebe mais seus códigos.",
		},
		"tip": "Um código só é seguro quando foi você que pediu e você mesmo vai digitar. Nunca passe para outra pessoa.",
	},
	{
		"id": "legit_compra",
		"kind": "email",
		"title": "Confirmação de compra real",
		"prompt": "Ontem você comprou um ventilador no site oficial dessa loja.",
		"content": {
			"from_name": "Loja Casa Boa",
			"from_addr": "pedidos@casaboa.com.br",
			"subject": "Seu pedido #48210 foi enviado",
			"body": "Olá! Seu ventilador já está a caminho. Acompanhe a entrega no aplicativo da loja. Não pedimos dados ou pagamentos por e-mail.",
			"link": "",
		},
		"clues": [],
		"legit": true,
		"labels": {"Abrir": "LER E-MAIL"},
		"best": "Abrir",
		"safe": [],
		"neutral": ["Ignorar", "Denunciar", "Bloquear"],
		"feedback": {
			"Abrir": "Você fez a compra, o endereço é oficial e não pedem nada. Pode ler com segurança.",
			"Ignorar": "Não era golpe! Era a confirmação da sua compra.",
			"Denunciar": "Não era golpe! A loja é a mesma onde você comprou.",
			"Bloquear": "Não era golpe! Agora você não recebe mais avisos da loja.",
		},
		"tip": "Mensagem verdadeira combina com algo que você fez, vem do endereço oficial e não pede senha nem pagamento.",
	},
]


## Sorteia os desafios de uma partida: LEGIT_PER_ROUND verdadeiros + o resto golpes.
static func pick_round() -> Array[Dictionary]:
	var scams: Array[Dictionary] = []
	var legit: Array[Dictionary] = []
	for challenge: Dictionary in BANK:
		if challenge.get("legit", false):
			legit.append(challenge)
		else:
			scams.append(challenge)
	scams.shuffle()
	legit.shuffle()

	var round_list: Array[Dictionary] = []
	round_list.append_array(legit.slice(0, LEGIT_PER_ROUND))
	round_list.append_array(scams.slice(0, ROUND_SIZE - round_list.size()))
	round_list.shuffle()
	return round_list


static func label_for(challenge: Dictionary, action: String) -> String:
	return challenge.get("labels", {}).get(action, DEFAULT_LABELS[action])
