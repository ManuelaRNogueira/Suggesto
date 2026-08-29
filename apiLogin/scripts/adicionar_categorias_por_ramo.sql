-- Adiciona as categorias de sugestão novas, específicas de cada ramo de
-- estabelecimento (ver js/categoriasPorRamo.js / lib/categoriasPorRamo.dart —
-- é lá que se decide quais categorias aparecem pra qual ramo; aqui só cria as
-- linhas na tabela). Puramente aditivo: não mexe nas 8 categorias que já
-- existem (ids 1-8) nem no que já foi respondido/salvo antes.
--
-- Como rodar:
--   mysql -h 143.106.241.4 -u cl204225 -p cl204225 < adicionar_categorias_por_ramo.sql
-- ou cole no phpMyAdmin / MySQL Workbench conectado nesse banco.

INSERT INTO categoria (nome_categoria) VALUES ('Limpeza');
INSERT INTO categoria (nome_categoria) VALUES ('Qualidade da comida');
INSERT INTO categoria (nome_categoria) VALUES ('Qualidade do serviço');
INSERT INTO categoria (nome_categoria) VALUES ('Equipamentos');
INSERT INTO categoria (nome_categoria) VALUES ('Horários');
INSERT INTO categoria (nome_categoria) VALUES ('Aulas');
INSERT INTO categoria (nome_categoria) VALUES ('Quartos');
INSERT INTO categoria (nome_categoria) VALUES ('Café da manhã');
INSERT INTO categoria (nome_categoria) VALUES ('Serviços');
INSERT INTO categoria (nome_categoria) VALUES ('Ensino');
INSERT INTO categoria (nome_categoria) VALUES ('Organização');
INSERT INTO categoria (nome_categoria) VALUES ('Recursos');
INSERT INTO categoria (nome_categoria) VALUES ('Variedade');
INSERT INTO categoria (nome_categoria) VALUES ('Agilidade');
INSERT INTO categoria (nome_categoria) VALUES ('Segurança');
INSERT INTO categoria (nome_categoria) VALUES ('Suporte');
INSERT INTO categoria (nome_categoria) VALUES ('Transparência');
INSERT INTO categoria (nome_categoria) VALUES ('Internet/Wi-Fi');
INSERT INTO categoria (nome_categoria) VALUES ('Cuidado com os animais');
INSERT INTO categoria (nome_categoria) VALUES ('Prazo de entrega');

-- Confira o resultado:
--   SELECT * FROM categoria ORDER BY id_categoria;
