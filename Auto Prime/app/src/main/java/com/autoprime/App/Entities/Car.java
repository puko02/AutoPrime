    package com.autoprime.App.Entities;

    import java.util.ArrayList;
    import java.util.List;

    import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
    import jakarta.persistence.*;
    import jakarta.validation.constraints.DecimalMin;
    import jakarta.validation.constraints.NotBlank;
    import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
    import lombok.Getter;
    import lombok.Setter;
    import lombok.ToString;

    @Getter
    @Setter
    @ToString(onlyExplicitlyIncluded = true)
    @Entity
    @Table(name = "car")
    public class Car {

        @ToString.Include
        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        private Integer id;

        @ToString.Include
        @Size(max = 50, message = "A marca é muita longa")
        @NotBlank(message = "Precisa de uma marca")
        private String Marca;

        @ToString.Include
        @Size(max = 80, message = "A marca é muita longa")
        @NotBlank(message = "Precisa de um modelo")
        private String modelo;

        @ToString.Include
        @NotNull(message = "Precisa de um ano")
        @Positive(message = "O ano deve ser maior que zero")
        private Integer ano;

        @ToString.Include
        @NotNull(message = "Precisa de um preço")
        @Positive(message = "O preço deve ser maior que zero")
        private Float preco;

        @ToString.Include
        private Integer quilometragem;

        @ToString.Include
        @Size(max = 80, message = "O chassi é muita longa")
        @NotBlank(message = "Precisa de um chassi")
        private String chassi;

        @ToString.Include
        private Integer stock;

        @ToString.Include
        private String imagem;


        @PrePersist
        public void prePersist() {
            if (stock == null) {
                stock = 1;
            }
            if (quilometragem == null) {
                quilometragem = 0;
            }
        }
    }
