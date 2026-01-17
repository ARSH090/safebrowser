# 🗺️ SafeBrowser: Future Upgrades & Bonus Features

This document outlines the roadmap for extending SafeBrowser into a full-scale child safety system. 

---

## 🚀 Phase 2: Missing & Bonus Features

### 1. Age-Based Social Media Blocking
*   **Goal**: Automatically restrict access to platforms like TikTok, Instagram, and Snapchat for users below a certain age group.
*   **Implementation**: 
    *   Map `AgeGroup` to strict domain blacklists.
    *   Inject restricted navigation logic in `WebViewSafetyManager`.

### 2. Explicit Media Detection (Advanced AI)
*   **Goal**: Move beyond text filtering to real-time image and video byte-level analysis.
*   **Implementation**: 
    *   Integrate `image_model.tflite` for NSFW detection.
    *   Analyze network resources in `onLoadResource` or `shouldInterceptRequest`.

### 3. Wellbeing & Usage Insights
*   **Goal**: Track screen time and provide health reports to parents.
*   **Implementation**: 
    *   Create a local timer in `BrowserPage`.
    *   Sync total daily minutes to a new `usageStats` sub-collection in Firestore.
    *   Display usage charts (e.g., using `fl_chart`) on the Parent Dashboard.

### 4. Ethical Content Filtering
*   **Goal**: Detect manipulative language and "Fake Educational" content.
*   **Implementation**: 
    *   Expand `ContentFilterService` with logic to score "Educational Confidence."
    *   Block sites that use dark patterns to target children.

---

## 🤖 Master AI Development Prompt

Give this prompt to any AI coding assistant to continue developing these features:

```text
You are a senior Flutter + Firebase + AI architect.

Analyze the SafeBrowser project and implement the following Phase 2 features:

1. Age-based social media blocking using the existing ChildProfile.ageGroup.
2. Explicit media detection (NSFW image blocking using TFLite).
3. Wellbeing and usage analytics: track browsing time and show charts on the Parent Dashboard.
4. Ethical content filtering: refine NLP text analysis to detect "fake educational" content.

Technical Requirements:
- Maintain the "Fail-Closed" security philosophy.
- Ensure all new logs follow the LogModel schema.
- Update Firestore rules to accommodate usage stats if needed.
- Optimize WebView interception for minimal "Safety Lag."

Maintain the existing folder structure and ensure zero build errors.
```

---

## 🔒 Security Hardening Roadmap
*   **Screenshot Prevention**: Use `flutter_windowmanager` to prevent screenshots during child sessions.
*   **Root Detection**: Detect rooted devices to prevent sandbox bypass.
*   **Secure DNS**: Hardcode DNS over HTTPS (DoH) to prevent DNS-level bypasses by ISP or local network.

---
*SafeBrowser: The Future of Responsible Parenting.*
