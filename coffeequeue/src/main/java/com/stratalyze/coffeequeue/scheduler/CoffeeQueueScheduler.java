package com.stratalyze.coffeequeue.scheduler;

import com.stratalyze.coffeequeue.service.CoffeeOrderService;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class CoffeeQueueScheduler {

    private final CoffeeOrderService service;

    public CoffeeQueueScheduler(CoffeeOrderService service) {
        this.service = service;
    }

    // Every 1-3 seconds: NEW → BREWING
    @Scheduled(fixedDelayString = "#{T(java.util.concurrent.ThreadLocalRandom).current().nextInt(1000, 3001)}")
    public void processOrders() {
        service.processNext();
    }

    // Every 1–3 seconds: BREWING → DONE
    @Scheduled(fixedDelayString = "#{T(java.util.concurrent.ThreadLocalRandom).current().nextInt(1000, 3001)}")
    public void finishOrders() {
        service.finishNext();
    }
}

