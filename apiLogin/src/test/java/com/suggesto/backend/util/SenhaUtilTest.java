package com.suggesto.backend.util;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class SenhaUtilTest {

    @Test
    void aceitaSenhaComLetraNumeroEEspecial() {
        assertThat(SenhaUtil.validar("suggesto#2026")).isNull();
        assertThat(SenhaUtil.validar("Ção_1234")).isNull();
    }

    @Test
    void recusaSenhaFraca() {
        assertThat(SenhaUtil.validar(null)).isNotNull();
        assertThat(SenhaUtil.validar("   ")).isNotNull();
        assertThat(SenhaUtil.validar("a#1")).contains("8 caracteres");
        assertThat(SenhaUtil.validar("semnumero#")).contains("caractere especial");
        assertThat(SenhaUtil.validar("semespecial1")).contains("caractere especial");
        assertThat(SenhaUtil.validar("12345678#")).contains("caractere especial");
        assertThat(SenhaUtil.validar("a#1".repeat(30))).contains("no máximo");
    }
}
