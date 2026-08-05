package com.autoprime.App.Services;

import com.autoprime.App.ExceptionHandlers.GenericExceptions;
import com.autoprime.App.Entities.Car;
import com.autoprime.App.Repositories.CarRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;

@Service
public class CarService {

    @Autowired
    private  CarRepository carRepository;

    public  String save(Car car) {
        try {
            carRepository.save(car);
            return "Car salvo com sucesso";
        }
        catch (DataIntegrityViolationException ex) {
            throw new GenericExceptions.InvalidData(
                    "Dados inválidos para o car: " + ex.getMessage()
            );
        }
        catch (Exception ex) {
            throw new GenericExceptions.General(
                    "Erro inesperado ao salvar o car: " + ex.getMessage()
            );
        }
    }

    public  List<Car> findAll() {
        List<Car> cars = carRepository.findAll(Sort.by(Sort.Direction.DESC, "id"));
        if (cars.isEmpty()) {
            throw new GenericExceptions.General(
                    "Não existem cars cadastrados."
            );
        } else {
            return cars;
        }
    }

    public  Car findById(Integer id) {
        return carRepository.findById(id)
                .orElseThrow(() -> new GenericExceptions.NotFound("Car não encontrado."));
    }

    public  Car update(Integer id, Car novoCar) {
        Car update = findById(id);

        if (novoCar.getImagem() != null) {
            update.setImagem(novoCar.getImagem());
        }

        if (novoCar.getAno() != null) {
            update.setAno(novoCar.getAno());
        }
        
        if (novoCar.getChassi() != null) {
            update.setChassi(novoCar.getChassi());
        }

        if (novoCar.getMarca() != null) {
            update.setMarca(novoCar.getMarca());
        }

        if (novoCar.getModelo() != null) {
            update.setModelo(novoCar.getModelo());
        }

        if (novoCar.getPreco() != null) {
            update.setPreco(novoCar.getPreco());
        }

        if (novoCar.getQuilometragem() != null) {
            update.setQuilometragem(novoCar.getQuilometragem());
        }
        
        if (novoCar.getStock() != null) {
            update.setStock(novoCar.getStock());
        }

        return carRepository.save(update);
    }

    public  void delete(Integer id) {
        Car delete = findById(id);
        carRepository.delete(delete);
    }
}

