    package com.autoprime.App.Entities;

    import java.time.LocalDate;
    import java.util.ArrayList;
    import java.util.List;
    import java.time.LocalDate;
    import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
    import jakarta.persistence.*;
    import jakarta.validation.constraints.DecimalMin;
    import jakarta.validation.constraints.Email;
    import jakarta.validation.constraints.NotBlank;
    import jakarta.validation.constraints.NotNull;
    import jakarta.validation.constraints.PastOrPresent;
    import jakarta.validation.constraints.Positive;
    import jakarta.validation.constraints.Size;
    import lombok.Getter;
    import lombok.Setter;
    import lombok.ToString;

    @Getter
    @Setter
    @ToString(onlyExplicitlyIncluded = true)
    @Entity
    @Table(name = "client")
    public class Client {

        @ToString.Include
        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        private Integer id;

        @ToString.Include
        @Size(max = 70, message = "O nome é muito longo")
        @NotBlank(message = "Precisa de um nome")
        private String nome;

        @ToString.Include
        @NotBlank(message = "Precisa de um CPF")
        @Size(max = 15, message = "O telefone é muito longo")
        private String cpf;

        @ToString.Include
        @Email(message = "Email deve ser válido")
        private String email;

        @ToString.Include
        @NotBlank(message = "Precisa de um telefone")
        @Size(max = 15, message = "O telefone é muito longo")
        private String telefone;

        @ToString.Include
        @NotBlank(message = "Precisa de uma rua")
        private String rua;

        @ToString.Include
        @NotNull(message = "Precisa de um numero de rua")
        private Integer numero;

        @ToString.Include
        @NotBlank(message = "Precisa de uma cidade")
        private String cidade;

        @ToString.Include
        @NotBlank(message = "Precisa de um estado")
        private String estado;

        @ToString.Include
        @PastOrPresent
        private LocalDate data;


        @PrePersist
        public void prePersist() {
            if(data == null) {
                LocalDate today = LocalDate.now();
                data = today;
            }
        }
    }
