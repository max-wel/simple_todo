package com.example.simple_todo.todo.controller;

import com.example.simple_todo.todo.dto.TodoDto;
import com.example.simple_todo.todo.entity.Todo;
import com.example.simple_todo.todo.repository.TodoRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.List;

@RestController
@RequestMapping("/todos")
public class TodoController {
    private final TodoRepository todoRepository;

    public TodoController(TodoRepository todoRepository) {
        this.todoRepository = todoRepository;
    }

    @GetMapping
    public List<TodoDto> fetchTodos() {
        var todos =  todoRepository.findAll();
        return todos.stream().map(todo -> {
            TodoDto todoDto = new TodoDto();
            todoDto.setId(todo.getId());
            todoDto.setTask(todo.getTask());
            todoDto.setCreatedAt(todo.getCreatedAt());
            return todoDto;
        }).toList();
    }

    @PostMapping
    public ResponseEntity<TodoDto> createTodo(@RequestBody TodoDto todoDto, UriComponentsBuilder uriComponentsBuilder) {
        Todo todo = new Todo();
        todo.setTask(todoDto.getTask());
        var newTodo = todoRepository.save(todo);

        todoDto.setId(newTodo.getId());
        todoDto.setCreatedAt(newTodo.getCreatedAt());

        var uri = uriComponentsBuilder.path("/todos/{id}").buildAndExpand(todoDto.getId()).toUri();

        return ResponseEntity.created(uri).body(todoDto);
    }
}

