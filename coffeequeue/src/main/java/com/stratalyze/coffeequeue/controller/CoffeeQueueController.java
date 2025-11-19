package com.stratalyze.coffeequeue.controller;


import com.stratalyze.coffeequeue.jpa.CoffeeOrder;
import com.stratalyze.coffeequeue.service.CoffeeOrderService;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/")
public class CoffeeQueueController {

    private final CoffeeOrderService service;

    public CoffeeQueueController(CoffeeOrderService service) {
        this.service = service;
    }

    @GetMapping("/health")
    public String health() {
        return "OK";
    }

    @PostMapping("/order")
    public CoffeeOrder order(@RequestParam String name) {
        return service.createOrder(name);
    }

    @GetMapping("/status")
    public List<CoffeeOrder> status(@RequestParam String name) {
        return service.getOrdersByName(name);
    }

    @GetMapping("/numberOfCoffees")
    public Map<String, Long> numberOfCoffees() {
        Map<String, Long> stats = new HashMap<>();
        for (CoffeeOrder.Status s : CoffeeOrder.Status.values()) {
            stats.put(s.name(), service.countByStatus(s));
        }
        return stats;
    }
}
