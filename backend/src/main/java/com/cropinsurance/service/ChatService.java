package com.cropinsurance.service;

import com.cropinsurance.dto.request.ChatRequest;
import com.cropinsurance.dto.response.ChatResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

@Service
@Slf4j
public class ChatService {

    @Value("${ai.service.url:http://localhost:8000}")
    private String aiServiceUrl;

    public ChatResponse processChat(ChatRequest request) {
        log.info("Forwarding chat request to AI Service: {}", request.getMessage());
        
        try {
            WebClient client = WebClient.create(aiServiceUrl);
            
            return client.post()
                    .uri("/chat")
                    .bodyValue(request)
                    .retrieve()
                    .bodyToMono(ChatResponse.class)
                    .block();
                    
        } catch (Exception e) {
            log.error("Failed to connect to AI Service /chat endpoint", e);
            ChatResponse fallback = new ChatResponse();
            fallback.setAnswer("I'm sorry, my AI engine is currently unreachable. Please try again later.");
            fallback.setReasoningSteps(java.util.Collections.emptyList());
            return fallback;
        }
    }
}
