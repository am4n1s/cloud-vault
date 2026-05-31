package com.cloudvault.service;

import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.client.builder.AwsClientBuilder;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDB;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder;
import com.amazonaws.services.dynamodbv2.document.DynamoDB;
import com.amazonaws.services.dynamodbv2.document.Item;
import com.amazonaws.services.dynamodbv2.document.Table;
import com.amazonaws.services.dynamodbv2.model.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
public class AuditService {

    @Value("${dynamodb.endpoint:http://localhost:8000}")
    private String dynamoEndpoint;

    @Value("${dynamodb.access-key:minioadmin}")
    private String accessKey;

    @Value("${dynamodb.secret-key:minioadmin}")
    private String secretKey;

    private DynamoDB dynamoDB;
    private AmazonDynamoDB client;
    private static final String TABLE_NAME = "AuditLog";
    private boolean initialized = false;

    @PostConstruct
    public void init() {
        new Thread(() -> {
            int attempts = 0;
            while (!initialized && attempts < 10) {
                try {
                    attempts++;
                    System.out.println("AuditService: Connecting to DynamoDB attempt " + attempts);
                    client = AmazonDynamoDBClientBuilder.standard()
                            .withEndpointConfiguration(
                                new AwsClientBuilder.EndpointConfiguration(dynamoEndpoint, "us-east-1"))
                            .withCredentials(
                                new AWSStaticCredentialsProvider(
                                    new BasicAWSCredentials(accessKey, secretKey)))
                            .build();

                    dynamoDB = new DynamoDB(client);
                    createTableIfNotExists();
                    initialized = true;
                    System.out.println("AuditService connected to DynamoDB: " + dynamoEndpoint);
                } catch (Exception e) {
                    System.out.println("AuditService: DynamoDB not ready, retrying in 10s: " + e.getMessage());
                    try { Thread.sleep(10000); } catch (InterruptedException ie) { break; }
                }
            }
        }).start();
    }

    private void createTableIfNotExists() {
        try {
            client.describeTable(TABLE_NAME);
            System.out.println("AuditLog table already exists");
        } catch (ResourceNotFoundException e) {
            client.createTable(new CreateTableRequest()
                    .withTableName(TABLE_NAME)
                    .withBillingMode(BillingMode.PAY_PER_REQUEST)
                    .withAttributeDefinitions(
                        new AttributeDefinition("id", ScalarAttributeType.S))
                    .withKeySchema(
                        new KeySchemaElement("id", KeyType.HASH)));
            System.out.println("AuditLog table created in DynamoDB");
        }
    }

    public void log(String username, String action, String endpoint, String ip) {
        if (!initialized) {
            System.out.println("AuditService: Not ready yet, skipping log");
            return;
        }
        try {
            Table table = dynamoDB.getTable(TABLE_NAME);
            Item item = new Item()
                    .withPrimaryKey("id", Instant.now().toEpochMilli() + "_" + username)
                    .withString("username", username)
                    .withString("action", action)
                    .withString("endpoint", endpoint)
                    .withString("ip", ip)
                    .withString("timestamp", Instant.now().toString());
            table.putItem(item);
        } catch (Exception e) {
            System.out.println("AuditService: Failed to log: " + e.getMessage());
        }
    }

    public List<Item> getLogs() {
        List<Item> logs = new ArrayList<>();
        if (!initialized) return logs;
        try {
            Table table = dynamoDB.getTable(TABLE_NAME);
            table.scan().forEach(logs::add);
        } catch (Exception e) {
            System.out.println("AuditService: Failed to get logs: " + e.getMessage());
        }
        return logs;
    }
}
