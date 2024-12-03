package com.transfer.ports;

import com.transfer.domain.RecurringTransfer;
import com.transfer.domain.TransactionStatus;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface TransferRepository {
    List<RecurringTransfer> findActiveTransfers();
    void updateLastExecuted(String transferId, LocalDateTime executionDate);
    void createNotification(String userId, String title, String message);
    void executeTransfer(RecurringTransfer transfer);
    void createFailedTransaction(RecurringTransfer transfer, String toUserId, String reason);
    void updateTransactionStatus(String transferId, TransactionStatus status);
    void retryFailedTransfer(String transferId);
    String findUserIdByPhone(String phone);
} 