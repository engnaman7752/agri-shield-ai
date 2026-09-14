package com.cropinsurance.entity.enums;

/**
 * PMFBY-aligned Crop Damage Reason Categories
 * Each reason has Hindi and English descriptions
 */
public enum DamageReason {
    DROUGHT("सूखा", "Drought / Dry Spell"),
    FLOOD_INUNDATION("बाढ़", "Flood / Inundation"),
    HEAVY_UNSEASONAL_RAIN("भारी/असामयिक बारिश", "Heavy / Unseasonal Rain"),
    HAILSTORM("ओलावृष्टि", "Hailstorm"),
    CYCLONE_STORM("चक्रवात/तूफान", "Cyclone / Storm"),
    PEST_ATTACK("कीट हमला", "Pest / Insect Attack"),
    CROP_DISEASE("फसल रोग", "Crop Disease"),
    FROST_COLD_WAVE("पाला/शीत लहर", "Frost / Cold Wave"),
    LIGHTNING_FIRE("बिजली/आग", "Lightning / Natural Fire"),
    LANDSLIDE("भूस्खलन", "Landslide"),
    POST_HARVEST_LOSS("कटाई के बाद नुकसान", "Post-Harvest Loss"),
    PREVENTED_SOWING("बुवाई न हो पाना", "Prevented Sowing"),
    OTHER("अन्य", "Other");

    private final String hindi;
    private final String english;

    DamageReason(String hindi, String english) {
        this.hindi = hindi;
        this.english = english;
    }

    public String getHindi() { return hindi; }
    public String getEnglish() { return english; }
}
