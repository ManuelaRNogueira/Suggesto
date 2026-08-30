

ALTER TABLE estabelecimento ADD COLUMN data_cadastro DATETIME;
ALTER TABLE recompensa ADD COLUMN data_cadastro DATETIME;

UPDATE estabelecimento SET data_cadastro = '2024-01-01 00:00:00' WHERE data_cadastro IS NULL;
UPDATE recompensa SET data_cadastro = '2024-01-01 00:00:00' WHERE data_cadastro IS NULL;

