-- Uma pessoa agora pode ser funcionária de vários estabelecimentos E dona do
-- próprio ao mesmo tempo — antes só dava pra ter UM vínculo (uma coluna só em
-- usuario). Essa tabela nova (membro_equipe) substitui esse vínculo único.
--
-- Como rodar: mesmo processo dos scripts anteriores (MySQL Workbench, cola e
-- executa; ou phpMyAdmin; ou mysql -h 143.106.241.4 -u cl204225 -p cl204225
-- < adicionar_membro_equipe.sql).
--
-- IMPORTANTE: rode este script E suba o backend novo JUNTOS. O app antigo
-- (antes deste deploy) para de funcionar direito depois que o backend novo
-- subir, porque o login deixa de devolver "idGerenteEfetivo".

CREATE TABLE IF NOT EXISTS membro_equipe (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  usuario_id BIGINT NOT NULL,
  estabelecimento_id BIGINT NOT NULL,
  data_entrada DATETIME,
  UNIQUE KEY uq_membro_equipe (usuario_id, estabelecimento_id),
  FOREIGN KEY (usuario_id) REFERENCES usuario(ID_Usuario),
  FOREIGN KEY (estabelecimento_id) REFERENCES estabelecimento(id_estabelecimento)
);

-- Todo dono vira membro da própria equipe (garante que "quem trabalha aqui"
-- nunca precisa de caso especial pro dono).
INSERT IGNORE INTO membro_equipe (usuario_id, estabelecimento_id, data_entrada)
SELECT id_gerente, id_estabelecimento, NOW() FROM estabelecimento;

-- Backfill de quem já tinha vínculo pelo campo único antigo (usuario.estabelecimento_id).
INSERT IGNORE INTO membro_equipe (usuario_id, estabelecimento_id, data_entrada)
SELECT ID_Usuario, estabelecimento_id, NOW() FROM usuario WHERE estabelecimento_id IS NOT NULL;

-- Solicitação de equipe: antes só permitia 1 pedido pendente por pessoa no
-- total; passa a permitir 1 pendente por (pessoa, estabelecimento). Antes de
-- rodar o DROP abaixo, confira o nome real do índice único antigo com:
--   SHOW INDEX FROM solicitacao_equipe;
-- (procure a linha com Column_name = usuario_id e Non_unique = 0 — o nome
-- costuma ser "UK..." ou o próprio nome da coluna; ajuste o DROP INDEX se o
-- nome mostrado for diferente de "usuario_id").
ALTER TABLE solicitacao_equipe DROP INDEX usuario_id;
ALTER TABLE solicitacao_equipe ADD UNIQUE KEY uq_solicitacao_equipe (usuario_id, estabelecimento_id);

-- Não apaga a coluna antiga usuario.estabelecimento_id — fica órfã e
-- inofensiva no banco, o código simplesmente para de usá-la.

-- Confira o resultado:
--   SELECT * FROM membro_equipe ORDER BY estabelecimento_id;
--   SHOW INDEX FROM solicitacao_equipe;
