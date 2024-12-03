package com.transfer.scheduler;

import com.transfer.domain.RecurringTransfer;
import com.transfer.ports.TransferRepository;
import com.transfer.service.TransferService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Slf4j
@Component
@RequiredArgsConstructor
public class TransferScheduler {
    private final TransferRepository transferRepository;
    private final TransferService transferService;

    @Scheduled(cron = "0 * * * * *") // Exécution à chaque minute
    public void checkAndExecuteTransfers() {
        log.info("Vérification des transferts récurrents à {}", LocalDateTime.now());
        LocalDateTime now = LocalDateTime.now();

        var transfers = transferRepository.findActiveTransfers();
        log.info("Nombre de transferts actifs trouvés : {}", transfers.size());

        transfers.stream()
            .peek(transfer -> log.info("Vérification du transfert {} - lastExecuted: {}, startDate: {}, executionTime: {}",
                transfer.getId(),
                transfer.getLastExecuted(),
                transfer.getStartDate(),
                transfer.getExecutionTime()))
            .filter(transfer -> {
                boolean shouldExecute = transfer.shouldExecuteNow(now);
                log.info("Le transfert {} {} être exécuté",
                    transfer.getId(),
                    shouldExecute ? "doit" : "ne doit pas");
                return shouldExecute;
            })
            .forEach(this::processTransfer);
    }

    private void processTransfer(RecurringTransfer transfer) {
        try {
            transferService.executeTransfer(transfer);
            log.info("Transfert {} exécuté avec succès", transfer.getId());
        } catch (Exception e) {
            log.error("Erreur lors de l'exécution du transfert-transferScheduler {}: {}", 
                transfer.getId(), e.getMessage());
            handleTransferError(transfer, e);
        }
    }

    private void handleTransferError(RecurringTransfer transfer, Exception error) {
        transferRepository.createNotification(
            transfer.getFromUserId(),
            "Échec du transfert récurrent",
            String.format("Le transfert vers %s de %.2f FCFA a échoué: %s",
                transfer.getToPhone(),
                transfer.getAmount(),
                error.getMessage())
        );
    }
} 