-- Adiciona a coluna `escopo` na tabela `categoria`, usada pra filtrar quais
-- categorias de sugestão aparecem pra cada tipo de estabelecimento (ver
-- CategoriaController): TODOS = aparece pra qualquer um, FISICO = só quem tem
-- espaço físico visitado pelo cliente, COMIDA = só quem serve comida/bebida.
--
-- O Hibernate (ddl-auto=update) já cria a coluna sozinho no próximo deploy,
-- mas roda esse script pra garantir que os dados existentes fiquem
-- preenchidos (senão fica tudo NULL e nenhuma categoria aparece filtrada).
--
-- Como rodar:
--   mysql -h 143.106.241.4 -u cl204225 -p cl204225 < adicionar_escopo_categoria.sql
-- ou cole no phpMyAdmin / MySQL Workbench conectado nesse banco.
--
-- Confira antes:
--   DESCRIBE categoria;

ALTER TABLE categoria ADD COLUMN IF NOT EXISTS escopo VARCHAR(20);

UPDATE categoria SET escopo = 'TODOS'  WHERE id_categoria = 1; -- Atendimento
UPDATE categoria SET escopo = 'TODOS'  WHERE id_categoria = 2; -- Qualidade do produto
UPDATE categoria SET escopo = 'TODOS'  WHERE id_categoria = 3; -- Preço
UPDATE categoria SET escopo = 'FISICO' WHERE id_categoria = 4; -- Estrutura
UPDATE categoria SET escopo = 'FISICO' WHERE id_categoria = 5; -- Ambiente
UPDATE categoria SET escopo = 'FISICO' WHERE id_categoria = 6; -- Higiene
UPDATE categoria SET escopo = 'COMIDA' WHERE id_categoria = 7; -- Cardápio
UPDATE categoria SET escopo = 'TODOS'  WHERE id_categoria = 8; -- Outro

-- Confira o resultado:
--   SELECT * FROM categoria ORDER BY id_categoria;
