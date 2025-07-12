# API Configuration for Flutter App

## Current Issue:
The Flutter app is using a different base URL than the Python app.

## Python Configuration (standardui.py):
```python
API_BASE_URL = os.getenv("API_BASE_URL", "http://127.0.0.1:8000")
```

## Flutter Configuration (needs to be changed):
```dart
static const String baseUrl = 'http://127.0.0.1:8000';
```

## Steps to fix:
1. Change baseUrl in InsightApiService
2. Make sure the backend server is running on http://127.0.0.1:8000
3. Test with simple endpoint first

## Endpoints that should work:
- POST /analyze-form (for both images and PDFs)
- POST /annotate-image (for live preview updates)
- POST /text-to-speech
- POST /speech-to-text
