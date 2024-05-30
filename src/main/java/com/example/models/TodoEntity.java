package com.example.models;

import java.lang.String;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Column;

@Entity
@Table(name = "todo")
public class TodoEntity {

    @Id
    @Column(name = "id", unique = true)
    private Long id;
    
    @Column(name = "content")
    private String Content;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getContent() {
        return Content;
    }

    public void setContent(String c) {
        Content = c;
    }
}