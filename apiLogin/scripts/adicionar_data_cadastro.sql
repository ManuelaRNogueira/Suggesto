-- Data de cadastro de estabelecimento e recompensa — usada pra saber quem é
-- "novo" na página de notificações do cliente (ver notificacoesCli.js).
-- Puramente aditivo, mesmo padrão dos scripts anteriores.
--
-- Depois de adicionar as colunas, preenche os registros que já existem com
-- uma data antiga (2024-01-01), pra eles não aparecerem todos de uma vez
-- como "novidade" assim que a coluna existir. Só quem for cadastrado a
-- partir de agora entra com a data de verdade.
--
-- Como rodar: mesmo processo dos scripts anteriores (MySQL Workbench, cola e
-- executa; ou phpMyAdmin; ou mysql -h 143.106.241.4 -u cl204225 -p cl204225
-- < adicionar_data_cadastro.sql).

ALTER TABLE estabelecimento ADD COLUMN data_cadastro DATETIME;
ALTER TABLE recompensa ADD COLUMN data_cadastro DATETIME;

UPDATE estabelecimento SET data_cadastro = '2024-01-01 00:00:00' WHERE data_cadastro IS NULL;
UPDATE recompensa SET data_cadastro = '2024-01-01 00:00:00' WHERE data_cadastro IS NULL;

-- Confira o resultado:
--   DESCRIBE estabelecimento;
--   DESCRIBE recompensa;
--   SELECT id_estabelecimento, nome_estabelecimento, data_cadastro FROM estabelecimento LIMIT 5;
