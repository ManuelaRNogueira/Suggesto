

    ALTER TABLE categoria ADD COLUMN IF NOT EXISTS escopo VARCHAR(20);

    UPDATE categoria SET escopo = 'TODOS'  WHERE id_categoria = 1; -- Atendimento
    UPDATE categoria SET escopo = 'TODOS'  WHERE id_categoria = 2; -- Qualidade do produto
    UPDATE categoria SET escopo = 'TODOS'  WHERE id_categoria = 3; -- Preço
    UPDATE categoria SET escopo = 'FISICO' WHERE id_categoria = 4; -- Estrutura
    UPDATE categoria SET escopo = 'FISICO' WHERE id_categoria = 5; -- Ambiente
    UPDATE categoria SET escopo = 'FISICO' WHERE id_categoria = 6; -- Higiene
    UPDATE categoria SET escopo = 'COMIDA' WHERE id_categoria = 7; -- Cardápio
    UPDATE categoria SET escopo = 'TODOS'  WHERE id_categoria = 8; -- Outro

