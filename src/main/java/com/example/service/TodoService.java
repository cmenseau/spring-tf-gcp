package com.example.service;
import java.util.List;

import com.example.repository.TodoRepository;
import com.example.models.TodoEntity;
import org.springframework.stereotype.Service;

@Service
public class TodoService {

    private final TodoRepository todoRepository;

    public List<TodoEntity> queryAll() {
        return todoRepository.findAll();
    }

    public TodoService(TodoRepository rp) {
        todoRepository = rp;
    }
}