package com.stratalyze.coffeequeue.repo;


import com.stratalyze.coffeequeue.jpa.CoffeeOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;

public interface CoffeeOrderRepository extends JpaRepository<CoffeeOrder, Long> {

    @Query("SELECT c FROM CoffeeOrder c WHERE c.status = :status ORDER BY c.createdAt ASC LIMIT 1")
    Optional<CoffeeOrder> findOldestByStatus(CoffeeOrder.Status status);

    long countByStatus(CoffeeOrder.Status status);
}
