-- Corrige a tabela `categoria` (área do feedback: Atendimento, Estrutura, etc.)
-- que estava com nomes de tipo de estabelecimento (Restaurante, Cafeteria, Padaria...)
-- em vez das áreas de feedback que fazerSugestao.html espera.
--
-- As colunas no banco sao snake_case (`id_categoria`, `nome_categoria`), seguindo
-- a estrategia de nomes padrao do Hibernate, e nao os nomes do Java (idCategoria).
--
-- Confira as colunas e o estado atual antes de rodar:
--   DESCRIBE categoria;
--   SELECT * FROM categoria ORDER BY id_categoria;
--
-- Como rodar:
--   mysql -h 143.106.241.4 -u cl204225 -p cl204225 < corrigir_categoria.sql
-- ou cole no phpMyAdmin / MySQL Workbench conectado nesse banco.

UPDATE categoria SET nome_categoria = 'Atendimento'          WHERE id_categoria = 1;
UPDATE categoria SET nome_categoria = 'Qualidade do produto' WHERE id_categoria = 2;
UPDATE categoria SET nome_categoria = 'Preço'                WHERE id_categoria = 3;
UPDATE categoria SET nome_categoria = 'Estrutura'            WHERE id_categoria = 4;
UPDATE categoria SET nome_categoria = 'Ambiente'             WHERE id_categoria = 5;
UPDATE categoria SET nome_categoria = 'Higiene'              WHERE id_categoria = 6;
UPDATE categoria SET nome_categoria = 'Cardápio'             WHERE id_categoria = 7;
UPDATE categoria SET nome_categoria = 'Outro'                WHERE id_categoria = 8;

-- Confira o resultado:
--   SELECT * FROM categoria ORDER BY id_categoria;
