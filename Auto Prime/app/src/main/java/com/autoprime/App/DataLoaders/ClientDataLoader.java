package com.autoprime.App.DataLoaders;

import com.autoprime.App.Entities.Client;
import com.autoprime.App.Services.ClientService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ClientDataLoader {

    @Bean
    CommandLineRunner initClientsDatabase(ClientService clientService) {
        return args -> {
            Client c1 = new Client();
            c1.setNome("Mariano rajoy");
            c1.setCidade("Foz do Iguaçu");
            c1.setCpf("12345678912");
            c1.setEmail("mariano@gmail.com");
            c1.setEstado("Paraná");
            c1.setTelefone("459992233");
            c1.setRua("Capitao 2");
            c1.setNumero(69);
            clientService.save(c1);
        };
    }
}
