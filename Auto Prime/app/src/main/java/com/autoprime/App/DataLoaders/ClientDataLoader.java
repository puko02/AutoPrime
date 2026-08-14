package com.autoprime.App.DataLoaders;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.autoprime.App.Entities.Client;
import com.autoprime.App.Repositories.ClientRepository;

@Configuration
public class ClientDataLoader {

    @Bean
    CommandLineRunner initClientsDatabase(ClientRepository repository) {
        return args -> {
            if (repository.count() == 0) {
                Client c1 = new Client();
                c1.setNome("Mariano Rajoy");
                c1.setCidade("Foz do Iguaçu");
                c1.setCpf("12345678912");
                c1.setEmail("mariano@gmail.com");
                c1.setSenha("123456");
                c1.setEstado("Paraná");
                c1.setTelefone("459992233");
                c1.setRua("Capitao 2");
                c1.setNumero(69);
                c1.setAdmin(false);

                Client c2 = new Client();
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

                Client c3 = new Client();
                c3.setNome("Carlos Vendedor");
                c3.setCidade("Curitiba");
                c3.setCpf("55544433322");
                c3.setEmail("vendedor@gmail.com");
                c3.setSenha("123456");
                c3.setEstado("Paraná");
                c3.setTelefone("41999887766");
                c3.setRua("Av. das Vendas");
                c3.setNumero(200);
                c3.setAdmin(false);

                repository.save(c1);
                repository.save(c2);
                repository.save(c3);
            }
        };
    }
}
