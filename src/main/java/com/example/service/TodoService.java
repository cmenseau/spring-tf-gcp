package com.example.service;
import java.util.List;

import com.example.repository.TodoRepository;
import com.example.models.TodoEntity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Service;

@Service
public class TodoService {

    @Autowired
    private TodoRepository todoRepository;

    public List<TodoEntity> queryAll() {
        return todoRepository.findAll();
    }
}