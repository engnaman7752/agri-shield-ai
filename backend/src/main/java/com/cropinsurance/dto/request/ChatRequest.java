package com.cropinsurance.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class ChatRequest {
    private String message;
    
    @JsonProperty("insurance_id")
    private String insuranceId;
    
    @JsonProperty("sensor_code")
    private String sensorCode;
    
    @JsonProperty("farmer_id")
    private String farmerId;
}
