package com.autoprime.App.DataLoaders;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.autoprime.App.Entities.Car;
import com.autoprime.App.Repositories.CarRepository;
import com.autoprime.App.Services.CarService;

@Configuration
public class CarDataLoader {

    @Bean
    CommandLineRunner initCarsDatabase(CarRepository carRepository, CarService carService) {
        return args -> {
            if (carRepository.count() == 0) {
                Car c1 = new Car();
                c1.setAno(2025);
                c1.setChassi("AUTOPRIME-001");
                c1.setMarca("Volkswagen");
                c1.setModelo("Golf GTI");
                c1.setPreco(185000.0f);
                c1.setQuilometragem(15000);
                c1.setStock(2);
                carService.save(c1);

                Car c2 = new Car();
                c2.setAno(2024);
                c2.setChassi("AUTOPRIME-002");
                c2.setMarca("Toyota");
                c2.setModelo("Corolla GR");
                c2.setPreco(210000.0f);
                c2.setQuilometragem(5000);
                c2.setStock(3);
                carService.save(c2);
            }
        };
    }
}
