

CREATE TABLE IF NOT EXISTS membro_equipe (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  usuario_id BIGINT NOT NULL,
  estabelecimento_id BIGINT NOT NULL,
  data_entrada DATETIME,
  UNIQUE KEY uq_membro_equipe (usuario_id, estabelecimento_id),
  FOREIGN KEY (usuario_id) REFERENCES usuario(ID_Usuario),
  FOREIGN KEY (estabelecimento_id) REFERENCES estabelecimento(id_estabelecimento)
);

INSERT IGNORE INTO membro_equipe (usuario_id, estabelecimento_id, data_entrada)
SELECT id_gerente, id_estabelecimento, NOW() FROM estabelecimento;

INSERT IGNORE INTO membro_equipe (usuario_id, estabelecimento_id, data_entrada)
SELECT ID_Usuario, estabelecimento_id, NOW() FROM usuario WHERE estabelecimento_id IS NOT NULL;

ALTER TABLE solicitacao_equipe DROP INDEX usuario_id;
ALTER TABLE solicitacao_equipe ADD UNIQUE KEY uq_solicitacao_equipe (usuario_id, estabelecimento_id);

