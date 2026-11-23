package com.autoprime.App.Controllers.DTO;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record LoginResponseDTO(String token, Object usuario) {
    public LoginResponseDTO(String token) {
        this(token, null);
    }
}
