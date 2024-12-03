package com.transfer.ports;

import com.transfer.domain.RecurringTransfer;

public interface FailedTransferHandler {
    void handleFailedTransfer(RecurringTransfer transfer, String reason);
    void retryTransfer(String transferId);
    void cancelFailedTransfer(String transferId);
} 