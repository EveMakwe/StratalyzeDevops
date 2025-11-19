package com.stratalyze.coffeequeue.jpa;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "coffee_orders")
public class CoffeeOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "customername", nullable = false)
    private String customerName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status;

    @Column(name = "createdat", nullable = false)
    private LocalDateTime createdAt;
    @Column(name = "updatedat", nullable = false)
    private LocalDateTime updatedAt;

    public enum Status {
        NEW,
        BREWING,
        DONE
    }

    // Constructors
    public CoffeeOrder() {
    }

    public CoffeeOrder(String customerName) {
        this.customerName = customerName;
        this.status = Status.NEW;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    // Getters & Setters
    public Long getId() {
        return id;
    }

    public String getCustomerName() {
        return customerName;
    }

    public Status getStatus() {
        return status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setStatus(Status status) {
        this.status = status;
        this.updatedAt = LocalDateTime.now();
    }
}
