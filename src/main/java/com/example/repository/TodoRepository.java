package com.example.repository;

import com.example.models.TodoEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

//@Repository
public interface TodoRepository extends JpaRepository<TodoEntity, Long> {
}