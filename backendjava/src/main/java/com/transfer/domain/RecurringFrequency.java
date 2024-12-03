package com.transfer.domain;

public enum RecurringFrequency {
    daily,
    weekly,
    monthly,
    yearly;

    public static RecurringFrequency fromString(String value) {
        try {
            return valueOf(value.toLowerCase());
        } catch (Exception e) {
            return monthly; // Valeur par défaut
        }
    }
} 