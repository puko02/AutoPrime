package com.autoprime.App.Controllers;

import com.autoprime.App.Controllers.DTO.LoginDTO;
import com.autoprime.App.Controllers.DTO.LoginResponseDTO;
import com.autoprime.App.Entities.Client;
import com.autoprime.App.Repositories.ClientRepository;
import com.autoprime.App.Services.ClientService;
import com.autoprime.App.Services.TokenService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/auth")
@CrossOrigin("*")
public class AuthController {

    @Autowired
    private ClientRepository repository;

    @Autowired
    private ClientService clientService;

    @Autowired
    private TokenService tokenService;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginDTO data) {
        Optional<Client> clientOpt = repository.findByEmail(data.getEmail());

        if (clientOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Usuário não encontrado");
        }

        Client client = clientOpt.get();

        if (!client.getSenha().equals(data.getSenha())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Senha incorreta");
        }

        String token = tokenService.generateToken(client);
        return ResponseEntity.ok(new LoginResponseDTO(token));
    }

    @PostMapping("/register")
    public ResponseEntity<String> register(@RequestBody @Valid Client data) {
        if (repository.findByEmail(data.getEmail()).isPresent()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Email já cadastrado");
        }

        String result = clientService.save(data);

        return ResponseEntity.status(HttpStatus.CREATED).body(result);
    }
}
