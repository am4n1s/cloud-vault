package com.cloudvault.controller;

import com.cloudvault.service.StorageService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/files")
public class FileController {

    private final StorageService storageService;

    public FileController(StorageService storageService) {
        this.storageService = storageService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('VIEWER','EDITOR','ADMIN')")
    public ResponseEntity<List<String>> listFiles() {
        return ResponseEntity.ok(storageService.listFiles());
    }

    @PostMapping("/upload")
    @PreAuthorize("hasAnyRole('EDITOR','ADMIN')")
    public ResponseEntity<String> uploadFile(@RequestParam("file") MultipartFile file)
            throws IOException {
        String key = storageService.uploadFile(file);
        return ResponseEntity.ok("Uploaded: " + key);
    }

    @DeleteMapping("/{key}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<String> deleteFile(@PathVariable String key) {
        storageService.deleteFile(key);
        return ResponseEntity.ok("Deleted: " + key);
    }

    @GetMapping("/admin/secret")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<String> secretEndpoint() {
        return ResponseEntity.ok("TOP SECRET: Admin only data");
    }
}
