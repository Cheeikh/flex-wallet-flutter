package com.transfer.domain;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Data
@Builder
public class RecurringTransfer {
    private String id;
    private String fromUserId;
    private String toPhone;
    private double amount;
    private RecurringFrequency frequency;
    
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime startDate;
    
    @JsonFormat(pattern = "HH:mm")
    private LocalTime executionTime;
    
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime endDate;
    
    private String description;
    
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime lastExecuted;
    
    private boolean isActive;

    public boolean shouldExecuteNow(LocalDateTime now) {
        if (!isActive || now.isBefore(startDate)) {
            return false;
        }

        if (endDate != null && now.isAfter(endDate)) {
            return false;
        }

        if (now.getHour() != executionTime.getHour() || 
            now.getMinute() != executionTime.getMinute()) {
            return false;
        }

        LocalDateTime lastExec = lastExecuted != null ? lastExecuted : startDate.minusDays(1);

        return switch (frequency) {
            case daily -> now.toLocalDate().isAfter(lastExec.toLocalDate());
            case weekly -> now.toLocalDate().minusDays(7).isAfter(lastExec.toLocalDate()) &&
                          now.getDayOfWeek() == startDate.getDayOfWeek();
            case monthly -> (now.getYear() > lastExec.getYear() ||
                           (now.getYear() == lastExec.getYear() && 
                            now.getMonthValue() > lastExec.getMonthValue())) &&
                           now.getDayOfMonth() == startDate.getDayOfMonth();
            case yearly -> now.getYear() > lastExec.getYear() &&
                          now.getMonthValue() == startDate.getMonthValue() &&
                          now.getDayOfMonth() == startDate.getDayOfMonth();
        };
    }
} 