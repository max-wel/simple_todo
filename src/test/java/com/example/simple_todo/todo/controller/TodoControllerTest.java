package com.example.simple_todo.todo.controller;

import com.example.simple_todo.todo.entity.Todo;
import com.example.simple_todo.todo.repository.TodoRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@WebMvcTest
@DisplayName("Todo controller unit tests")
class TodoControllerTest {
    @Autowired
    MockMvcTester mvc;

    @MockitoBean
    TodoRepository todoRepository;

    @Test
    void createTodo() {
        when(todoRepository.save(any())).thenReturn(new Todo(1L, "some task", LocalDateTime.now()));

        var result = mvc.post().uri("/todos").contentType(MediaType.APPLICATION_JSON).content("""
                {"task": "some task"}
                      """).exchange();
        assertThat(result).hasStatus(HttpStatus.CREATED);
        assertThat(result).headers().containsHeader("Location");
        verify(todoRepository, times(1)).save(any());
    }
}