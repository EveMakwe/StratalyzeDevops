package com.stratalyze.coffeequeue.service;

import com.stratalyze.coffeequeue.jpa.CoffeeOrder;
import com.stratalyze.coffeequeue.repo.CoffeeOrderRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Random;

@Service
public class CoffeeOrderService {

    private final CoffeeOrderRepository repository;
    private final Random random = new Random();

    public CoffeeOrderService(CoffeeOrderRepository repository) {
        this.repository = repository;
    }

    public CoffeeOrder createOrder(String name) {
        CoffeeOrder order = new CoffeeOrder(name);
        return repository.save(order);
    }

    public List<CoffeeOrder> getOrdersByName(String name) {
        return repository.findAll()
                .stream()
                .filter(o -> o.getCustomerName().equalsIgnoreCase(name))
                .toList();
    }

    public long countByStatus(CoffeeOrder.Status status) {
        return repository.countByStatus(status);
    }

    @Transactional
    public void processNext() {
        // Move oldest NEW -> BREWING
        repository.findOldestByStatus(CoffeeOrder.Status.NEW).ifPresent(o -> {
            o.setStatus(CoffeeOrder.Status.BREWING);
            repository.save(o);
        });
    }

    @Transactional
    public void finishNext() {
        // Move oldest BREWING -> DONE
        repository.findOldestByStatus(CoffeeOrder.Status.BREWING).ifPresent(o -> {
            o.setStatus(CoffeeOrder.Status.DONE);
            repository.save(o);
        });
    }

    // Generate random delays between min and max
    public int randomBetween(int min, int max) {
        return random.nextInt(max - min + 1) + min;
    }
}

