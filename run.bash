#!/bin/bash

python3 Backend/backend.py &
flutter run --release --web-hostname 0.0.0.0 --web-port=8080