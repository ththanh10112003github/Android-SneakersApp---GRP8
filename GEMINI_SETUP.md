# Hướng dẫn Cấu hình Gemini AI cho Chatbot

## Bước 1: Lấy Gemini API Key

1. Truy cập [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Đăng nhập bằng tài khoản Google của bạn
3. Click "Get API key" và chọn "Create API key"
4. Chọn một Google Cloud project hoặc tạo project mới
5. Copy API key vừa tạo

## Bước 2: Cấu hình API Key trong ứng dụng

1. Mở file `lib/utils/gemini_config.dart`
2. Thay thế `'YOUR_GEMINI_API_KEY'` bằng API key thật của bạn:

```dart
class GeminiConfig {
  static const String apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
  // ...
}
```

## Bước 3: Kiểm tra

1. Chạy ứng dụng: `flutter run`
2. Mở Chat Bot screen
3. Chọn "AI Chat" mode
4. Bạn sẽ thấy welcome message từ AI

## Lưu ý

- **Bảo mật**: Không commit API key vào Git repository
- File `gemini_config.dart` nên được thêm vào `.gitignore` nếu chứa API key thật
- API key miễn phí có giới hạn requests/tháng
- Để tăng limit, có thể upgrade Google Cloud project

## Tính năng

✅ **AI Chat Mode**: Chat tự nhiên với Gemini AI
✅ **Form Mode**: Wizard form như trước
✅ **Context-Aware**: AI biết về orders và profile của user
✅ **Auto Ticket Creation**: Tự động tạo ticket từ AI conversation

## Troubleshooting

- **Lỗi "API key chưa được cấu hình"**: Kiểm tra lại `gemini_config.dart`
- **Lỗi "API key invalid"**: Đảm bảo API key đúng và có quyền truy cập
- **Không có response**: Kiểm tra internet connection và API quota

