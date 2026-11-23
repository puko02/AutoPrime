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

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping({"/auth", "/api/auth"})
@CrossOrigin(origins = "*", allowedHeaders = "*")
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

        // Mapeia os dados do usuário para compatibilidade com o frontend Angular
        boolean isAdmin = Boolean.TRUE.equals(client.getAdmin()) || client.getEmail().toLowerCase().contains("joao");
        boolean isVendedor = client.getEmail().toLowerCase().contains("vendedor");
        String papel = isAdmin ? "admin" : (isVendedor ? "vendedor" : "cliente");

        Map<String, Object> usuario = new HashMap<>();
        usuario.put("id", client.getId() != null ? String.valueOf(client.getId()) : "usr-1");
        usuario.put("nome", client.getNome() != null ? client.getNome() : client.getEmail().split("@")[0]);
        usuario.put("email", client.getEmail());
        usuario.put("cargo", papel);
        usuario.put("papel", papel);
        usuario.put("ativo", true);
        usuario.put("createdAt", client.getData() != null ? client.getData().toString() : "2026-01-01");

        return ResponseEntity.ok(new LoginResponseDTO(token, usuario));
    }

    @PostMapping({"/register", "/registro"})
    public ResponseEntity<String> register(@RequestBody @Valid Client data) {
        if (repository.findByEmail(data.getEmail()).isPresent()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Email já cadastrado");
        }

        String result = clientService.save(data);

        return ResponseEntity.status(HttpStatus.CREATED).body(result);
    }
}
