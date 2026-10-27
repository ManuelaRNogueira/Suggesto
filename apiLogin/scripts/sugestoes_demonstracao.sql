-- Dados de demonstração pra apresentação: 16 clientes fictícios e ~70 sugestões,
-- críticas e elogios espalhados pelos estabelecimentos (ids 1 a 14), com uma
-- mistura de pendentes, implementadas e recusadas e algumas respostas da equipe.
--
-- Todos os usuários criados têm e-mail demo.<nome>@example.com. A senha deles é
-- um hash que não casa com nenhuma senha, então ninguém consegue logar nessas
-- contas — elas só aparecem como autores.
--
-- É idempotente: apaga o que ele mesmo criou antes e cria de novo, então pode
-- rodar mais de uma vez. Pra remover tudo, rode só o bloco "LIMPEZA".
-- Banco: MySQL. As categorias são procuradas pelo nome (tabela categoria).

-- ---------------------------------------------------------------- LIMPEZA
DELETE FROM avaliacao WHERE id_usuario IN (SELECT ID_Usuario FROM usuario WHERE Email LIKE 'demo.%@example.com');
DELETE FROM usuario WHERE Email LIKE 'demo.%@example.com';
-- (fim da LIMPEZA — se só quer apagar, pare aqui)

-- ---------------------------------------------------------------- USUÁRIOS
INSERT INTO usuario (Nome_Usuario, Username, Email, Senha, Tipo_Usuario, Cidade, Estado, pontos, pontos_acumulados) VALUES
('Ana Clara Souza',     'anaclara.souza',  'demo.ana@example.com',      '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'Limeira',          'SP', 0, 0),
('Bruno Mendes',        'bruno.mendes',    'demo.bruno@example.com',    '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'Campinas',         'SP', 0, 0),
('Carla Dias',          'carla.dias',      'demo.carla@example.com',    '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'Campinas',         'SP', 0, 0),
('Diego Rocha',         'diego.rocha',     'demo.diego@example.com',    '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'Limeira',          'SP', 0, 0),
('Fernanda Lima',       'fernanda.lima',   'demo.fernanda@example.com', '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'Campinas',         'SP', 0, 0),
('Gabriel Alves',       'gabriel.alves',   'demo.gabriel@example.com',  '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'São Paulo',        'SP', 0, 0),
('Helena Martins',      'helena.martins',  'demo.helena@example.com',   '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'Limeira',          'SP', 0, 0),
('Igor Santos',         'igor.santos',     'demo.igor@example.com',     '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'Campinas',         'SP', 0, 0),
('Júlia Ferreira',      'julia.ferreira',  'demo.julia@example.com',    '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'Americana',        'SP', 0, 0),
('Lucas Pereira',       'lucas.pereira',   'demo.lucas@example.com',    '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'Campinas',         'SP', 0, 0),
('Mariana Costa',       'mariana.costa',   'demo.mariana@example.com',  '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'Limeira',          'SP', 0, 0),
('Nicolas Araújo',      'nicolas.araujo',  'demo.nicolas@example.com',  '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'Campinas',         'SP', 0, 0),
('Patrícia Gomes',      'patricia.gomes',  'demo.patricia@example.com', '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'Poços de Caldas',  'MG', 0, 0),
('Rafael Barbosa',      'rafael.barbosa',  'demo.rafael@example.com',   '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'Campinas',         'SP', 0, 0),
('Sofia Ribeiro',       'sofia.ribeiro',   'demo.sofia@example.com',    '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'Limeira',          'SP', 0, 0),
('Thiago Nunes',        'thiago.nunes',    'demo.thiago@example.com',   '$2a$10$demoDemoDemoDemoDemoDeuDemoDemoDemoDemoDemoDemoDemoDe', 'Cliente', 'São Paulo',        'SP', 0, 0);

-- ------------------------------------------------------------- SUGESTÕES
-- autor = parte do e-mail (demo.<autor>@example.com); horas_atras = há quanto
-- tempo foi enviada; resp_apos_h = quantas horas depois a equipe respondeu/decidiu.
DROP TEMPORARY TABLE IF EXISTS tmp_sug;
CREATE TEMPORARY TABLE tmp_sug (
  autor VARCHAR(20), est INT, categoria VARCHAR(60), tipo VARCHAR(20), nota INT,
  comentario TEXT, horas_atras INT, status VARCHAR(20), resposta TEXT,
  resp_apos_h INT, motivo TEXT, metodo VARCHAR(20)
);

INSERT INTO tmp_sug VALUES
-- 1 · Pinho's Bistrô (Restaurante)
('ana', 1, 'Qualidade da comida', 'elogio', 5, 'O risoto de cogumelos estava perfeito, no ponto certo e bem temperado. Voltarei com certeza!', 52, 'pendente', 'Ficamos muito felizes, Ana! Vamos passar o elogio pro chef.', 3, NULL, 'QR'),
('diego', 1, 'Atendimento', 'sugestao', 4, 'Seria legal ter um cardápio com QR code na mesa, às vezes demora um pouco pra pegar o impresso.', 130, 'IMPLEMENTADA', 'Boa ideia, Diego! Já colocamos os QR codes nas mesas esta semana.', 20, NULL, 'QR'),
('helena', 1, 'Ambiente', 'critica', 2, 'A música estava muito alta e dificultava a conversa na mesa. Dava pra baixar um pouco o volume.', 200, 'IMPLEMENTADA', 'Obrigado pelo aviso, Helena. Ajustamos o volume no horário do jantar.', 30, NULL, 'LOCALIZACAO'),
('mariana', 1, 'Preço', 'sugestao', 3, 'Poderia ter um menu executivo no almoço com preço fechado, ia atrair bastante gente do centro.', 310, 'RECUSADA', 'Agradecemos a sugestão, Mariana.', 48, 'No momento abrimos só à noite, mas vamos avaliar um menu executivo no futuro.', 'QR'),

-- 2 · Vila Amparo (Restaurante)
('sofia', 2, 'Cardápio', 'sugestao', 4, 'Falta uma opção vegetariana principal no cardápio, só tem acompanhamento sem carne.', 70, 'pendente', NULL, NULL, NULL, 'QR'),
('ana', 2, 'Ambiente', 'elogio', 5, 'Lugar lindo, iluminação aconchegante e ótimo pra comemorar aniversário. Adoramos!', 160, 'pendente', 'Que bom que gostou, Ana! Esperamos vocês de novo.', 5, NULL, 'LOCALIZACAO'),
('mariana', 2, 'Atendimento', 'critica', 2, 'Esperamos quase 40 minutos pelo prato principal e ninguém avisou do atraso.', 240, 'IMPLEMENTADA', 'Pedimos desculpas, Mariana. Reforçamos a equipe de salão e agora avisamos a mesa quando há atraso.', 26, NULL, 'QR'),
('diego', 2, 'Higiene', 'critica', 3, 'O banheiro estava sem papel no sábado à noite. Vale ficar de olho nos horários de pico.', 400, 'pendente', NULL, NULL, NULL, 'QR'),
('sofia', 2, 'Qualidade da comida', 'elogio', 5, 'A costela com purê é de outro mundo, derrete na boca.', 520, 'pendente', 'Nosso carro-chefe! Obrigado, Sofia.', 4, NULL, 'LOCALIZACAO'),

-- 3 · Padaria Piracam (Padaria)
('bruno', 3, 'Qualidade da comida', 'elogio', 5, 'O pão francês sai quentinho às 6h, o melhor da região. Já virei freguês de todo dia.', 30, 'pendente', 'Que honra, Bruno! A primeira fornada sai às 6h mesmo.', 2, NULL, 'LOCALIZACAO'),
('carla', 3, 'Variedade', 'sugestao', 4, 'Poderiam ter mais opções sem glúten e sem lactose, fica difícil pra quem tem restrição.', 90, 'IMPLEMENTADA', 'Ótima sugestão, Carla! Já temos pão sem glúten e bolo sem lactose às quartas e sextas.', 72, NULL, 'QR'),
('igor', 3, 'Atendimento', 'critica', 2, 'Fila grande no caixa de manhã com só uma pessoa atendendo. Perdi o horário do trabalho.', 150, 'pendente', NULL, NULL, NULL, 'LOCALIZACAO'),
('lucas', 3, 'Preço', 'sugestao', 3, 'Um combo café da manhã com pão na chapa, café e suco ia ser ótimo e atrair mais gente.', 260, 'IMPLEMENTADA', 'Combo criado! Já está no balcão, Lucas. Obrigado pela ideia.', 40, NULL, 'QR'),
('rafael', 3, 'Higiene', 'elogio', 4, 'Tudo muito limpo, funcionários de touca e luva, dá confiança.', 380, 'pendente', NULL, NULL, NULL, 'LOCALIZACAO'),

-- 4 · Colégio Franciscano Ave Maria (Educacao)
('carla', 4, 'Estrutura', 'sugestao', 4, 'A quadra poderia ter cobertura, em dia de chuva as aulas de educação física são perdidas.', 110, 'pendente', NULL, NULL, NULL, 'QR'),
('nicolas', 4, 'Atendimento', 'elogio', 5, 'A secretaria resolveu minha documentação em poucos minutos, equipe muito educada.', 200, 'pendente', 'Agradecemos, Nicolas! Nossa secretaria fica feliz com o reconhecimento.', 6, NULL, 'LOCALIZACAO'),
('fernanda', 4, 'Outro', 'sugestao', 3, 'Seria bom ter um aplicativo ou portal para acompanhar notas e comunicados dos pais.', 330, 'RECUSADA', 'Obrigado, Fernanda.', 96, 'Já temos um portal dos pais ativo; vamos reforçar a divulgação do acesso.', 'QR'),
('lucas', 4, 'Ambiente', 'critica', 2, 'O pátio fica muito quente na hora do intervalo, faltam áreas com sombra para as crianças.', 450, 'pendente', NULL, NULL, NULL, 'LOCALIZACAO'),

-- 5 · Mercadinho Princesa (Comercio)
('igor', 5, 'Preço', 'sugestao', 4, 'Poderia ter promoção semanal de hortifrúti, sempre vejo outros mercados com isso.', 45, 'pendente', NULL, NULL, NULL, 'QR'),
('rafael', 5, 'Atendimento', 'elogio', 5, 'O senhor do caixa é muito simpático e ajuda a embalar as compras. Fez meu dia.', 120, 'pendente', 'Repassamos o recado! Obrigado, Rafael.', 8, NULL, 'LOCALIZACAO'),
('bruno', 5, 'Estrutura', 'critica', 2, 'Os corredores são estreitos e é difícil passar com o carrinho em horário de movimento.', 280, 'IMPLEMENTADA', 'Reorganizamos as gôndolas centrais para abrir mais espaço. Obrigado pelo aviso.', 50, NULL, 'QR'),
('carla', 5, 'Qualidade do produto', 'critica', 1, 'Comprei um iogurte vencido há dois dias na prateleira. Precisam conferir as validades com mais atenção.', 360, 'IMPLEMENTADA', 'Pedimos desculpas, Carla. Passamos a conferir as validades todo dia de manhã.', 18, NULL, 'LOCALIZACAO'),

-- 6 · Genitus Engenharia (Servicos)
('gabriel', 6, 'Atendimento', 'elogio', 5, 'Fui muito bem atendido pelo engenheiro responsável, explicou tudo com clareza e sem enrolação.', 80, 'pendente', 'Agradecemos, Gabriel! Foi um prazer atender seu projeto.', 10, NULL, 'QR'),
('thiago', 6, 'Outro', 'sugestao', 4, 'Seria bom receber um relatório de andamento semanal por e-mail, ajuda a acompanhar a obra.', 190, 'IMPLEMENTADA', 'Implementamos o envio semanal de relatório. Obrigado pela sugestão, Thiago.', 60, NULL, 'LOCALIZACAO'),
('gabriel', 6, 'Preço', 'critica', 3, 'O orçamento demorou mais de uma semana para chegar. O valor foi justo, mas o prazo foi longo.', 340, 'pendente', NULL, NULL, NULL, 'QR'),

-- 7 · Monreale Hotéis (Hotel)
('patricia', 7, 'Atendimento', 'elogio', 5, 'Recepção excelente, fizeram o check-in rápido e ainda indicaram ótimos passeios na cidade.', 60, 'pendente', 'Ficamos muito felizes com a sua estadia, Patrícia!', 12, NULL, 'LOCALIZACAO'),
('thiago', 7, 'Estrutura', 'sugestao', 4, 'Mais tomadas ao lado da cama seriam muito úteis, só havia uma e longe do colchão.', 170, 'IMPLEMENTADA', 'Instalamos novas tomadas e portas USB nos quartos. Obrigado, Thiago!', 120, NULL, 'QR'),
('patricia', 7, 'Ambiente', 'critica', 3, 'O corredor do andar tinha barulho até tarde da noite, dificultou o descanso.', 290, 'pendente', NULL, NULL, NULL, 'LOCALIZACAO'),
('julia', 7, 'Preço', 'sugestao', 3, 'Pacotes com café da manhã incluso e saída tardia ficariam mais atraentes para casais.', 410, 'RECUSADA', 'Obrigado, Júlia.', 72, 'Os pacotes já existem em temporada alta; vamos divulgá-los melhor no site.', 'QR'),

-- 9 · Mútuo (Coworking)
('lucas', 9, 'Internet/Wi-Fi', 'critica', 2, 'O Wi-Fi caiu duas vezes durante uma videochamada importante. Precisa de mais estabilidade.', 25, 'pendente', NULL, NULL, NULL, 'QR'),
('julia', 9, 'Ambiente', 'elogio', 5, 'Espaço lindo, silencioso e com boa luz natural. Rende demais para trabalhar aqui.', 100, 'pendente', 'Que bom, Júlia! Essa era a ideia do espaço.', 7, NULL, 'LOCALIZACAO'),
('nicolas', 9, 'Estrutura', 'sugestao', 5, 'Faltam salas de reunião menores para duas ou três pessoas, só tem a sala grande.', 215, 'IMPLEMENTADA', 'Transformamos uma sala em duas cabines de reunião. Obrigado, Nicolas.', 96, NULL, 'QR'),
('fernanda', 9, 'Limpeza', 'elogio', 4, 'Cozinha e banheiros sempre limpos, dá gosto de usar.', 300, 'pendente', NULL, NULL, NULL, 'LOCALIZACAO'),
('thiago', 9, 'Preço', 'sugestao', 3, 'Um plano de diárias para quem vai só alguns dias no mês seria bem vindo.', 430, 'pendente', NULL, NULL, NULL, 'QR'),

-- 11 · Drogasil (Farmácia)
('helena', 11, 'Agilidade', 'critica', 2, 'Fila enorme no balcão no fim da tarde e só um atendente. Demorei mais de 20 minutos.', 35, 'pendente', NULL, NULL, NULL, 'LOCALIZACAO'),
('igor', 11, 'Atendimento', 'elogio', 5, 'A farmacêutica explicou direitinho como tomar o remédio e ainda sugeriu uma opção mais barata.', 95, 'pendente', 'Agradecemos o carinho, Igor!', 4, NULL, 'QR'),
('sofia', 11, 'Variedade', 'sugestao', 3, 'Faltam mais produtos de dermocosméticos na loja, tive que ir a outra para achar o protetor que uso.', 210, 'RECUSADA', 'Obrigado, Sofia.', 70, 'O sortimento é definido pela rede; vamos encaminhar o pedido para a central de compras.', 'LOCALIZACAO'),
('bruno', 11, 'Organização', 'sugestao', 4, 'Poderiam sinalizar melhor as seções da loja, demorei pra achar os produtos infantis.', 330, 'IMPLEMENTADA', 'Colocamos placas de identificação nos corredores. Obrigado, Bruno.', 45, NULL, 'QR'),
('carla', 11, 'Higiene', 'elogio', 4, 'Loja muito limpa e organizada, com álcool em gel na entrada.', 470, 'pendente', NULL, NULL, NULL, 'LOCALIZACAO'),

-- 12 · Suggesto (Apresentação)
('ana', 12, 'Design e interface', 'elogio', 5, 'Visual limpo e moderno, as cores combinam e os botões são fáceis de achar.', 20, 'pendente', NULL, NULL, NULL, 'QR'),
('gabriel', 12, 'Facilidade de uso', 'elogio', 5, 'Em menos de um minuto já tinha escaneado o QR e enviado uma sugestão. Muito simples!', 40, 'pendente', NULL, NULL, NULL, 'QR'),
('rafael', 12, 'Funcionalidades', 'sugestao', 4, 'Seria legal poder anexar uma foto na sugestão, ajuda a mostrar o problema.', 65, 'pendente', NULL, NULL, NULL, 'LOCALIZACAO'),
('mariana', 12, 'Proposta do projeto', 'elogio', 5, 'Ideia ótima: dá voz ao cliente e ainda recompensa com pontos. Parabéns à equipe!', 85, 'pendente', NULL, NULL, NULL, 'QR'),
('nicolas', 12, 'Desempenho', 'critica', 3, 'No primeiro acesso a página demorou um pouco para carregar, depois ficou rápido.', 105, 'pendente', NULL, NULL, NULL, 'QR'),
('patricia', 12, 'Acessibilidade', 'sugestao', 4, 'Poderia ter modo escuro e opção de aumentar a fonte para quem tem dificuldade de leitura.', 130, 'pendente', NULL, NULL, NULL, 'LOCALIZACAO'),
('julia', 12, 'Clareza da apresentação', 'elogio', 5, 'A apresentação foi clara, objetiva e a demonstração mostrou bem como tudo funciona.', 150, 'pendente', NULL, NULL, NULL, 'QR'),
('thiago', 12, 'Experiência do usuário', 'elogio', 4, 'Fluxo bem pensado, do check-in até o envio. Só faltou um aviso de confirmação mais visível.', 175, 'pendente', NULL, NULL, NULL, 'QR'),

-- 13 · Cotil Limeira (Escola / Educação)
('diego', 13, 'Ensino', 'elogio', 5, 'Professores dedicados e aulas práticas que realmente preparam para o mercado.', 55, 'pendente', 'Agradecemos, Diego! Nossos professores merecem o reconhecimento.', 9, NULL, 'LOCALIZACAO'),
('sofia', 13, 'Recursos', 'sugestao', 4, 'Os laboratórios de informática poderiam ter computadores mais novos para os projetos.', 140, 'pendente', NULL, NULL, NULL, 'QR'),
('ana', 13, 'Organização', 'critica', 3, 'A troca de horários de aula foi avisada em cima da hora. Dava para comunicar com antecedência.', 270, 'IMPLEMENTADA', 'Passamos a avisar mudanças de horário com 48h de antecedência pelo mural e pelo app.', 80, NULL, 'QR'),
('helena', 13, 'Limpeza', 'elogio', 4, 'Salas e banheiros bem cuidados durante o dia todo.', 360, 'pendente', NULL, NULL, NULL, 'LOCALIZACAO'),
('mariana', 13, 'Estrutura', 'sugestao', 5, 'A biblioteca poderia abrir mais cedo e ter mesas de estudo em grupo.', 480, 'pendente', NULL, NULL, NULL, 'QR'),

-- 14 · Starbucks (Cafeteria)
('gabriel', 14, 'Atendimento', 'elogio', 5, 'Atendente anotou meu nome certinho no copo e acertou a bebida do primeiro jeito. Ótimo!', 15, 'pendente', NULL, NULL, NULL, 'QR'),
('thiago', 14, 'Preço', 'critica', 2, 'Os preços das bebidas sobem a cada mês. Um programa de fidelidade com desconto ajudaria.', 75, 'pendente', NULL, NULL, NULL, 'LOCALIZACAO'),
('julia', 14, 'Ambiente', 'sugestao', 4, 'Faltam tomadas perto das mesas, muita gente trabalha aqui com notebook.', 125, 'pendente', NULL, NULL, NULL, 'QR'),
('patricia', 14, 'Cardápio', 'sugestao', 4, 'Mais opções de bebidas veganas com leite de aveia ou coco seriam bem-vindas.', 195, 'IMPLEMENTADA', 'Incluímos leite de aveia sem custo extra no cardápio fixo. Obrigado!', 100, NULL, 'LOCALIZACAO'),
('gabriel', 14, 'Qualidade da comida', 'elogio', 4, 'O sanduíche de peru estava fresquinho e bem recheado.', 250, 'pendente', NULL, NULL, NULL, 'QR'),
('nicolas', 14, 'Higiene', 'critica', 3, 'As mesas demoraram a ser limpas depois que os clientes saíram, ficou meio sujo no sábado.', 340, 'pendente', NULL, NULL, NULL, 'LOCALIZACAO');

-- Gravação final: cruza cada linha com o usuário, o estabelecimento e a
-- categoria reais do banco. Linha sem categoria ou usuário encontrado é
-- descartada (o SELECT abaixo mostra quantas entraram).
INSERT INTO avaliacao
  (id_usuario, id_estabelecimento, id_categoria, tipo, nota, comentario, status,
   data_avaliacao, resposta, data_resposta, respondido_por, motivo_recusa,
   data_decisao, metodo_visita)
SELECT u.ID_Usuario, e.id_estabelecimento, c.id_categoria, t.tipo, t.nota, t.comentario, t.status,
       DATE_SUB(NOW(), INTERVAL t.horas_atras HOUR),
       t.resposta,
       CASE WHEN t.resposta IS NOT NULL
            THEN DATE_SUB(NOW(), INTERVAL (t.horas_atras - t.resp_apos_h) HOUR) END,
       CASE WHEN t.resposta IS NOT NULL
            THEN (SELECT g.Nome_Usuario FROM usuario g WHERE g.ID_Usuario = e.id_gerente) END,
       t.motivo,
       CASE WHEN t.status IN ('IMPLEMENTADA', 'RECUSADA')
            THEN DATE_SUB(NOW(), INTERVAL (t.horas_atras - COALESCE(t.resp_apos_h, 24)) HOUR) END,
       t.metodo
FROM tmp_sug t
JOIN usuario u ON u.Email = CONCAT('demo.', t.autor, '@example.com')
JOIN estabelecimento e ON e.id_estabelecimento = t.est
JOIN categoria c ON c.nome_categoria = t.categoria;

DROP TEMPORARY TABLE tmp_sug;

-- Cada sugestão implementada vale 500 pontos pro autor (igual à regra da API).
UPDATE usuario u
SET pontos = 500 * (SELECT COUNT(*) FROM avaliacao a WHERE a.id_usuario = u.ID_Usuario AND a.status = 'IMPLEMENTADA'),
    pontos_acumulados = 500 * (SELECT COUNT(*) FROM avaliacao a WHERE a.id_usuario = u.ID_Usuario AND a.status = 'IMPLEMENTADA')
WHERE u.Email LIKE 'demo.%@example.com';

-- Conferência: quantas sugestões demo existem por estabelecimento.
SELECT e.id_estabelecimento, e.nome_estabelecimento, COUNT(a.id_avaliacao) AS demo_sugestoes
FROM estabelecimento e
LEFT JOIN avaliacao a ON a.id_estabelecimento = e.id_estabelecimento
  AND a.id_usuario IN (SELECT ID_Usuario FROM usuario WHERE Email LIKE 'demo.%@example.com')
GROUP BY e.id_estabelecimento, e.nome_estabelecimento
ORDER BY e.id_estabelecimento;
