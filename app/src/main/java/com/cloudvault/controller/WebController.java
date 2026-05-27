package com.cloudvault.controller;

import com.amazonaws.services.dynamodbv2.document.Item;
import com.cloudvault.service.AuditService;
import com.cloudvault.service.StorageService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Controller
public class WebController {

    private final StorageService storageService;
    private final AuditService auditService;

    public WebController(StorageService storageService, AuditService auditService) {
        this.storageService = storageService;
        this.auditService = auditService;
    }

    @GetMapping("/login")
    public String loginPage() {
        return "login";
    }

    @GetMapping("/files")
    @PreAuthorize("hasAnyRole('VIEWER','EDITOR','ADMIN')")
    public String filesPage(Model model, Authentication auth, HttpServletRequest request) {
        auditService.log(auth.getName(), "ACCESS", "/files", request.getRemoteAddr());
        model.addAttribute("files", storageService.listFiles());
        model.addAttribute("username", auth.getName());
        model.addAttribute("role", auth.getAuthorities().iterator().next().getAuthority());
        return "files";
    }

    @PostMapping("/files/upload")
    @PreAuthorize("hasAnyRole('EDITOR','ADMIN')")
    public String uploadFile(@RequestParam("file") MultipartFile file,
                             RedirectAttributes redirectAttributes,
                             Authentication auth,
                             HttpServletRequest request) {
        try {
            String key = storageService.uploadFile(file);
            auditService.log(auth.getName(), "UPLOAD", "/files/upload", request.getRemoteAddr());
            redirectAttributes.addFlashAttribute("success", "File uploaded: " + key);
        } catch (IOException e) {
            redirectAttributes.addFlashAttribute("error", "Upload error: " + e.getMessage());
        }
        return "redirect:/files";
    }

    @PostMapping("/files/delete")
    @PreAuthorize("hasRole('ADMIN')")
    public String deleteFile(@RequestParam("key") String key,
                             RedirectAttributes redirectAttributes,
                             Authentication auth,
                             HttpServletRequest request) {
        storageService.deleteFile(key);
        auditService.log(auth.getName(), "DELETE", "/files/delete", request.getRemoteAddr());
        redirectAttributes.addFlashAttribute("success", "File deleted: " + key);
        return "redirect:/files";
    }

    @GetMapping("/admin/secret")
    @PreAuthorize("hasRole('ADMIN')")
    public String secretPage(Model model, Authentication auth, HttpServletRequest request) {
        auditService.log(auth.getName(), "SECRET_ACCESS", "/admin/secret", request.getRemoteAddr());
        model.addAttribute("username", auth.getName());
        model.addAttribute("role", auth.getAuthorities().iterator().next().getAuthority());
        return "secret";
    }

    @GetMapping("/admin/logs")
    @PreAuthorize("hasRole('ADMIN')")
    public String logsPage(Model model, Authentication auth) {
        List<Map<String, String>> logs = auditService.getLogs()
                .stream()
                .map(item -> Map.of(
                        "username", item.getString("username") != null ? item.getString("username") : "",
                        "action",   item.getString("action")   != null ? item.getString("action")   : "",
                        "endpoint", item.getString("endpoint") != null ? item.getString("endpoint") : "",
                        "ip",       item.getString("ip")       != null ? item.getString("ip")       : "",
                        "timestamp",item.getString("timestamp")!= null ? item.getString("timestamp"): ""
                ))
                .sorted((a, b) -> b.get("timestamp").compareTo(a.get("timestamp")))
                .collect(Collectors.toList());

        model.addAttribute("logs", logs);
        model.addAttribute("username", auth.getName());
        model.addAttribute("role", auth.getAuthorities().iterator().next().getAuthority());
        return "logs";
    }
}
