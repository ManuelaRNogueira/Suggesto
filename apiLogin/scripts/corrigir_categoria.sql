-- Corrige a tabela `categoria` (área do feedback: Atendimento, Estrutura, etc.)
-- que estava com nomes de tipo de estabelecimento (Restaurante, Cafeteria, Padaria...)
-- em vez das áreas de feedback que fazerSugestao.html espera.
--
-- Antes de rodar, confira o estado atual:
--   SELECT * FROM categoria ORDER BY idCategoria;
--
-- Como rodar:
--   mysql -h 143.106.241.4 -u cl204225 -p cl204225 < corrigir_categoria.sql
-- ou cole no phpMyAdmin / MySQL Workbench conectado nesse banco.

UPDATE categoria SET nomeCategoria = 'Atendimento'          WHERE idCategoria = 1;
UPDATE categoria SET nomeCategoria = 'Qualidade do produto' WHERE idCategoria = 2;
UPDATE categoria SET nomeCategoria = 'Preço'                WHERE idCategoria = 3;
UPDATE categoria SET nomeCategoria = 'Estrutura'            WHERE idCategoria = 4;
UPDATE categoria SET nomeCategoria = 'Ambiente'             WHERE idCategoria = 5;
UPDATE categoria SET nomeCategoria = 'Higiene'               WHERE idCategoria = 6;
UPDATE categoria SET nomeCategoria = 'Cardápio'              WHERE idCategoria = 7;
UPDATE categoria SET nomeCategoria = 'Outro'                 WHERE idCategoria = 8;

-- Confira o resultado:
--   SELECT * FROM categoria ORDER BY idCategoria;
