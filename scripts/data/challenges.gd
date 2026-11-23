class_name Challenges
## Banco de desafios. A cada partida o jogo sorteia ROUND_SIZE deles.
##
## Campos de cada desafio:
##   id        -> nome único
##   kind      -> como aparece na tela: "email", "chat", "sms", "call", "file",
##                "login", "qr" (QR Code em cartaz) ou "boleto"
##   title     -> nome curto (aparece no relatório final)
##   prompt    -> contexto/pergunta mostrado acima da mensagem
##   content   -> o que aparece dentro do "aplicativo" (depende do kind, veja challenge_view.gd)
##   clues     -> { campo do content: "por que isso é uma pista" }. Depois da resposta,
##                cada campo fica destacado com a explicação ao lado. Nas mensagens
##                verdadeiras, as "pistas" explicam por que a mensagem é confiável.
##   legit     -> true se a mensagem é verdadeira (não é golpe)
##   labels    -> (opcional) texto diferente para algum botão nesta situação
##   best      -> ações que valem nota máxima (pode ter mais de uma)
##   safe / neutral -> as outras classificações (o que sobrar é inseguro e tira vida)
##   feedback  -> explicação curta para cada ação
##   tip       -> dica de prevenção mostrada no relatório final

const ACTIONS: Array[String] = ["Abrir", "Ignorar", "Denunciar", "Bloquear"]
const DEFAULT_LABELS: Dictionary = {
	"Abrir": "ABRIR",
	"Ignorar": "IGNORAR",
	"Denunciar": "DENUNCIAR",
	"Bloquear": "BLOQUEAR",
}
## Nome de cada tipo de desafio, usado no histórico e no certificado.
const KIND_NAMES: Dictionary = {
	"email": "E-mail",
	"chat": "Mensagens",
	"sms": "SMS",
	"call": "Ligação",
	"file": "Arquivo",
	"login": "Alerta de acesso",
	"qr": "QR Code",
	"boleto": "Boleto",
}
const ROUND_SIZE: int = 6
## Quantas mensagens verdadeiras entram em cada partida (sorteado entre os dois).
## Assim o jogador não consegue "decorar" que sempre existe exatamente uma.
const MIN_LEGIT_PER_ROUND: int = 0
const MAX_LEGIT_PER_ROUND: int = 2

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
		"clues": {
			"from_addr": "O endereço termina em .xyz, não é o site do banco.",
			"subject": "Pressa e ameaça de bloqueio para você não pensar.",
			"link": "O link pede a sua senha. Banco nunca faz isso.",
		},
		"labels": {"Abrir": "CLICAR NO LINK"},
		"best": ["Denunciar", "Bloquear"],
		"safe": [],
		"neutral": ["Ignorar"],
		"feedback": {
			"Denunciar": "Endereço estranho, pressa e pedido de senha: é golpe. Denunciar avisa o serviço de e-mail e protege outras pessoas.",
			"Bloquear": "Endereço estranho, pressa e pedido de senha: é golpe. Bloquear impede que esse remetente escreva de novo.",
			"Ignorar": "Não clicar já evita o golpe, mas denunciar ou bloquear seria mais completo.",
			"Abrir": "O link leva a um site falso que rouba sua senha.",
		},
		"tip": "Banco nunca pede senha por e-mail. Desconfie de pressa e de endereços estranhos. Na dúvida, abra o aplicativo oficial do banco.",
	},
	{
		"id": "chat_premio",
		"kind": "chat",
		"title": "Prêmio falso por mensagem",
		"prompt": "Um número desconhecido mandou mensagem no aplicativo de mensagens.",
		"content": {
			"contact": "+55 11 9 8765-0000",
			"messages": [
				"PARABÉNS!!! Você foi sorteado e ganhou R$ 5.000 no Sorteio Premiado!",
				"Para receber, envie seu CPF e o código de 6 números que chegou por SMS.",
			],
		},
		"clues": {
			"contact": "Número que você não conhece.",
			"messages": "Prêmio de um sorteio que você não entrou e pedido do código do SMS.",
		},
		"labels": {"Abrir": "ENVIAR DADOS"},
		"best": ["Denunciar", "Bloquear"],
		"safe": [],
		"neutral": ["Ignorar"],
		"feedback": {
			"Denunciar": "Prêmio que você não pediu + pedido de código = golpe. Denunciar ajuda a derrubar esse número.",
			"Bloquear": "Prêmio que você não pediu + pedido de código = golpe. Bloquear impede novas mensagens desse número.",
			"Ignorar": "Ignorar evita o golpe, mas o número continua enganando outras pessoas.",
			"Abrir": "Com o código do SMS, o golpista consegue roubar a sua conta de mensagens.",
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
				"Oi! Sou eu, troquei de número. Salva esse.",
				"Tô com um problema no banco, consegue fazer um Pix de R$ 1.800 pra um amigo? Te devolvo amanhã.",
			],
		},
		"clues": {
			"contact": "Número novo, não é o que está salvo na sua agenda.",
			"messages": "Pede dinheiro com pressa e para a conta de outra pessoa.",
		},
		"labels": {"Abrir": "FAZER O PIX"},
		"best": ["Bloquear", "Denunciar"],
		"safe": [],
		"neutral": ["Ignorar"],
		"feedback": {
			"Bloquear": "Número novo pedindo dinheiro é o golpe do falso parente. Bloqueie e ligue para o número antigo do seu filho.",
			"Denunciar": "Número novo pedindo dinheiro é o golpe do falso parente. Denuncie e confirme ligando para o número antigo.",
			"Ignorar": "Não pagar evita o prejuízo, mas confirme com a família por outro meio.",
			"Abrir": "O dinheiro vai para o golpista e dificilmente volta.",
		},
		"tip": "Se um parente pedir dinheiro de um número novo, ligue para o número antigo ou pergunte algo que só ele saberia.",
	},
	{
		"id": "sms_entrega",
		"kind": "sms",
		"title": "SMS de entrega com taxa",
		"prompt": "Você recebeu um SMS sobre uma encomenda.",
		"content": {
			"sender": "40028",
			"text": "ENTREGAS BR: sua encomenda foi retida. Pague a taxa de R$ 9,90 para liberar: entregas-br4sil.top/taxa",
		},
		"clues": {
			"text": "O link troca letras (br4sil) e cobra uma taxa por mensagem.",
		},
		"labels": {"Abrir": "PAGAR A TAXA"},
		"best": ["Denunciar", "Bloquear"],
		"safe": [],
		"neutral": ["Ignorar"],
		"feedback": {
			"Denunciar": "O link imita o nome da transportadora com letras trocadas. Denunciar ajuda a operadora a bloquear o golpe.",
			"Bloquear": "O link imita o nome da transportadora com letras trocadas. Bloquear o número é seguro.",
			"Ignorar": "Ignorar evita o golpe, mas denunciar ou bloquear seria melhor.",
			"Abrir": "O site falso rouba os dados do seu cartão.",
		},
		"tip": "Confira encomendas só no site ou aplicativo oficial da loja ou da transportadora. Links com letras trocadas (br4sil) são falsos.",
	},
	{
		"id": "file_exe",
		"kind": "file",
		"title": "Arquivo com vírus",
		"prompt": "Um contato desconhecido mandou um arquivo para o seu computador.",
		"content": {
			"sender": "desconhecido_2024",
			"message": "olha essas fotos da festa kkkk abre logo",
			"file_name": "fotos_festa.exe",
			"file_size": "2,4 MB",
		},
		"clues": {
			"file_name": "Termina em .exe: é um programa, não uma foto.",
			"sender": "Contato que você não conhece.",
		},
		"labels": {"Abrir": "ABRIR ARQUIVO"},
		"best": ["Denunciar", "Bloquear"],
		"safe": [],
		"neutral": ["Ignorar"],
		"feedback": {
			"Denunciar": "Foto não termina em .exe! É um programa disfarçado. Denunciar ajuda a impedir o vírus.",
			"Bloquear": "Foto não termina em .exe! É um programa disfarçado. Bloquear evita novas tentativas.",
			"Ignorar": "Não abrir já protege, mas denunciar ou bloquear é melhor.",
			"Abrir": "Arquivos .exe instalam programas. Esse poderia sequestrar seu computador.",
		},
		"tip": "Fotos terminam em .jpg ou .png. Nunca abra arquivos .exe, .bat ou .scr (no computador) nem .apk (no celular) que você não esperava.",
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
		"clues": {
			"speech": "Pede o código que chegou para você. Suporte de verdade nunca pede.",
		},
		"labels": {"Abrir": "PASSAR O CÓDIGO"},
		"best": ["Bloquear", "Denunciar"],
		"safe": [],
		"neutral": ["Ignorar"],
		"feedback": {
			"Bloquear": "Suporte de verdade nunca pede o código. Bloquear o número corta a tentativa.",
			"Denunciar": "Suporte de verdade nunca pede o código. Denunciar o número ajuda outras pessoas.",
			"Ignorar": "Não passar o código protege você, mas bloquear ou denunciar é melhor.",
			"Abrir": "Com esse código, o golpista entra na sua conta.",
		},
		"tip": "Códigos de verificação são só seus. Nenhuma empresa liga pedindo esse número.",
	},
	{
		"id": "login_estranho",
		"kind": "login",
		"title": "Login de outro lugar",
		"prompt": "Seu e-mail mostrou um alerta. Você está em casa, em Londrina, no seu computador.",
		"content": {
			"service": "Conta de E-mail",
			"device": "Computador desconhecido",
			"location": "Porto Velho, RO",
			"time": "agora mesmo",
		},
		"clues": {
			"location": "Uma cidade onde você não está.",
			"device": "Um aparelho que não é o seu.",
		},
		"labels": {"Abrir": "FUI EU", "Bloquear": "NÃO FUI EU"},
		"best": ["Bloquear"],
		"safe": ["Denunciar"],
		"neutral": ["Ignorar"],
		"feedback": {
			"Bloquear": "Não foi você, então alguém tem sua senha. Bloqueie e troque a senha.",
			"Denunciar": "Avisar o serviço ajuda, mas também clique em NÃO FUI EU e troque sua senha agora.",
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
		"clues": {
			"subject": "Preço impossível: 95% de desconto.",
			"body": "Pressa (15 minutos) e pagamento só no Pix.",
			"from_addr": "Loja que você não conhece, com endereço estranho.",
		},
		"labels": {"Abrir": "COMPRAR"},
		"best": ["Denunciar", "Bloquear"],
		"safe": [],
		"neutral": ["Ignorar"],
		"feedback": {
			"Denunciar": "Preço impossível + pressa + só Pix = loja falsa. Denunciar ajuda outras pessoas.",
			"Bloquear": "Preço impossível + pressa + só Pix = loja falsa. Bloquear o remetente é seguro.",
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
		"clues": {
			"speech": "Susto com uma compra + pedido para instalar aplicativo. Banco não faz isso.",
		},
		"labels": {"Abrir": "INSTALAR APP"},
		"best": ["Bloquear", "Denunciar"],
		"safe": [],
		"neutral": ["Ignorar"],
		"feedback": {
			"Bloquear": "Banco não pede para instalar aplicativo por telefone. Desligue e ligue você mesmo para o número do cartão.",
			"Denunciar": "Banco não pede para instalar aplicativo por telefone. Denuncie e ligue para o número atrás do seu cartão.",
			"Ignorar": "Não instalar protege você, mas confirme com o banco pelo número oficial.",
			"Abrir": "Esse aplicativo dá ao golpista o controle do seu celular.",
		},
		"tip": "Se o banco ligar, desligue e ligue você mesmo para o número oficial atrás do cartão.",
	},
	{
		"id": "qr_estacionamento",
		"kind": "qr",
		"title": "QR Code falso no estacionamento",
		"prompt": "Você estacionou na rua e um cartaz pede o pagamento por QR Code.",
		"content": {
			"title": "ESTACIONAMENTO ROTATIVO",
			"subtitle": "Pague aqui no Pix: R$ 15,00 por hora.",
			"note": "Olhando de perto, o código é um adesivo colado por cima do cartaz.",
			"link": "estaciona-pix.top/pagar",
			"receiver": "Pix para: Marcos A. Silva",
		},
		"clues": {
			"note": "Adesivo colado por cima: alguém trocou o código original.",
			"link": "Site estranho, não é o da prefeitura nem da empresa.",
			"receiver": "O dinheiro vai para uma pessoa, não para a empresa.",
		},
		"labels": {"Abrir": "PAGAR NO PIX", "Ignorar": "NÃO PAGAR", "Denunciar": "AVISAR O FISCAL", "Bloquear": "PAGAR NO APP OFICIAL"},
		"best": ["Denunciar", "Bloquear"],
		"safe": [],
		"neutral": ["Ignorar"],
		"feedback": {
			"Denunciar": "O código foi trocado por um adesivo. Avisar o fiscal ajuda a tirar o golpe da rua.",
			"Bloquear": "Pagar pelo aplicativo oficial evita o código falso. Ótima escolha!",
			"Ignorar": "Você não caiu no golpe, mas pode levar multa. Pague pelo aplicativo oficial.",
			"Abrir": "O Pix foi para o golpista. Antes de pagar, sempre confira o nome de quem recebe.",
		},
		"tip": "Antes de pagar um QR Code, confira se não é adesivo colado e se o nome de quem recebe é o da empresa.",
	},
	{
		"id": "boleto_condominio",
		"kind": "boleto",
		"title": "Boleto adulterado",
		"prompt": "Você pediu a 2ª via do boleto do condomínio Residencial Flores. Chegou este, por mensagem.",
		"content": {
			"origin": "Enviado por: +55 43 9 9988-1122 (número desconhecido)",
			"beneficiary": "J S Cobranças Rápidas ME",
			"amount": "R$ 640,00",
			"due": "HOJE",
			"barcode": "99990.12345 67890.123456 78901.234567 1 98760000064000",
		},
		"clues": {
			"origin": "Veio de um número que não é o da administradora.",
			"beneficiary": "O nome de quem recebe não é o do condomínio.",
			"due": "Vencimento para hoje, para você pagar sem conferir.",
		},
		"labels": {"Abrir": "PAGAR", "Ignorar": "NÃO PAGAR", "Denunciar": "AVISAR O SÍNDICO", "Bloquear": "BLOQUEAR O NÚMERO"},
		"best": ["Denunciar", "Bloquear"],
		"safe": [],
		"neutral": ["Ignorar"],
		"feedback": {
			"Denunciar": "O beneficiário não é o condomínio: boleto adulterado. Avisar o síndico protege os vizinhos.",
			"Bloquear": "O beneficiário não é o condomínio: boleto adulterado. Bloqueie e peça o boleto pelo canal oficial.",
			"Ignorar": "Não pagar evita o golpe. Peça o boleto certo na administradora.",
			"Abrir": "O dinheiro foi para o golpista e o condomínio continua sem pagar.",
		},
		"tip": "Antes de pagar um boleto, confira no aplicativo do banco se o nome do beneficiário é o da empresa. Peça boletos só pelos canais oficiais.",
	},
	{
		"id": "chat_emprego",
		"kind": "chat",
		"title": "Falso emprego",
		"prompt": "Você recebeu uma proposta de trabalho por mensagem, sem ter procurado vaga.",
		"content": {
			"contact": "Vagas RH Online",
			"messages": [
				"Olá! Vaga home office: ganhe R$ 300 por dia só curtindo vídeos.",
				"Para liberar sua vaga, pague a taxa de cadastro de R$ 49,90 no Pix.",
			],
		},
		"clues": {
			"contact": "Empresa que você nunca procurou.",
			"messages": "Dinheiro fácil demais e uma taxa para começar.",
		},
		"labels": {"Abrir": "PAGAR A TAXA"},
		"best": ["Denunciar", "Bloquear"],
		"safe": [],
		"neutral": ["Ignorar"],
		"feedback": {
			"Denunciar": "Emprego de verdade não cobra para contratar. Denunciar ajuda a derrubar o golpe.",
			"Bloquear": "Emprego de verdade não cobra para contratar. Bloquear impede novas mensagens.",
			"Ignorar": "Não pagar evita o golpe, mas denunciar ou bloquear seria melhor.",
			"Abrir": "Depois da taxa, eles pedem mais dinheiro e o 'salário' nunca chega.",
		},
		"tip": "Vaga de verdade não cobra taxa de cadastro. Desconfie de ganho fácil demais.",
	},
	{
		"id": "sms_beneficio",
		"kind": "sms",
		"title": "Falso aviso da aposentadoria",
		"prompt": "Você recebe aposentadoria e chegou este SMS.",
		"content": {
			"sender": "28077",
			"text": "PREVIDENCIA: seu benefício será SUSPENSO amanhã. Atualize seu cadastro agora: recadastro-beneficio.online",
		},
		"clues": {
			"text": "Ameaça de corte e link que não termina em .gov.br.",
		},
		"labels": {"Abrir": "ATUALIZAR CADASTRO"},
		"best": ["Denunciar", "Bloquear"],
		"safe": [],
		"neutral": ["Ignorar"],
		"feedback": {
			"Denunciar": "Site do governo termina em .gov.br. Esse link rouba seus dados. Denunciar ajuda outras pessoas.",
			"Bloquear": "Site do governo termina em .gov.br. Esse link rouba seus dados. Bloquear o número é seguro.",
			"Ignorar": "Não clicar evita o golpe. Se ficar com dúvida, confira no aplicativo oficial.",
			"Abrir": "O site falso rouba seus dados e pode pedir empréstimos no seu nome.",
		},
		"tip": "Sites do governo terminam em .gov.br. Cadastro e prova de vida se fazem no aplicativo oficial ou na agência, nunca por link de SMS.",
	},
	{
		"id": "call_consignado",
		"kind": "call",
		"title": "Falso empréstimo consignado",
		"prompt": "Você está recebendo uma ligação.",
		"content": {
			"caller": "Crédito Fácil",
			"number": "(43) 3000-5566",
			"speech": "Seu empréstimo consignado com juros baixinhos já está aprovado! Só preciso confirmar seu CPF, o número do benefício e uma foto do seu documento.",
		},
		"clues": {
			"speech": "Empréstimo que você não pediu + pedido de documentos por telefone.",
		},
		"labels": {"Abrir": "PASSAR OS DADOS"},
		"best": ["Bloquear", "Denunciar"],
		"safe": [],
		"neutral": ["Ignorar"],
		"feedback": {
			"Bloquear": "Ninguém aprova empréstimo que você não pediu. Bloquear o número corta a tentativa.",
			"Denunciar": "Ninguém aprova empréstimo que você não pediu. Denunciar ajuda outras pessoas.",
			"Ignorar": "Não passar os dados protege você, mas bloquear ou denunciar é melhor.",
			"Abrir": "Com seus documentos, o golpista faz empréstimos no seu nome.",
		},
		"tip": "Ninguém aprova empréstimo que você não pediu. Nunca passe CPF, número do benefício ou foto de documento por telefone.",
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
				"Oi! Domingo eu chego pro almoço, tá?",
				"Vou levar aquele bolo que você gosta!",
			],
		},
		"clues": {
			"contact": "Contato salvo na agenda há anos.",
			"messages": "Não pede dinheiro, senha nem código.",
		},
		"legit": true,
		"labels": {"Abrir": "RESPONDER"},
		"best": ["Abrir"],
		"safe": [],
		"neutral": ["Ignorar", "Denunciar", "Bloquear"],
		"feedback": {
			"Abrir": "Contato conhecido, sem pedir dinheiro, dados ou códigos. Pode responder com tranquilidade!",
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
			"sender": "SEU BANCO",
			"text": "Seu código de acesso é 482913. Não compartilhe com ninguém.",
		},
		"clues": {
			"text": "Foi você que pediu agora, e a mensagem não pede nada.",
		},
		"legit": true,
		"labels": {"Abrir": "USAR O CÓDIGO"},
		"best": ["Abrir"],
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
		"clues": {
			"from_addr": "Endereço oficial da loja onde você comprou.",
			"body": "Combina com a sua compra e não pede dados nem pagamento.",
		},
		"legit": true,
		"labels": {"Abrir": "LER E-MAIL"},
		"best": ["Abrir"],
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
	{
		"id": "legit_consulta",
		"kind": "sms",
		"title": "Lembrete de consulta",
		"prompt": "Ontem você marcou uma consulta na Clínica Bem Viver.",
		"content": {
			"sender": "CLINICA",
			"text": "Clínica Bem Viver: lembrete da sua consulta amanhã, às 9h. Para remarcar, ligue para o telefone de sempre da clínica.",
		},
		"clues": {
			"text": "Combina com a consulta que você marcou e não pede dados, link nem pagamento.",
		},
		"legit": true,
		"labels": {"Abrir": "LER"},
		"best": ["Abrir"],
		"safe": [],
		"neutral": ["Ignorar", "Denunciar", "Bloquear"],
		"feedback": {
			"Abrir": "É só um lembrete da consulta que você marcou. Pode ler com tranquilidade!",
			"Ignorar": "Não era golpe! Era o lembrete da sua consulta.",
			"Denunciar": "Não era golpe! A clínica só lembrou da consulta.",
			"Bloquear": "Não era golpe! Agora você não recebe mais lembretes da clínica.",
		},
		"tip": "Lembrete verdadeiro combina com algo que você marcou e manda você usar o contato de sempre, sem link nem pagamento.",
	},
	{
		"id": "legit_boleto_luz",
		"kind": "boleto",
		"title": "Conta de luz verdadeira",
		"prompt": "Você entrou no site oficial da companhia de energia e baixou a sua conta de luz.",
		"content": {
			"origin": "Baixado por você no site oficial da companhia",
			"beneficiary": "Luz Forte Energia S.A.",
			"amount": "R$ 187,40",
			"due": "10/12",
			"barcode": "99990.00001 23456.789012 34567.890123 4 99990000018740",
		},
		"clues": {
			"origin": "Você mesmo baixou no site oficial.",
			"beneficiary": "O nome de quem recebe é o da companhia de energia.",
		},
		"legit": true,
		"labels": {"Abrir": "PAGAR", "Ignorar": "NÃO PAGAR"},
		"best": ["Abrir"],
		"safe": [],
		"neutral": ["Ignorar", "Denunciar", "Bloquear"],
		"feedback": {
			"Abrir": "Você baixou no site oficial e o beneficiário é a companhia. Pode pagar com segurança.",
			"Ignorar": "Não era golpe! E a conta de luz pode atrasar.",
			"Denunciar": "Não era golpe! O boleto é da companhia de energia.",
			"Bloquear": "Não era golpe! Era a sua conta de luz.",
		},
		"tip": "Boleto confiável é o que você baixou no site ou aplicativo oficial, com o nome da empresa como beneficiário.",
	},
]


## Sorteia os desafios de uma partida: de MIN a MAX verdadeiros + o resto golpes.
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

	var legit_count: int = randi_range(MIN_LEGIT_PER_ROUND, MAX_LEGIT_PER_ROUND)
	var round_list: Array[Dictionary] = []
	round_list.append_array(legit.slice(0, legit_count))
	round_list.append_array(scams.slice(0, ROUND_SIZE - round_list.size()))
	round_list.shuffle()
	return round_list


static func label_for(challenge: Dictionary, action: String) -> String:
	return challenge.get("labels", {}).get(action, DEFAULT_LABELS[action])


## true quando a ação é uma das respostas ideais do desafio.
static func is_best(challenge: Dictionary, action: String) -> bool:
	return (challenge["best"] as Array).has(action)
