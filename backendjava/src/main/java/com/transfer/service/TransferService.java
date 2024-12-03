package com.transfer.service;

import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;
import com.transfer.domain.RecurringTransfer;
import com.transfer.ports.TransferRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.HashMap;
import com.google.cloud.firestore.FieldValue;
import com.transfer.application.TransferException;

@Service
@RequiredArgsConstructor
public class TransferService {
    private final TransferRepository transferRepository;

    public void executeTransfer(RecurringTransfer transfer) {
        try {
            // Déléguer l'exécution au repository qui gère correctement la conversion phone -> userId
            transferRepository.executeTransfer(transfer);
            
            // Mettre à jour la date de dernière exécution
            transferRepository.updateLastExecuted(transfer.getId(), LocalDateTime.now());
            
        } catch (Exception e) {
            throw new TransferException("Erreur lors de l'exécution du transfert-transfert-service", e);
        }
    }
} 