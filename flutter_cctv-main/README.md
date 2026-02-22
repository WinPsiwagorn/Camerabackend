lib/
├── core/                # เก็บ Config พื้นฐาน (เอา api_config.dart มาไว้ที่นี่)
├── data/                # ส่วนจัดการข้อมูล
│   ├── models/          # เก็บ Model class (เช่น Camera, LicensePlate)
│   ├── repositories/    # ตัวกลางที่เรียก Service แล้วแปลงเป็น Model
│   └── services/        # เก็บตัวยิง API (ย้าย api_manager.dart มาปรับปรุงที่นี่)
├── presentation/        # ส่วนแสดงผล UI
│   ├── screens/         # หน้าจอหลัก (เช่น command_view, login_page)
│   └── widgets/         # UI ส่วนย่อย (เช่น hls_player, camera_dashboard_table)
└── utils/               # ไฟล์ช่วยเหลือต่างๆ