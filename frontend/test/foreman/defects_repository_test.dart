/// Путь файла для `POST /files/link`.
///
/// Ручка принимает путь относительно каталога загрузок и по нему же считает
/// владельца файла (`backend/src/core/files.parse_owner`), а `pdf_file`
/// приходит полным адресом. Наступить на это легко, а ошибка тихая: сервер
/// отвечает «такого файла нет».
library;

import 'package:els/foreman/defects/defects_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('адрес из ответа режется до пути внутри статики', () {
    expect(
      staticPathOf('185.154.193.42:8000/api/v1/static/defective_act/31/pdf/a.pdf'),
      'defective_act/31/pdf/a.pdf',
    );
  });

  test('путь под HTTPS и с доменом режется так же', () {
    expect(
      staticPathOf('https://els.example/api/v1/static/defective_act/7/pdf/b.pdf'),
      'defective_act/7/pdf/b.pdf',
    );
  });

  test('уже относительный путь остаётся собой, ведущий слэш снимается', () {
    expect(staticPathOf('defective_act/7/pdf/b.pdf'), 'defective_act/7/pdf/b.pdf');
    expect(staticPathOf('/defective_act/7/pdf/b.pdf'), 'defective_act/7/pdf/b.pdf');
  });
}
