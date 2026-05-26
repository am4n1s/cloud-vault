package com.cloudvault.service;

import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.model.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class StorageService {

    private final AmazonS3 amazonS3;

    @Value("${minio.bucket}")
    private String bucket;

    public StorageService(AmazonS3 amazonS3) {
        this.amazonS3 = amazonS3;
    }

    @PostConstruct
    public void initBucket() {
        try {
            if (!amazonS3.doesBucketExistV2(bucket)) {
                amazonS3.createBucket(bucket);
                System.out.println("Bucket created: " + bucket);
            }
        } catch (Exception e) {
            System.out.println("Could not init bucket (MinIO may not be running): " + e.getMessage());
        }
    }

    public List<String> listFiles() {
        ObjectListing listing = amazonS3.listObjects(bucket);
        return listing.getObjectSummaries()
                .stream()
                .map(S3ObjectSummary::getKey)
                .collect(Collectors.toList());
    }

    public String uploadFile(MultipartFile file) throws IOException {
        String key = System.currentTimeMillis() + "_" + file.getOriginalFilename();
        ObjectMetadata metadata = new ObjectMetadata();
        metadata.setContentLength(file.getSize());
        metadata.setContentType(file.getContentType());
        amazonS3.putObject(bucket, key, file.getInputStream(), metadata);
        System.out.println("File uploaded: " + key);
        return key;
    }

    public void deleteFile(String key) {
        amazonS3.deleteObject(bucket, key);
        System.out.println("File deleted: " + key);
    }
}
