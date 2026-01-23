package com.bridge.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.List;

@Data
public class SpeakerDTO {
    private String name;
    private String speakerUuid;
    private List<Style> styles;

    @Data
    public static class Style {
        private String name;
        
        @JsonProperty("style_id")
        private int styleId;
    }
}