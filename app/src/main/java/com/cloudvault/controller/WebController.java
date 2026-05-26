package com.cloudvault.controller;

import com.cloudvault.service.StorageService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.io.IOException;

@Controller
public class WebController {

    private final StorageService storageService;

    public WebController(StorageService storageService) {
        this.storageService = storageService;
    }

    @GetMapping("/login")
    public String loginPage() {
        return "login";
    }

    @GetMapping("/files")
    @PreAuthorize("hasAnyRole('VIEWER','EDITOR','ADMIN')")
    public String filesPage(Model model, Authentication auth) {
        model.addAttribute("files", storageService.listFiles());
        model.addAttribute("username", auth.getName());
        model.addAttribute("role", auth.getAuthorities().iterator().next().getAuthority());
        return "files";
    }

    @PostMapping("/files/upload")
    @PreAuthorize("hasAnyRole('EDITOR','ADMIN')")
    public String uploadFile(@RequestParam("file") MultipartFile file,
                             RedirectAttributes redirectAttributes) {
        try {
            String key = storageService.uploadFile(file);
            redirectAttributes.addFlashAttribute("success", "Файл загружен: " + key);
        } catch (IOException e) {
            redirectAttributes.addFlashAttribute("error", "Ошибка загрузки: " + e.getMessage());
        }
        return "redirect:/files";
    }

    @PostMapping("/files/delete")
    @PreAuthorize("hasRole('ADMIN')")
    public String deleteFile(@RequestParam("key") String key,
                             RedirectAttributes redirectAttributes) {
        storageService.deleteFile(key);
        redirectAttributes.addFlashAttribute("success", "Файл удалён: " + key);
        return "redirect:/files";
    }

    @GetMapping("/admin/secret")
    @PreAuthorize("hasRole('ADMIN')")
    public String secretPage(Model model, Authentication auth) {
        model.addAttribute("username", auth.getName());
        model.addAttribute("role", auth.getAuthorities().iterator().next().getAuthority());
        return "secret";
    }
}
