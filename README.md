\# Flutter Isolate FPS Demo



\## 1. Giới thiệu



\*\*Isolate FPS Demo\*\* là ứng dụng Flutter minh họa cách sử dụng Isolates để xử lý các tác vụ nặng mà không làm nghẽn luồng giao diện (UI).



Ứng dụng tạo dữ liệu JSON lớn, sau đó parse JSON thành danh sách đối tượng `Product` bằng ba phương pháp:



1\. \*\*Main Thread:\*\* Xử lý trực tiếp trên luồng giao diện.

2\. \*\*compute():\*\* Chuyển tác vụ sang isolate nền bằng API `compute`.

3\. \*\*Isolate.spawn():\*\* Tạo isolate thủ công và trao đổi dữ liệu qua `SendPort` và `ReceivePort`.



Mục tiêu là so sánh thời gian xử lý và mức độ ảnh hưởng đến độ mượt của giao diện.



\## 2. Mục tiêu



\- Tìm hiểu sự khác nhau giữa Main Thread và Isolate.

\- Thực hành parse JSON và chuyển dữ liệu JSON thành model.

\- Tìm hiểu cách sử dụng `compute()`, `Isolate.spawn()`, `SendPort` và `ReceivePort`.

\- Quan sát FPS trong khi ứng dụng thực hiện tác vụ nặng.

\- So sánh thời gian xử lý và khoảng ngắt frame lớn nhất giữa các phương pháp.



\## 3. Công nghệ sử dụng



\- Flutter

\- Dart

\- Material Design 3

\- Dart Isolates

\- JSON (`dart:convert`)

\- Flutter Scheduler để theo dõi frame



\## 4. Cấu trúc thư mục



```text

lib/

├── main.dart

├── models/

│   ├── product.dart

│   └── bench\_result.dart

├── services/

│   ├── json\_service.dart

│   ├── isolate\_service.dart

│   └── fps\_monitor.dart

└── ui/

&#x20;   └── isolate\_demo.dart

```



\### Chức năng từng file



\- `main.dart`: Khởi chạy ứng dụng Flutter.

\- `models/product.dart`: Định nghĩa model `Product` và chuyển JSON thành đối tượng.

\- `models/bench\_result.dart`: Lưu kết quả của mỗi lượt kiểm thử.

\- `services/json\_service.dart`: Tạo JSON, parse JSON và tính dung lượng dữ liệu.

\- `services/isolate\_service.dart`: Thực hiện xử lý bằng `Isolate.spawn()` và giao tiếp qua các port.

\- `services/fps\_monitor.dart`: Theo dõi FPS và khoảng thời gian giữa các frame.

\- `ui/isolate\_demo.dart`: Hiển thị giao diện, điều khiển phép thử và kết quả.



\## 5. Yêu cầu cài đặt



Trước khi chạy chương trình, cần cài đặt:



\- Flutter SDK.

\- Dart SDK đi kèm Flutter.

\- Git.

\- Một trong các môi trường chạy được hỗ trợ, chẳng hạn Windows Desktop hoặc thiết bị Android.



Kiểm tra môi trường:



```bash

flutter --version

flutter doctor

```



\## 6. Cài đặt và chạy chương trình



\### Bước 1: Clone repository



```bash

git clone https://github.com/nguyenbui220905-rgb/Isolate\_fps\_demo.git

cd Isolate\_fps\_demo

```



\### Bước 2: Cài đặt dependencies



```bash

flutter pub get

```



\### Bước 3: Kiểm tra mã nguồn



```bash

flutter analyze

```



\### Bước 4: Chạy ứng dụng



Chạy trên Windows Desktop:



```bash

flutter run -d windows --profile

```



Hoặc chạy trên thiết bị Android đã kết nối:



```bash

flutter devices

flutter run --profile

```



Chế độ `--profile` phù hợp để đánh giá hiệu năng hơn chế độ debug.



\## 7. Hướng dẫn sử dụng



1\. Mở ứng dụng.

2\. Nhấn \*\*Tạo JSON\*\* để tạo dữ liệu kiểm thử.

3\. Kiểm tra dung lượng JSON hiển thị trên giao diện. Chỉ chạy phép thử khi dữ liệu lớn hơn 15 MiB.

4\. Nhấn \*\*Main Thread\*\* để parse JSON trực tiếp trên luồng giao diện.

5\. Nhấn \*\*compute()\*\* để parse JSON trên isolate nền.

6\. Nhấn \*\*Isolate + Port\*\* để kiểm tra phương pháp tạo isolate thủ công.

7\. Quan sát biểu tượng đang xoay, FPS và các kết quả được hiển thị.

8\. So sánh thời gian xử lý, số bản ghi, FPS trung bình và khoảng ngắt frame lớn nhất giữa các phương pháp.



Nên chạy mỗi phương pháp nhiều lần trên cùng thiết bị và cùng dữ liệu để kết quả dễ so sánh hơn.



\## 8. Nguyên lý hoạt động



\### Main Thread



Tác vụ parse JSON được thực hiện đồng bộ trên isolate giao diện. Khi tác vụ chiếm nhiều thời gian, giao diện có thể bị khựng vì các frame không được xử lý kịp thời.



\### compute()



Hàm `compute()` giúp chuyển tác vụ xử lý dữ liệu sang isolate nền trên các nền tảng native được hỗ trợ, nhờ đó giảm việc chiếm dụng luồng giao diện.



\### Isolate.spawn()



`Isolate.spawn()` tạo isolate mới. Isolate giao diện gửi `SendPort` cho isolate xử lý; isolate xử lý gửi kết quả về thông qua port đó. Hai isolate không chia sẻ trực tiếp vùng nhớ thông thường như các luồng dùng chung bộ nhớ.



\## 9. Các chỉ số đánh giá



\- \*\*Thời gian xử lý (ms):\*\* Thời gian từ khi bắt đầu đến khi tác vụ hoàn thành, theo cách đo của ứng dụng.

\- \*\*FPS trung bình:\*\* Số frame callback ghi nhận trên mỗi giây trong khoảng đo.

\- \*\*Khoảng ngắt frame lớn nhất (ms):\*\* Khoảng cách thời gian lớn nhất giữa hai frame callback liên tiếp trong phiên kiểm thử.

\- \*\*Số bản ghi:\*\* Số đối tượng `Product` được parse thành công.



Các chỉ số FPS và khoảng ngắt frame là phép đo gần đúng dựa trên callback của Flutter, không phải phép đo phần cứng tuyệt đối. Kết quả có thể thay đổi theo thiết bị, hệ điều hành và điều kiện chạy.



\## 10. Kết quả mong đợi



\- \*\*Main Thread:\*\* Tác vụ nặng có thể làm giao diện giật hoặc tạm ngừng cập nhật.

\- \*\*compute():\*\* Giao diện thường mượt hơn vì phần parse được thực hiện ngoài isolate giao diện.

\- \*\*Isolate.spawn():\*\* Cũng có thể giữ giao diện mượt hơn, đồng thời minh họa rõ cách trao đổi thông điệp giữa các isolate.



Thời gian chạy thực tế phụ thuộc vào môi trường. Không nên kết luận phương pháp nào nhanh nhất chỉ từ một lần thử.



\## 11. Giới hạn hiện tại



\- Dữ liệu JSON được tạo trong bộ nhớ, không phải đọc từ một file JSON có sẵn trên ổ đĩa.

\- Kích thước JSON thực tế phụ thuộc số lượng bản ghi và nội dung dữ liệu.

\- Các phép đo hiệu năng mang tính tham khảo và cần được thực hiện trên cùng thiết bị để so sánh công bằng.


## 12. Cấu hình môi trường

Dự án hiện tại không yêu cầu file `.env` hoặc `google-services.json`.

- **`.env`:** Không cần vì ứng dụng không sử dụng API bên ngoài, thông tin đăng nhập máy chủ hoặc khóa bí mật.
- **`google-services.json`:** Không cần vì ứng dụng không tích hợp Firebase.
- **Dữ liệu kiểm thử:** Được tạo và xử lý cục bộ trong ứng dụng.

Nếu phát triển thêm chức năng sử dụng API hoặc Firebase, cần bổ sung hướng dẫn cấu hình tương ứng.

## 13. Kiểm tra chất lượng mã nguồn

Chạy các lệnh sau tại thư mục gốc dự án:

```bash
flutter pub get
flutter analyze
flutter run -d windows --profile
```

- `flutter pub get`: cài đặt các dependency.
- `flutter analyze`: kiểm tra lỗi và cảnh báo mã nguồn.
- `flutter run -d windows --profile`: chạy ứng dụng ở chế độ Profile để kiểm thử hiệu năng.

Để chạy trên Windows Desktop, cần cài Flutter SDK và Visual Studio với workload **Desktop development with C++**.

## 14. Giới hạn và hướng phát triển

- Dữ liệu JSON hiện được tạo trong bộ nhớ, chưa đọc từ tập tin JSON có sẵn.
- Các chỉ số FPS và thời gian xử lý phụ thuộc thiết bị, nền tảng và điều kiện chạy.
- Hướng phát triển: bổ sung chức năng chọn và đọc tập tin JSON lớn hơn 15 MiB, cải thiện xử lý lỗi và thực hiện nhiều lần đo để so sánh kết quả.




