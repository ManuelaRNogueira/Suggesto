-- Só referência: o Hibernate (ddl-auto=update) já cria esta tabela sozinho no
-- primeiro boot depois do deploy. Rode à mão apenas se ela não aparecer.
CREATE TABLE IF NOT EXISTS token_redefinicao_senha (
    id BIGINT NOT NULL AUTO_INCREMENT,
    id_usuario BIGINT NOT NULL,
    token_hash VARCHAR(64) NOT NULL,
    criado_em DATETIME(6) NOT NULL,
    expira_em DATETIME(6) NOT NULL,
    usado BIT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_token_redefinicao_senha_hash (token_hash),
    CONSTRAINT fk_token_redefinicao_senha_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (ID_Usuario)
);
