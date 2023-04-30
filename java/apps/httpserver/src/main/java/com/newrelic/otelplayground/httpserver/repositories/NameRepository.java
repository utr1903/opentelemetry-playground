package com.newrelic.otelplayground.httpserver.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.newrelic.otelplayground.httpserver.entities.Name;

@Repository
public interface NameRepository extends JpaRepository<Name, Long> {

}
