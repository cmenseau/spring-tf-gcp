package com.example.springboot;

import java.util.List;
import java.util.ArrayList;

import com.example.models.TodoEntity;
import com.example.service.TodoService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.beans.factory.annotation.Autowired;

@RestController
public class TodoController {

    @Autowired
    private TodoService todoService;

    @GetMapping("todos")
    public List<String> getTodos() {
        List<String> lst = new ArrayList<>();
        lst.add("Hello");
        lst.add(" ");
        lst.add("world!");
        return lst;
    }

    @GetMapping("todos-db")
    public List<String> getTodosDb() {
        return todoService.queryAll().stream()
        .map(TodoEntity::getContent)
        .toList();
    }
    
}