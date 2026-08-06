package com.autoprime.App.DataLoaders;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.autoprime.App.Entities.Client;
import com.autoprime.App.Services.ClientService;

@Configuration
public class ClientDataLoader {

    @Bean
    CommandLineRunner initClientsDatabase(ClientService clientService) {
        return args -> {
            Client c1 = new Client();
            Client c2 = new Client();
            c1.setNome("Mariano rajoy");
            c1.setCidade("Foz do Iguaçu");
            c1.setCpf("12345678912");
            c1.setEmail("mariano@gmail.com");
            c1.setSenha("123456");
            c1.setEstado("Paraná");
            c1.setTelefone("459992233");
            c1.setRua("Capitao 2");
            c1.setNumero(69);
            c1.setAdmin(false);

            c2.setNome("João Silva");
            c2.setCidade("Curitiba");
            c2.setCpf("98765432109");
            c2.setEmail("joao@gmail.com");
            c2.setSenha("123456");
            c2.setEstado("Paraná");
            c2.setTelefone("41987654321");
            c2.setRua("Rua Principal");
            c2.setNumero(100);
            c2.setAdmin(true);

            clientService.save(c1);
            clientService.save(c2);
        };
    }
}
