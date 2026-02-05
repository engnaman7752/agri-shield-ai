package com.cropinsurance.service;

import lombok.extern.slf4j.Slf4j;
import okhttp3.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.Random;

/**
 * SMS Service - Sends OTP via Fast2SMS (India)
 * Get free API key from: https://www.fast2sms.com/
 */
@Service
@Slf4j
public class SmsService {

    @Value("${sms.enabled:true}")
    private boolean smsEnabled;

    @Value("${sms.mock-mode:true}")
    private boolean mockMode;

    @Value("${sms.fast2sms.api-key:}")
    private String apiKey;

    private final OkHttpClient httpClient = new OkHttpClient();
    private final Random random = new Random();

    /**
     * Generate a 6-digit OTP
     */
    public String generateOtp() {
        if (mockMode) {
            return "123456"; // Fixed OTP for demo
        }
        return String.format("%06d", random.nextInt(1000000));
    }

    /**
     * Send OTP to phone number
     * 
     * @param phone Phone number (Indian 10-digit)
     * @param otp   OTP to send
     * @return true if sent successfully
     */
    public boolean sendOtp(String phone, String otp) {
        // Clean phone number
        String cleanPhone = phone.replaceAll("[^0-9]", "");
        if (cleanPhone.startsWith("91") && cleanPhone.length() == 12) {
            cleanPhone = cleanPhone.substring(2);
        }

        log.info("📱 Sending OTP to: {} | OTP: {}", cleanPhone, otp);

        if (!smsEnabled) {
            log.info("SMS disabled. OTP not sent.");
            return true;
        }

        if (mockMode) {
            log.info("🔧 Mock mode: OTP is always 123456");
            return true;
        }

        // Real SMS via Fast2SMS
        return sendViaFast2Sms(cleanPhone, otp);
    }

    /**
     * Send SMS via Fast2SMS API
     */
    private boolean sendViaFast2Sms(String phone, String otp) {
        if (apiKey == null || apiKey.isEmpty() || apiKey.equals("YOUR_FAST2SMS_API_KEY_HERE")) {
            log.warn("Fast2SMS API key not configured. Using mock mode.");
            return true;
        }

        try {
            String message = "Your Crop Insurance OTP is: " + otp + ". Valid for 5 minutes. - Fasal Beema";

            // Fast2SMS Quick SMS API
            String url = "https://www.fast2sms.com/dev/bulkV2";

            RequestBody formBody = new FormBody.Builder()
                    .add("route", "q") // Quick SMS
                    .add("message", message)
                    .add("language", "english")
                    .add("flash", "0")
                    .add("numbers", phone)
                    .build();

            Request request = new Request.Builder()
                    .url(url)
                    .addHeader("authorization", apiKey)
                    .addHeader("Content-Type", "application/x-www-form-urlencoded")
                    .post(formBody)
                    .build();

            try (Response response = httpClient.newCall(request).execute()) {
                String responseBody = response.body() != null ? response.body().string() : "";

                if (response.isSuccessful()) {
                    log.info("✅ SMS sent successfully to {}", phone);
                    log.debug("Response: {}", responseBody);
                    return true;
                } else {
                    log.error("❌ SMS failed. Status: {} | Response: {}", response.code(), responseBody);
                    return false;
                }
            }
        } catch (IOException e) {
            log.error("❌ SMS sending error: {}", e.getMessage());
            return false;
        }
    }

    /**
     * Send custom SMS message
     */
    public boolean sendSms(String phone, String message) {
        if (!smsEnabled || mockMode) {
            log.info("📱 SMS (mock): To {} | Message: {}", phone, message);
            return true;
        }

        // Implementation for custom messages
        return sendCustomViaFast2Sms(phone, message);
    }

    private boolean sendCustomViaFast2Sms(String phone, String message) {
        if (apiKey == null || apiKey.isEmpty()) {
            return true;
        }

        try {
            String url = "https://www.fast2sms.com/dev/bulkV2";

            RequestBody formBody = new FormBody.Builder()
                    .add("route", "q")
                    .add("message", message)
                    .add("language", "english")
                    .add("flash", "0")
                    .add("numbers", phone)
                    .build();

            Request request = new Request.Builder()
                    .url(url)
                    .addHeader("authorization", apiKey)
                    .post(formBody)
                    .build();

            try (Response response = httpClient.newCall(request).execute()) {
                return response.isSuccessful();
            }
        } catch (IOException e) {
            log.error("SMS error: {}", e.getMessage());
            return false;
        }
    }
}
