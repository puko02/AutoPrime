package com.autoprime.App.Services;

import com.autoprime.App.ExceptionHandlers.GenericExceptions;
import com.autoprime.App.Entities.Client;
import com.autoprime.App.Repositories.ClientRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class ClientService {

    @Autowired
    private  ClientRepository clientRepository;

    public  String save(Client client) {
        try {
            clientRepository.save(client);
            return "Client salvo com sucesso";
        }
        catch (DataIntegrityViolationException ex) {
            throw new GenericExceptions.InvalidData(
                    "Dados inválidos para o client: " + ex.getMessage()
            );
        }
        catch (Exception ex) {
            throw new GenericExceptions.General(
                    "Erro inesperado ao salvar o client: " + ex.getMessage()
            );
        }
    }

    public  List<Client> findAll() {
        List<Client> clients = clientRepository.findAll(Sort.by(Sort.Direction.DESC, "id"));
        if (clients.isEmpty()) {
            throw new GenericExceptions.General(
                    "Não existem clients cadastrados."
            );
        } else {
            return clients;
        }
    }

    public  Client findById(Integer id) {
        return clientRepository.findById(id)
                .orElseThrow(() -> new GenericExceptions.NotFound("Client não encontrado."));
    }

    public  Client update(Integer id, Client novoClient) {
        Client update = findById(id);

        if (novoClient.getNome() != null) {
            update.setNome(novoClient.getNome());
        }

        if (novoClient.getCpf() != null) {
            update.setCpf(novoClient.getCpf());
        }

        if (novoClient.getEmail() != null) {
            update.setEmail(novoClient.getEmail());
        }

        if (novoClient.getTelefone() != null) {
            update.setTelefone(novoClient.getTelefone());
        }

        if (novoClient.getRua() != null) {
            update.setRua(novoClient.getRua());
        }

        if (novoClient.getData() != null) {
            update.setData(novoClient.getData());
        }

        if (novoClient.getEstado() != null) {
            update.setEstado(novoClient.getEstado());
        }

        if (novoClient.getNumero() != null) {
            update.setNumero(novoClient.getNumero());
        }

        if (novoClient.getCidade() != null) {
            update.setCidade(novoClient.getCidade());
        }
        
        return clientRepository.save(update);
    }

    public  void delete(Integer id) {
        Client delete = findById(id);
        clientRepository.delete(delete);
    }
}

