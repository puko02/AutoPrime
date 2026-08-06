package com.autoprime.App.DataLoaders;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.autoprime.App.Entities.Car;
import com.autoprime.App.Services.CarService;

@Configuration
public class CarDataLoader {

    @Bean
    CommandLineRunner initCarsDatabase(CarService carService) {
        return args -> {
            Car c1 = new Car();
            c1.setAno(2025);
            c1.setChassi("sasd");
            c1.setMarca("Wolkswagen");
            c1.setModelo("Mariano");
            c1.setPreco(69.4f);
            carService.save(c1);

            Car c2 = new Car();
            c2.setAno(2022);
            c2.setChassi("sasd");
            c2.setMarca("Toyota");
            c2.setModelo("Portal");
            c2.setPreco(27.4f);
            carService.save(c2);
        };
    }
}
