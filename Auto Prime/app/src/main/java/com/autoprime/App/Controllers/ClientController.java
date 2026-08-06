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

import com.autoprime.App.Entities.Client;
import com.autoprime.App.Services.ClientService;

import jakarta.validation.Valid;

@SuppressWarnings("unused")
@RestController
@RequestMapping("/api/client")
public class ClientController {

    @Autowired
    private ClientService clientService;

    //@PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/save")
    public ResponseEntity<String> save(@RequestBody @Valid Client client) {
        String result = this.clientService.save(client);
        return new ResponseEntity<>(result, HttpStatus.OK);
    }

    @GetMapping("/findAll")
    public ResponseEntity<List<Client>> findAll() {
        var result = clientService.findAll();
        return new ResponseEntity<>(result, HttpStatus.OK);
    }

    @GetMapping("/findById/{id}")
    public ResponseEntity<Client> findById(@PathVariable Integer id) {
        var result = clientService.findById(id);
        return new ResponseEntity<>(result, HttpStatus.OK);
    }

    //@PreAuthorize("hasRole('ADMIN')")
    @PutMapping("/update/{id}")
    public ResponseEntity<String> update(@PathVariable Integer id, @RequestBody @Valid Client clientUpdate) {
        clientService.update(id, clientUpdate);
        return new ResponseEntity<>("Client atualizado com sucesso.", HttpStatus.OK);
    }

    //@PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/delete/{id}")
    public ResponseEntity<?> delete(@PathVariable Integer id) {
        clientService.delete(id);
        return ResponseEntity.noContent().build(); // status 204
    }

}