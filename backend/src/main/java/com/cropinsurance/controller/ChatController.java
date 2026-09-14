package com.cropinsurance.controller;

import com.cropinsurance.dto.request.ChatRequest;
import com.cropinsurance.dto.response.ApiResponse;
import com.cropinsurance.dto.response.ChatResponse;
import com.cropinsurance.service.ChatService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import org.springframework.security.core.annotation.AuthenticationPrincipal;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
@Tag(name = "Chat", description = "AI Agent Chat Integration")
public class ChatController {

    private final ChatService chatService;

    @PostMapping
    @Operation(summary = "Send message to ReAct AI Agent")
    public ResponseEntity<ApiResponse<ChatResponse>> processChat(
            @AuthenticationPrincipal String userId,
            @Valid @RequestBody ChatRequest request) {
        
        request.setFarmerId(userId);
        ChatResponse response = chatService.processChat(request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
