lib/
├── core/
│   └── config/
│       └── api_config.dart
│
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
│
├── presentation/
│   ├── screens/
│   └── widgets/                    ← รวมทุก widget ไว้ที่นี่
│       ├── camera/
│       │   ├── models/             ← _model.dart 
│       │   │   ├── addnewcamera_model.dart
│       │   │   ├── detailscamera_model.dart
│       │   │   └── editdatacamera_model.dart
│       │   └── views/              ← _widget.dart 
│       │       ├── addnewcamera_widget.dart
│       │       ├── detailscamera_widget.dart
│       │       └── editdatacamera_widget.dart
│       ├── map/
│       │   ├── models/
│       │   │   ├── map_view_component_model.dart
│       │   │   └── marker_info_popup_model.dart
│       │   └── views/
│       │       ├── interactive_map.dart
│       │       ├── map_view_component_widget.dart
│       │       └── marker_info_popup_widget.dart
│       ├── nav/
│       │   ├── models/
│       │   │   └── nav_bar_main_model.dart
│       │   └── views/
│       │       └── nav_bar_main_widget.dart
│       └── shared/                 ← widget ที่ใช้ร่วมกันหลายที่
│           ├── hls_player.dart
│           ├── camera_dashboard_table.dart
│           ├── license_plate_table.dart
│           └── command_widget.dart
│
└── utils/
    ├── flutter_flow/               ← รวม flutter_flow_*.dart ไว้กลุ่มเดียว
    │   ├── animations.dart
    │   ├── autocomplete_options_list.dart
    │   ├── data_table.dart
    │   ├── icon_button.dart
    │   ├── model.dart              ← flutter_flow_model.dart
    │   ├── theme.dart
    │   ├── util.dart
    │   └── widgets.dart
    └── models/                     ← data model เล็กๆ ที่ไม่ผูกกับ UI
        ├── lat_lng.dart
        ├── place.dart
        └── uploaded_file.dart