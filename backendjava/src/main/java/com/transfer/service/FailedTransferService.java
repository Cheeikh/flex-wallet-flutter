package com.transfer.service;

import com.transfer.domain.RecurringTransfer;
import com.transfer.domain.TransactionStatus;
import com.transfer.ports.FailedTransferHandler;
import com.transfer.ports.TransferRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class FailedTransferService implements FailedTransferHandler {
    private final TransferRepository transferRepository;

    @Override
    public void handleFailedTransfer(RecurringTransfer transfer, String reason) {
        try {
            // Rechercher le toUserId à partir du numéro de téléphone
            String toUserId = transferRepository.findUserIdByPhone(transfer.getToPhone());
            
            // Créer une transaction avec le statut FAILED
            transferRepository.createFailedTransaction(transfer, toUserId, reason);
            
            // Créer une notification pour l'utilisateur
            String message = String.format(
                "Le transfert programmé de %s FCFA vers %s a échoué : %s",
                transfer.getAmount(),
                transfer.getToPhone(),
                reason
            );
            
            transferRepository.createNotification(
                transfer.getFromUserId(),
                "Échec du transfert programmé",
                message
            );
            
            log.info("Transfert échoué géré avec succès: {}", transfer.getId());
        } catch (Exception e) {
            log.error("Erreur lors de la gestion du transfert échoué: {}", e.getMessage());
        }
    }

    @Override
    public void retryTransfer(String transferId) {
        try {
            transferRepository.updateTransactionStatus(transferId, TransactionStatus.retrying);
            // Logique de relance à implémenter
        } catch (Exception e) {
            log.error("Erreur lors de la relance du transfert: {}", e.getMessage());
        }
    }

    @Override
    public void cancelFailedTransfer(String transferId) {
        try {
            transferRepository.updateTransactionStatus(transferId, TransactionStatus.canceled);
        } catch (Exception e) {
            log.error("Erreur lors de l'annulation du transfert: {}", e.getMessage());
        }
    }
} 