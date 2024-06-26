package com.example.springboot;

import static org.mockito.Mockito.when;

import java.util.ArrayList;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.models.TodoEntity;
import com.example.repository.TodoRepository;
import com.example.service.TodoService;

import static org.assertj.core.api.Assertions.assertThat;

@ExtendWith(MockitoExtension.class)
public class TodoServiceTest {
    
    @Mock
    private TodoRepository todoRepository;

    @InjectMocks
    private TodoService todoService;

    @Test
    void queryAll() {
        List<TodoEntity> todos = new ArrayList<>();
        todos.add(new TodoEntity("todo1"));
        when(todoRepository.findAll()).thenReturn(todos);
        List<TodoEntity> queriedTodos = todoService.queryAll();
        assertThat(queriedTodos).isEqualTo(todos);
        //assertThat(queriedTodos).containsExactlyInAnyOrderElementsOf(todos);
    }
}
