package com.example.simple_todo.todo.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
public class TodoDto {
    private Long id;
    private String task;
    private LocalDateTime createdAt;
}
