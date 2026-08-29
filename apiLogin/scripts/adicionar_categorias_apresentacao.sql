-- Categorias de sugestão do ramo "Apresentação" (o Suggesto avaliado como
-- app, numa feira/demo — ver js/categoriasPorRamo.js /
-- lib/categoriasPorRamo.dart). Lista fechada, só estas 7 + "Outro" (que já
-- existe, id 8). Puramente aditivo, mesmo padrão dos scripts anteriores.
--
-- Se você já rodou uma versão anterior deste script (com "Clareza",
-- "Conteúdo", "Slides", "Domínio do assunto", "Objetividade"), essas linhas
-- antigas ficam sem uso — não têm mais nenhuma categoria delas no config, mas
-- não atrapalham nada, só sobram sem serem escolhidas por ninguém.
--
-- Como rodar: mesmo processo dos scripts anteriores (MySQL Workbench, cola e
-- executa; ou phpMyAdmin; ou mysql -h 143.106.241.4 -u cl204225 -p cl204225
-- < adicionar_categorias_apresentacao.sql).

INSERT INTO categoria (nome_categoria) VALUES ('Design e interface');
INSERT INTO categoria (nome_categoria) VALUES ('Facilidade de uso');
INSERT INTO categoria (nome_categoria) VALUES ('Funcionalidades');
INSERT INTO categoria (nome_categoria) VALUES ('Desempenho');
INSERT INTO categoria (nome_categoria) VALUES ('Experiência do usuário');
INSERT INTO categoria (nome_categoria) VALUES ('Acessibilidade');
INSERT INTO categoria (nome_categoria) VALUES ('Proposta do projeto');

-- Confira o resultado:
--   SELECT * FROM categoria ORDER BY id_categoria;
