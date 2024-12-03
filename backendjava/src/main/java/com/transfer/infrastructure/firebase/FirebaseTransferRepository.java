package com.transfer.infrastructure.firebase;

import com.google.cloud.firestore.Firestore;
import com.google.firebase.FirebaseApp;
import com.google.firebase.cloud.FirestoreClient;
import com.google.cloud.Timestamp;
import com.transfer.domain.RecurringTransfer;
import com.transfer.ports.TransferRepository;
import org.springframework.stereotype.Repository;
import org.springframework.beans.factory.annotation.Autowired;
import com.transfer.application.TransferException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.FieldValue;
import com.google.cloud.firestore.QuerySnapshot;
import com.transfer.domain.TransactionStatus;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Repository
public class FirebaseTransferRepository implements TransferRepository {
    private static final Logger logger = LoggerFactory.getLogger(FirebaseTransferRepository.class);
    private final Firestore firestore;
    private static final String COLLECTION_NAME = "recurring_transfers";

    @Autowired
    public FirebaseTransferRepository(FirebaseApp firebaseApp) {
        this.firestore = FirestoreClient.getFirestore();
    }

    @Override
    public List<RecurringTransfer> findActiveTransfers() {
        try {
            logger.debug("Recherche des transferts actifs dans Firebase");
            List<RecurringTransfer> transfers = firestore.collection(COLLECTION_NAME)
                .whereEqualTo("isActive", true)
                .get()
                .get()
                .getDocuments()
                .stream()
                .map(FirebaseTransferMapper::toRecurringTransfer)
                .collect(Collectors.toList());
            logger.debug("Nombre de transferts actifs trouvés : {}", transfers.size());
            return transfers;
        } catch (InterruptedException | ExecutionException e) {
            Thread.currentThread().interrupt();
            logger.error("Erreur lors de la récupération des transferts actifs", e);
            throw new TransferException("Impossible de récupérer les transferts actifs depuis Firebase", e);
        }
    }

    @Override
    public void updateLastExecuted(String transferId, LocalDateTime executionDate) {
        try {
            logger.debug("Mise à jour de la date d'exécution pour le transfert {} à {}", transferId, executionDate);
            firestore.collection(COLLECTION_NAME)
                .document(transferId)
                .update("lastExecuted", Timestamp.of(java.util.Date.from(
                    executionDate.atZone(ZoneId.systemDefault()).toInstant()
                )))
                .get();
            logger.debug("Date d'exécution mise à jour avec succès pour le transfert {}", transferId);
        } catch (InterruptedException | ExecutionException e) {
            Thread.currentThread().interrupt();
            logger.error("Erreur lors de la mise à jour de la date d'exécution pour le transfert {}", transferId, e);
            throw new TransferException("Impossible de mettre à jour la date d'exécution pour le transfert " + transferId, e);
        }
    }

    @Override
    public void createNotification(String userId, String title, String message) {
        try {
            logger.debug("Création d'une notification pour l'utilisateur {} avec le titre : {}", userId, title);
            firestore.collection("notifications")
                .add(FirebaseTransferMapper.toFirestoreNotification(userId, title, message))
                .get();
            logger.debug("Notification créée avec succès pour l'utilisateur {}", userId);
        } catch (InterruptedException | ExecutionException e) {
            Thread.currentThread().interrupt();
            logger.error("Erreur lors de la création de la notification pour l'utilisateur {}", userId, e);
            throw new TransferException("Impossible de créer la notification pour l'utilisateur " + userId, e);
        }
    }

    @Override
    public void executeTransfer(RecurringTransfer transfer) {
        try {
            logger.debug("Exécution du transfert {} de {} vers {}", 
                transfer.getId(), transfer.getFromUserId(), transfer.getToPhone());
            
            // Vérifier le destinataire
            String toUserId = findUserIdByPhone(transfer.getToPhone());
            if (toUserId == null) {
                createFailedTransaction(transfer, toUserId, "Destinataire non trouvé");
                return;
            }

            // Exécuter le transfert de manière atomique
            firestore.runTransaction(transaction -> {
                // Vérifier le solde de l'expéditeur
                DocumentSnapshot senderDoc = transaction.get(
                    firestore.collection("users").document(transfer.getFromUserId())
                ).get();
                
                double currentBalance = senderDoc.getDouble("balance");
                if (currentBalance < transfer.getAmount()) {
                    // Au lieu de lancer une exception, créer une transaction échouée
                    createFailedTransaction(transfer, toUserId, "Solde insuffisant");
                    return null;
                }

                // Créer la transaction avec le statut SUCCESS
                Map<String, Object> transactionData = FirebaseTransferMapper.createTransactionMap(
                    transfer, toUserId, TransactionStatus.success
                );
                
                // Mettre à jour les soldes
                transaction.update(
                    firestore.collection("users").document(transfer.getFromUserId()),
                    "balance", FieldValue.increment(-transfer.getAmount())
                );
                
                transaction.update(
                    firestore.collection("users").document(toUserId),
                    "balance", FieldValue.increment(transfer.getAmount())
                );

                // Sauvegarder la transaction
                transaction.set(
                    firestore.collection("transactions").document(transfer.getId()),
                    transactionData
                );

                return null;
            }).get();
                
            logger.debug("Transfert {} exécuté avec succès", transfer.getId());
            
        } catch (Exception e) {
            logger.error("Erreur lors de l'exécution du transfert: {}", e.getMessage());
            String toUserId = null;
            try {
                toUserId = findUserIdByPhone(transfer.getToPhone());
            } catch (Exception ex) {
                logger.error("Impossible de récupérer le toUserId: {}", ex.getMessage());
            }
            createFailedTransaction(transfer, toUserId, e.getMessage());
        }
    }

    @Override
    public String findUserIdByPhone(String phone) {
        try {
            QuerySnapshot query = firestore.collection("users")
                .whereEqualTo("phone", phone)
                .get()
                .get();
                
            if (query.isEmpty()) {
                return null;
            }
            
            return query.getDocuments().get(0).getId();
        } catch (InterruptedException | ExecutionException e) {
            Thread.currentThread().interrupt();
            throw new TransferException("Erreur lors de la recherche de l'utilisateur par téléphone", e);
        }
    }

    @Override
    public void createFailedTransaction(RecurringTransfer transfer, String toUserId, String reason) {
        try {
            Map<String, Object> transactionData = FirebaseTransferMapper.createFailedTransactionMap(
                transfer,
                toUserId,
                reason
            );
            
            firestore.collection("transactions")
                .document(transfer.getId())
                .set(transactionData)
                .get();
                
            // Créer une notification pour l'utilisateur
            createNotification(
                transfer.getFromUserId(),
                "Échec du transfert programmé",
                String.format(
                    "Le transfert de %.2f FCFA vers %s a échoué : %s",
                    transfer.getAmount(),
                    transfer.getToPhone(),
                    reason
                )
            );
                
            logger.info("Transaction échouée créée avec succès: {}", transfer.getId());
        } catch (Exception e) {
            logger.error("Erreur lors de la création de la transaction échouée: {}", e.getMessage());
            throw new TransferException("Impossible de créer la transaction échouée", e);
        }
    }

    @Override
    public void updateTransactionStatus(String transferId, TransactionStatus status) {
        try {
            Map<String, Object> updates = FirebaseTransferMapper.createStatusUpdateMap(status);
            
            firestore.collection("transactions")
                .document(transferId)
                .update(updates)
                .get();
                
            logger.info("Statut de la transaction {} mis à jour: {}", transferId, status);
        } catch (Exception e) {
            logger.error("Erreur lors de la mise à jour du statut: {}", e.getMessage());
            throw new TransferException("Impossible de mettre à jour le statut", e);
        }
    }

    @Override
    public void retryFailedTransfer(String transferId) {
        try {
            // Récupérer la transaction échouée
            DocumentSnapshot doc = firestore.collection("transactions")
                .document(transferId)
                .get()
                .get();

            if (!doc.exists()) {
                throw new TransferException("Transaction non trouvée: " + transferId);
            }

            // Vérifier si la transaction peut être relancée
            Boolean isRetryable = doc.getBoolean("isRetryable");
            Integer retryCount = doc.getLong("retryCount") != null ? 
                doc.getLong("retryCount").intValue() : 0;

            if (isRetryable == null || !isRetryable || retryCount >= 3) {
                throw new TransferException("Cette transaction ne peut plus être relancée");
            }

            // Récupérer les informations de la transaction originale
            String fromUserId = doc.getString("fromUserId");
            String toPhone = doc.getString("toPhone");
            Double amount = doc.getDouble("amount");
            String description = doc.getString("description");

            // Vérifier le destinataire
            String toUserId = findUserIdByPhone(toPhone);
            if (toUserId == null) {
                updateTransactionStatus(transferId, TransactionStatus.failed);
                createNotification(fromUserId, "Échec de la relance", 
                    "Le destinataire n'existe plus");
                return;
            }

            // Exécuter le transfert de manière atomique
            firestore.runTransaction(transaction -> {
                // Vérifier le solde de l'expéditeur
                DocumentSnapshot senderDoc = transaction.get(
                    firestore.collection("users").document(fromUserId)
                ).get();
                
                double currentBalance = senderDoc.getDouble("balance");
                if (currentBalance < amount) {
                    updateTransactionStatus(transferId, TransactionStatus.failed);
                    createNotification(fromUserId, "Échec de la relance", 
                        "Solde insuffisant");
                    return null;
                }

                // Mettre à jour les soldes
                transaction.update(
                    firestore.collection("users").document(fromUserId),
                    "balance", FieldValue.increment(-amount)
                );
                
                transaction.update(
                    firestore.collection("users").document(toUserId),
                    "balance", FieldValue.increment(amount)
                );

                // Mettre à jour le statut de la transaction
                transaction.update(
                    firestore.collection("transactions").document(transferId),
                    Map.of(
                        "status", TransactionStatus.success.name(),
                        "lastRetryAt", FieldValue.serverTimestamp(),
                        "retryCount", FieldValue.increment(1)
                    )
                );

                return null;
            }).get();

            // Notifier l'utilisateur du succès
            createNotification(
                fromUserId,
                "Transfert relancé avec succès",
                String.format("Le transfert de %.2f FCFA vers %s a été effectué", amount, toPhone)
            );
                
            logger.info("Transfert {} relancé avec succès", transferId);
            
        } catch (Exception e) {
            logger.error("Erreur lors de la relance du transfert: {}", e.getMessage());
            throw new TransferException("Impossible de relancer le transfert", e);
        }
    }
} 