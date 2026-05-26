package com.cloudvault.config;

import com.cloudvault.model.Role;
import com.cloudvault.model.User;
import com.cloudvault.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public DataInitializer(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        createUser("viewer", "viewer123", Role.ROLE_VIEWER);
        createUser("editor", "editor123", Role.ROLE_EDITOR);
        createUser("admin",  "admin123",  Role.ROLE_ADMIN);
        System.out.println("Test users created: viewer / editor / admin");
    }

    private void createUser(String username, String password, Role role) {
        if (userRepository.findByUsername(username).isEmpty()) {
            userRepository.save(new User(username, passwordEncoder.encode(password), role));
        }
    }
}
