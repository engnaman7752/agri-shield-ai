package com.cropinsurance.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.util.List;

@Data
public class ChatResponse {
    private String answer;
    
    @JsonProperty("reasoning_steps")
    private List<String> reasoningSteps;
}
