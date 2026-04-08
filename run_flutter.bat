@echo off
cd /d "c:\Fred\Programas\Golf 2\apps\main_app"
echo Starting flutter...
flutter run -d chrome --web-port 8081 > run_log.txt 2>&1
echo Done.
