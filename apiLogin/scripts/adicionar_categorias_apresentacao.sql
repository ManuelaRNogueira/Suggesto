-- Categorias de sugestão específicas do ramo "Apresentação" (defesa de
-- projeto/produto, pitch, TCC — ver js/categoriasPorRamo.js /
-- lib/categoriasPorRamo.dart). Puramente aditivo, mesmo padrão de
-- adicionar_categorias_por_ramo.sql.
--
-- Como rodar: mesmo processo do script anterior (MySQL Workbench, cola e
-- executa; ou phpMyAdmin; ou mysql -h 143.106.241.4 -u cl204225 -p cl204225
-- < adicionar_categorias_apresentacao.sql).

INSERT INTO categoria (nome_categoria) VALUES ('Clareza');
INSERT INTO categoria (nome_categoria) VALUES ('Conteúdo');
INSERT INTO categoria (nome_categoria) VALUES ('Slides');
INSERT INTO categoria (nome_categoria) VALUES ('Domínio do assunto');
INSERT INTO categoria (nome_categoria) VALUES ('Objetividade');

-- Confira o resultado:
--   SELECT * FROM categoria ORDER BY id_categoria;
