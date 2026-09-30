package com.example.simple_todo.todo.integration_tests;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.Network;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.mysql.MySQLContainer;

import static io.restassured.RestAssured.*;

@Testcontainers
class TodoApiTest {
    String imageName = System.getProperty("app.image", "simple_todo:latest");
    Network network = Network.newNetwork();

    @Container
    MySQLContainer mysql = new MySQLContainer("mysql:8.4")
            .withNetwork(network)
            .withNetworkAliases("mysql");

    @Container
    GenericContainer<?> container = new GenericContainer<>(imageName)
            .withExposedPorts(8080)
            .withNetwork(network)
            .withEnv("SPRING_DATASOURCE_URL", "jdbc:mysql://mysql:3306/test")
            .withEnv("SPRING_DATASOURCE_USERNAME", mysql.getUsername())
            .withEnv("SPRING_DATASOURCE_PASSWORD", mysql.getPassword())
            .dependsOn(mysql);

    @BeforeEach
    void setUp() {
        baseURI = "http://localhost";
        port = container.getMappedPort(8080);
        System.out.println("Starting test container on port " + port);
    }

    @Test
    void getTodo() {
        given()
                .when()
                .get("/todos")
                .then()
                .statusCode(200);
    }
}