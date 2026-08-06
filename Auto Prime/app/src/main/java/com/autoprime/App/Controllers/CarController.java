package com.autoprime.App.Controllers;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.autoprime.App.Entities.Car;
import com.autoprime.App.Services.CarService;

import jakarta.validation.Valid;

@SuppressWarnings("unused")
@RestController
@RequestMapping("/api/car")
@CrossOrigin("*")
public class CarController {

    @Autowired
    private CarService carService;

    //@PreAuthorize("hasRole('ADMIN')")
    @PostMapping
    public ResponseEntity<String> save(@RequestBody @Valid Car car) {
        String result = this.carService.save(car);
        return new ResponseEntity<>(result, HttpStatus.OK);
    }

    @GetMapping
    public ResponseEntity<List<Car>> findAll() {
        var result = carService.findAll();
        return new ResponseEntity<>(result, HttpStatus.OK);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Car> findById(@PathVariable Integer id) {
        var result = carService.findById(id);
        return new ResponseEntity<>(result, HttpStatus.OK);
    }

    //@PreAuthorize("hasRole('ADMIN')")
    @PutMapping("/{id}")
    public ResponseEntity<String> update(@PathVariable Integer id, @RequestBody @Valid Car carUpdate) {
        carService.update(id, carUpdate);
        return new ResponseEntity<>("Car atualizado com sucesso.", HttpStatus.OK);
    }

    //@PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Integer id) {
        carService.delete(id);
        return ResponseEntity.noContent().build(); // status 204
    }

}