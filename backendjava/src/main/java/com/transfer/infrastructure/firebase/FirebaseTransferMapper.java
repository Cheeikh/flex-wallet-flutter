package com.transfer.infrastructure.firebase;

import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.Timestamp;
import com.transfer.domain.RecurringFrequency;
import com.transfer.domain.RecurringTransfer;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.transfer.application.TransferException;
import java.time.ZonedDateTime;
import java.util.HashMap;
import com.google.cloud.firestore.FieldValue;
import com.transfer.domain.TransactionStatus;
import com.transfer.domain.TransactionType;

public class FirebaseTransferMapper {
    private static final Logger logger = LoggerFactory.getLogger(FirebaseTransferMapper.class);
    
    public static RecurringTransfer toRecurringTransfer(DocumentSnapshot document) {
        try {
            Map<String, Object> data = document.getData();
            if (data == null) {
                throw new IllegalArgumentException("Document data is null for ID: " + document.getId());
            }

            logger.debug("Converting document {} to RecurringTransfer", document.getId());
            
            // Vérification des champs obligatoires
            validateRequiredFields(document);

            RecurringTransfer transfer = RecurringTransfer.builder()
                .id(document.getId())
                .fromUserId(document.getString("fromUserId"))
                .toPhone(document.getString("toPhone"))
                .amount(document.getDouble("amount"))
                .frequency(RecurringFrequency.fromString(document.getString("frequency")))
                .startDate(timestampToLocalDateTime(document.getTimestamp("startDate")))
                .executionTime(parseExecutionTime(data.get("executionTime")))
                .endDate(document.getTimestamp("endDate") != null ? 
                        timestampToLocalDateTime(document.getTimestamp("endDate")) : null)
                .description(document.getString("description"))
                .lastExecuted(document.getTimestamp("lastExecuted") != null ? 
                        timestampToLocalDateTime(document.getTimestamp("lastExecuted")) : null)
                .isActive(document.getBoolean("isActive"))
                .build();

            logger.debug("Successfully converted document {} to RecurringTransfer", document.getId());
            return transfer;
        } catch (Exception e) {
            logger.error("Erreur lors de la conversion du document {} en RecurringTransfer", document.getId(), e);
            throw new TransferException("Impossible de convertir le document Firebase en RecurringTransfer", e);
        }
    }

    private static void validateRequiredFields(DocumentSnapshot document) {
        StringBuilder missingFields = new StringBuilder();
        
        checkField(document, "fromUserId", missingFields);
        checkField(document, "toPhone", missingFields);
        checkField(document, "amount", missingFields);
        checkField(document, "frequency", missingFields);
        checkField(document, "startDate", missingFields);
        checkField(document, "executionTime", missingFields);
        
        if (missingFields.length() > 0) {
            throw new IllegalArgumentException("Champs manquants dans le document: " + missingFields);
        }
    }

    private static void checkField(DocumentSnapshot document, String fieldName, StringBuilder missingFields) {
        if (!document.contains(fieldName) || document.get(fieldName) == null) {
            if (missingFields.length() > 0) {
                missingFields.append(", ");
            }
            missingFields.append(fieldName);
        }
    }

    private static LocalDateTime timestampToLocalDateTime(Timestamp timestamp) {
        if (timestamp == null) {
            throw new IllegalArgumentException("Timestamp ne peut pas être null");
        }
        return LocalDateTime.ofInstant(
            timestamp.toDate().toInstant(),
            ZoneId.systemDefault()
        );
    }

    private static LocalTime parseExecutionTime(Object executionTime) {
        if (executionTime == null) {
            throw new IllegalArgumentException("executionTime ne peut pas être null");
        }
        
        if (executionTime instanceof Map) {
            try {
                @SuppressWarnings("unchecked")
                Map<String, Long> timeMap = (Map<String, Long>) executionTime;
                
                Long hour = timeMap.get("hour");
                Long minute = timeMap.get("minute");
                
                if (hour == null || minute == null) {
                    throw new IllegalArgumentException("Les champs hour et minute sont requis dans executionTime");
                }
                
                return LocalTime.of(hour.intValue(), minute.intValue());
            } catch (Exception e) {
                logger.error("Erreur lors du parsing de executionTime: {}", executionTime, e);
                throw new IllegalArgumentException("Format invalide pour executionTime", e);
            }
        }
        throw new IllegalArgumentException("executionTime doit être une Map");
    }

    public static Map<String, Object> toFirestore(RecurringTransfer transfer) {
        return Map.of(
            "fromUserId", transfer.getFromUserId(),
            "toPhone", transfer.getToPhone(),
            "amount", transfer.getAmount(),
            "frequency", transfer.getFrequency().name(),
            "startDate", Timestamp.of(java.util.Date.from(transfer.getStartDate()
                .atZone(ZoneId.systemDefault()).toInstant())),
            "executionTime", Map.of(
                "hour", transfer.getExecutionTime().getHour(),
                "minute", transfer.getExecutionTime().getMinute()
            ),
            "endDate", transfer.getEndDate() != null ? 
                Timestamp.of(java.util.Date.from(transfer.getEndDate()
                    .atZone(ZoneId.systemDefault()).toInstant())) : null,
            "description", transfer.getDescription(),
            "lastExecuted", transfer.getLastExecuted() != null ? 
                Timestamp.of(java.util.Date.from(transfer.getLastExecuted()
                    .atZone(ZoneId.systemDefault()).toInstant())) : null,
            "isActive", transfer.isActive()
        );
    }

    public static Map<String, Object> toFirestoreNotification(String userId, String title, String message) {
        return Map.of(
            "userId", userId,
            "title", title,
            "message", message,
            "createdAt", Timestamp.of(java.util.Date.from(
                LocalDateTime.now().atZone(ZoneId.systemDefault()).toInstant()
            )),
            "read", false
        );
    }

    public static Map<String, Object> createTransactionMap(
        RecurringTransfer transfer, 
        String toUserId, 
        TransactionStatus status
    ) {
        Map<String, Object> data = new HashMap<>();
        data.put("id", transfer.getId());
        data.put("fromUserId", transfer.getFromUserId());
        data.put("toUserId", toUserId);
        data.put("amount", transfer.getAmount());
        data.put("type", "recurringTransfer");
        data.put("status", status.name());
        data.put("createdAt", FieldValue.serverTimestamp());
        data.put("description", transfer.getDescription());
        data.put("isCancelable", true);
        data.put("cancelableUntil", null);
        data.put("canceledAt", null);
        data.put("failureReason", null);
        data.put("retryCount", 0);
        data.put("lastRetryAt", null);
        return data;
    }

    public static Map<String, Object> createTransactionMap(
        RecurringTransfer transfer, 
        String toUserId
    ) {
        return createTransactionMap(transfer, toUserId, TransactionStatus.pending);
    }

    public static void validateTransaction(Map<String, Object> transaction) {
        StringBuilder missingFields = new StringBuilder();
        
        String[] requiredFields = {
            "id", "fromUserId", "toUserId", "amount", "type", "createdAt",
            "status", "isCancelable"
        };
        
        for (String field : requiredFields) {
            if (!transaction.containsKey(field) || transaction.get(field) == null) {
                if (missingFields.length() > 0) {
                    missingFields.append(", ");
                }
                missingFields.append(field);
            }
        }
        
        if (missingFields.length() > 0) {
            throw new IllegalArgumentException("Champs manquants dans la transaction: " + missingFields);
        }
        
        // Validation du type de transaction
        String type = (String) transaction.get("type");
        try {
            TransactionType.valueOf(type);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Type de transaction invalide: " + type);
        }
        
        // Validation du montant
        Object amount = transaction.get("amount");
        if (!(amount instanceof Number)) {
            throw new IllegalArgumentException("Le montant doit être un nombre");
        }
        
        // Validation des timestamps
        validateTimestamp(transaction, "createdAt");
        validateTimestamp(transaction, "cancelableUntil");
        validateTimestamp(transaction, "canceledAt");
        validateTimestamp(transaction, "lastRetryAt");
    }

    private static void validateTimestamp(Map<String, Object> transaction, String field) {
        Object value = transaction.get(field);
        if (value != null && !(value instanceof Timestamp)) {
            throw new IllegalArgumentException(
                String.format("Le champ %s doit être un Timestamp", field));
        }
    }

    public static Map<String, Object> createFailedTransactionMap(
        RecurringTransfer transfer,
        String toUserId,
        String reason
    ) {
        Map<String, Object> data = new HashMap<>();
        data.put("id", transfer.getId());
        data.put("fromUserId", transfer.getFromUserId());
        data.put("toUserId", toUserId);
        data.put("amount", transfer.getAmount());
        data.put("type", "recurringTransfer");
        data.put("status", TransactionStatus.failed.name());
        data.put("createdAt", FieldValue.serverTimestamp());
        data.put("description", transfer.getDescription());
        data.put("isCancelable", false);
        data.put("failureReason", reason);
        data.put("retryCount", 0);
        data.put("lastRetryAt", null);
        return data;
    }

    public static Map<String, Object> createStatusUpdateMap(TransactionStatus status) {
        Map<String, Object> updates = new HashMap<>();
        updates.put("status", status.name());
        
        if (status == TransactionStatus.retrying) {
            updates.put("lastRetryAt", Timestamp.of(java.util.Date.from(
                ZonedDateTime.now().toInstant()
            )));
            updates.put("retryCount", FieldValue.increment(1));
        }

        return updates;
    }
} 