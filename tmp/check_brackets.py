
import os

files = [
    r'C:\Fred\Programas\Golf 2\apps\main_app\lib\src\features\quotes\presentation\widgets\service_estimation_dialog.dart',
    r'C:\Fred\Programas\Golf 2\apps\main_app\lib\src\features\quotes\presentation\widgets\quote_form_dialog.dart',
    r'C:\Fred\Programas\Golf 2\apps\main_app\lib\src\features\quotes\presentation\widgets\schedule_calendar_view.dart',
    r'C:\Fred\Programas\Golf 2\apps\main_app\lib\src\features\quotes\presentation\pages\quote_detail_page.dart'
]

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
        lp = content.count('(')
        rp = content.count(')')
        lb = content.count('{')
        rb = content.count('}')
        ls = content.count('[')
        rs = content.count(']')
        print(f"{os.path.basename(f)}: (={lp} )={rp} {lp-rp} | {{={lb} }}={rb} {lb-rb} | [={ls} ]={rs} {ls-rs}")
