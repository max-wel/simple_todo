package com.example.simple_todo.todo.repository;

import com.example.simple_todo.todo.entity.Todo;
import org.springframework.data.repository.ListCrudRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TodoRepository extends ListCrudRepository<Todo, Long> {
}
