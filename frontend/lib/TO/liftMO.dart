
import 'package:flutter/material.dart';

import '../helper/button/my_button.dart';
import '../helper/class_colors.dart';
import '../screns/home_page/home_page.dart';
import '../screns/object/view/object_screen.dart';
import '../screns/schedule/schedule_page.dart';

/// ТО Лифт МО

List liftMOTO1 = [
  {"text" : 'Проверка средств защиты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка наличия инструмента', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Информирование оператора о начале работ', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Получение ключей от машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность освещения на площадке и в приямке', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие и состояние светового табло', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Вывешивание плаката "Лифт на текущем ремонте', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие информационных табличек', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние вызывного аппарата, исправность ламп', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние ограждения двери шахты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность замка дверей шахты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Зазоры между створкой и обрамлением', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние плафона и исправность ламп', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Качество связи с диспетчером', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Интерьер купе – отсутствие повреждений', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние лицевой панели и кнопок', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность реверса дверей', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность замка и контакта двери кабины', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка исправности кнопки "Стоп', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка правильности работы приказного аппарата по этажам', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие вибрации, толчков, посторонних шумов', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Плавность торможения при остановке кабины', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Точность остановки на этажах', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние освещения у входа в машинное помещение', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие и состояние ступеней при входе и ограждения перепадов высот', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние двери машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность запора двери машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие надписи на двери машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отключить, проверить отсутствие напряжения, наличие запирающего устройства', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность выключателя освещения и ламп', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие механической защиты лампы', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие посторонних предметов, чистота', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие электросхемы, средств защиты от электротока', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Равномерность отхода тормозных колодок', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие сколов реборды, износ ручьев', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Надежность крепления гаек, состояние подшипников', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние ограждения КВШ', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Уровень масла в редукторе', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние предохранителей', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие нерегламентированных перемычек', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность освещения, ламп', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие повреждений', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние вызывных аппаратов, исправность кнопок', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить работу лифта по вызовам', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние ограждения дверей шахты на всех этажах', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Снять плакаты «Лифт на текущем ремонте»', "bool" : false, "comment" : '', "photo" : ''},
];

List liftMOTO3 = [
  {"text" : 'Проверка средств защиты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка наличия инструмента', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Информирование оператора о начале работ', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Получение ключей от машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность освещения на площадке и в приямке', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие и состояние светового табло', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Вывешивание плаката "Лифт на текущем ремонте', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие информационных табличек', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние вызывного аппарата, исправность ламп', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние ограждения двери шахты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность замка дверей шахты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Зазоры между створкой и обрамлением', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние плафона и исправность ламп освещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Качество связи с диспетчером', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Интерьер купе – отсутствие повреждений', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние лицевой панели и кнопок', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность реверса дверей', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность замка и контакта двери кабины', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка исправности кнопки "Стоп', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка правильности работы приказного аппарата по этажам', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие вибрации, толчков, посторонних шумов', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Плавность торможения при остановке кабины', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Точность остановки на этажах', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние освещения у входа в машинное помещение', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие и состояние ступеней при входе и ограждения перепадов высот', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние двери машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность запора двери машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие надписи на двери машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отключить, проверить отсутствие напряжения, наличие запирающего устройства', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность выключателя освещения и ламп', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие механической защиты лампы', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие посторонних предметов, чистота', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие электросхемы, средств защиты от электротока', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Равномерность отхода тормозных колодок', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие сколов реборды, износ ручьев', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Надежность крепления гаек, состояние', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние ограждения КВШ', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Уровень масла в редукторе', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние предохранителей', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие нерегламентированных перемычек', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность освещения, ламп', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие повреждений', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние вызывных аппаратов, исправность кнопок', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить работу лифта по вызовам', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние ограждения дверей шахты на всех этажах', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Снять плакаты «Лифт на текущем ремонте»', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Сделать запись в журнал о проведении ТО', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Снять плакат «Лифт на текущем ремонте»', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Сообщить по связи диспетчеру о завершении работ', "bool" : false, "comment" : '', "photo" : ''},
];

List liftMOTO6A = [
  {"text" : 'Проверка средств защиты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка наличия инструмента', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Информирование оператора о начале работ', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Получение ключей от машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'исправность освещения на площадке', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'наличие информационных табличек', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'наличие и состояние светового табло', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние вызывного аппарата, исправность кнопки', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние створок двери шахты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние притворной резины двери шахты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'зазор между створками ДШ и обрамлением портала', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'исправность замка дверей шахты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'зазор между створками и обрамлением ДШ', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние притворной резины створок ДК', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'работу реверса дверей', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'исправность замка и контакта дверей кабины', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'исправность подпольного контакта', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка исправности кнопки "Стоп"', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка правильности работы приказного аппарата по этажам', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие вибрации, толчков, посторонних', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Плавность торможения при остановке кабины', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Точность остановки на этажах', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние освещения у входа в машинное помещение', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие и состояние ступеней при входе и ограждения перепадов высот', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние двери машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность запора двери машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие надписи на двери машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Уровень масла в редукторе', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние поверхности тормозной полумуфты, ее крепление', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние буферных', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие сколов реборды, износ ручьев', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Надежность крепления гаек', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие сколов реборды, износ ручьев', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние подшипников, наличие смазки', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Надежность крепления болтовых соединений', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Равномерность отхода тормозных колодок, их состояние', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность и состояние тормозного электромагнита', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние рычагов, осей, шайб, шплинтов', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие сколов, трещин на шкиве', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние каната ограничителя скорости', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'исправность освещения и ламп на этаже', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'отсутствие повреждений на портале и ДШ', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние вызывного аппарата и кнопки', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние притворной резины створок ДШ', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'зазоры между створками ДШ и обрамлением портала', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'исправность освещения и ламп на этажных площадках', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'отсутствие повреждений на портале и двери', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние вызывных аппаратов и кнопок', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние притворной резины дверей шахты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'зазоры между створками и обрамлением портала', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'проверяет работу лифта по вызовам и действие УБ-1 при недозакрывании дверей шахты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'снимает плакат «Лифт на текущем ремонте»', "bool" : false, "comment" : '', "photo" : ''},
];

// List liftMOTO6B = [
//   {"text" : 'Проверка средств защиты', "bool" : false},
//   {"text" : 'Проверка наличия инструмента', "bool" : false},
//   {"text" : 'Информирование оператора о начале работ', "bool" : false},
//   {"text" : 'Получение ключей от машинного помещения', "bool" : false},
//   {"text" : 'санитарное состояние', "bool" : false},
//   {"text" : 'исправность освещения в приямке', "bool" : false},
//   {"text" : 'наличие механической защиты ламп', "bool" : false},
//   {"text" : 'исправность выключателя приямка', "bool" : false},
//   {"text" : 'буферное устройство кабины', "bool" : false},
//   {"text" : 'состояние натяжного устройства ОС', "bool" : false},
//   {"text" : 'исправность контакта ВНУ', "bool" : false},
//   {"text" : 'состояние подвесного кабеля, низ кабины', "bool" : false},
//   {"text" : 'состояние подвижного пола кабины', "bool" : false},
//   {"text" : 'состояние плафона и исправность ламп освещения', "bool" : false},
//   {"text" : 'качество связи с диспетчером', "bool" : false},
//   {"text" : 'интерьер купе - отсутствие повреждений', "bool" : false},
//   {"text" : 'состояние лицевой панели приказного аппарата', "bool" : false},
//   {"text" : 'Проверка исправности кнопки "Стоп"', "bool" : false},
//   {"text" : 'Проверка правильности работы приказного аппарата по этажам', "bool" : false},
//   {"text" : 'Отсутствие вибрации, толчков, посторонних', "bool" : false},
//   {"text" : 'Плавность торможения при остановке кабины', "bool" : false},
//   {"text" : 'Точность остановки на этажах', "bool" : false},
//   {"text" : 'Отключить, проверить отсутствие напряжения, наличие запирающего устройства', "bool" : false},
//   {"text" : 'Состояние контактных поверхностей ножей и пенцетов', "bool" : false},
//   {"text" : 'Состояние нулевого провода и электропроводки в машинном', "bool" : false},
//   {"text" : 'Исправность выключателя освещения и ламп', "bool" : false},
//   {"text" : 'Наличие механической защиты', "bool" : false},
//   {"text" : 'Отсутствие посторонних предметов, чистота', "bool" : false},
//   {"text" : 'Наличие электросхемы, средств защиты от электротока', "bool" : false},
//   {"text" : 'Состояние предохранителей', "bool" : false},
//   {"text" : 'Отсутствие нерегламентированных перемычек', "bool" : false},
//   {"text" : 'Состояние контактных поверхностей реле и контакторов', "bool" : false},
//   {"text" : 'исправность ламп освещения в шахте', "bool" : false},
//   {"text" : 'чистота на крыше кабины', "bool" : false},
//   {"text" : 'состояние привода дверей', "bool" : false},
//   {"text" : 'состояние башмаков и вкладышей кабины', "bool" : false},
//   {"text" : 'состояние рамы и контактов СПК и ДУСК', "bool" : false},
//   {"text" : 'исправность контакта ловителей и взаимодействие его с рычажным механизмом', "bool" : false},
//   {"text" : 'состояние ограждения шахты', "bool" : false},
//   {"text" : 'состояние шунтов и датчиков, этажных переключателей', "bool" : false},
//   {"text" : 'состояние башмаков и вкладышей противовеса, штихмасс', "bool" : false},
//   {"text" : 'состояние верхней балки дверей шахты, исправность контактов ДШ, ДЗ', "bool" : false},
//   {"text" : 'исправность замков дверей шахты', "bool" : false},
//   {"text" : 'состояние башмачков двери шахты', "bool" : false},
//   {"text" : 'состояние порога дверей шахты', "bool" : false},
//   {"text" : 'накат створок и крепление их к кареткам', "bool" : false},
//   {"text" : 'Сделать запись в журнал о проведении ТО', "bool" : false},
//   {"text" : 'Сообщить по связи диспетчеру о завершении работ', "bool" : false},
// ];

List liftMOTO12A = [
  {"text" : 'Проверка средств защиты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка наличия инструмента', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Информирование оператора  о начале работ', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Получение ключей от машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'исправность освещения на площадке', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'наличие информационных табличек', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'наличие и состояние светового табло', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние вызывного аппарата, исправность кнопки', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние створок двери шахты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние притворной резины  двери шахты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'зазор между створками ДШ и обрамлением портала', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'исправность замка дверей шахты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'зазор между створками и обрамлением ДШ', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние притворной резины створок ДК', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'работу реверса дверей', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'исправность замка и контакта дверей кабины', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'исправность подпольного контакта', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка правильности работы приказного аппарата по этажам', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие вибрации, толчков, посторонних шумов', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Плавность торможения при остановке кабины', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Точность остановки на этажах', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность подпольного контакта кабины', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние освещения у входа в машинное помещение', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие и состояние ступеней при входе и ограждения перепадов высот', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние двери машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность запора двери машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие надписи на двери машинного помещения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Уровень масла в редукторе', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние поверхности тормозной полумуфты, ее крепление', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние буферных', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие сколов реборды, износ ручьев', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Надежность крепления гаек', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Наличие ограждения', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие сколов реборды, износ ручьев', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние подшипников, наличие смазки', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Равномерность отхода тормозных колодок, их состояние', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Исправность и состояние тормозного электромагнита', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние рычагов, осей, шайб, шплинтов', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Отсутствие сколов, трещин на шкиве', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Состояние каната ограничителя скорости', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'исправность освещения и ламп на этаже', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'отсутствие повреждений на портале и ДШ', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние вызывного аппарата и кнопки', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние притворной резины створок ДШ', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'зазоры между створками ДШ и обрамлением портала', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'исправность освещения и ламп на этажных площадках', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'отсутствие повреждений на портале и двери', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние вызывных аппаратов и кнопок', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'состояние притворной резины дверей шахты', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'зазоры между створками и обрамлением портала', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'проверяет работу лифта по вызовам и действие УБ-1 при недозакрывании дверей', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'снимает плакат «Лифт на текущем ремонте»', "bool" : false, "comment" : '', "photo" : ''},
];

// List liftMOTO12B = [
//   {"text" : 'Проверка средств защиты', "bool" : false},
//   {"text" : 'Проверка наличия инструмента', "bool" : false},
//   {"text" : 'Информирование оператора  о начале работ', "bool" : false},
//   {"text" : 'Получение ключей от машинного помещения', "bool" : false},
//   {"text" : 'санитарное состояние', "bool" : false},
//   {"text" : 'исправность освещения в приямке', "bool" : false},
//   {"text" : 'наличие механической защиты ламп', "bool" : false},
//   {"text" : 'буферное устройство кабины', "bool" : false},
//   {"text" : 'состояние натяжного устройства ОС', "bool" : false},
//   {"text" : 'исправность контакта ВНУ', "bool" : false},
//   {"text" : 'состояние подвесного кабеля, низ кабины', "bool" : false},
//   {"text" : 'состояние плафона и исправность ламп освещения', "bool" : false},
//   {"text" : 'качество связи с диспетчером', "bool" : false},
//   {"text" : 'интерьер купе - отсутствие повреждений', "bool" : false},
//   {"text" : 'состояние лицевой панели приказного аппарата', "bool" : false},
//   {"text" : 'Проверка правильности работы приказного аппарата по этажам', "bool" : false},
//   {"text" : 'Отсутствие вибрации, толчков, посторонних шумов', "bool" : false},
//   {"text" : 'Плавность торможения при остановке кабины', "bool" : false},
//   {"text" : 'Точность остановки на этажах', "bool" : false},
//   {"text" : 'Исправность подпольного контакта кабины', "bool" : false},
//   {"text" : 'Отключить, проверить отсутствие напряжения, наличие запирающего устройства', "bool" : false},
//   {"text" : 'Состояние контактных поверхностей ножей и пинцетов', "bool" : false},
//   {"text" : 'Состояние нулевого провода и электропроводки в машинном', "bool" : false},
//   {"text" : 'Исправность выключателя освещения и ламп', "bool" : false},
//   {"text" : 'Наличие механической защиты', "bool" : false},
//   {"text" : 'Отсутствие посторонних предметов, чистота', "bool" : false},
//   {"text" : 'Наличие электросхемы, средств защиты от электротока', "bool" : false},
//   {"text" : 'Состояние предохранителей', "bool" : false},
//   {"text" : 'Отсутствие нерегламентированных перемычек', "bool" : false},
//   {"text" : 'Состояние контактных поверхностей реле и контакторов', "bool" : false},
//   {"text" : 'исправность ламп освещения в шахте', "bool" : false},
//   {"text" : 'чистота на крыше кабины', "bool" : false},
//   {"text" : 'состояние привода дверей', "bool" : false},
//   {"text" : 'состояние башмаков и вкладышей кабины', "bool" : false},
//   {"text" : 'состояние рамы и контактов СПК', "bool" : false},
//   {"text" : 'исправность контакта ловителей и взаимодействие его с рычажным', "bool" : false},
//   {"text" : 'наличие смазки в смазывающем устройстве', "bool" : false},
//   {"text" : 'состояние ограждения шахты', "bool" : false},
//   {"text" : 'состояние шунтов и датчиков, этажных переключателей', "bool" : false},
//   {"text" : 'состояние башмаков и вкладышей противовеса, штихмасс', "bool" : false},
//   {"text" : 'состояние верхней балки дверей шахты, исправность контактов ДШ, ДЗ', "bool" : false},
//   {"text" : 'исправность замков дверей шахты', "bool" : false},
//   {"text" : 'состояние башмачков двери шахты', "bool" : false},
//   {"text" : 'состояние порога дверей шахты', "bool" : false},
//   {"text" : 'накат створок и крепление их к кареткам', "bool" : false},
//   {"text" : 'состояние направляющих кабины и противовеса', "bool" : false},
//   {"text" : 'состояние рамы и грузов противовеса', "bool" : false},
//   {"text" : 'Сделать запись в журнал о проведении ТО', "bool" : false},
//   {"text" : 'Сообщить по связи диспетчеру о завершении работ', "bool" : false},
// ];

class TOLiftMO extends StatefulWidget {
  const TOLiftMO({Key? key}) : super(key: key);

  @override
  State<TOLiftMO> createState() => _TOLiftMOState();
}

class _TOLiftMOState extends State<TOLiftMO> {
  final keyNameTO1 = GlobalKey<FormState>();
  TextEditingController addNewNameTO = TextEditingController();
  bool openBoolTo1 = false;

  @override
  void initState() {
    saveTO1 = false;
    saveTO2 = false;
    saveTO3 = false;
    saveTO4 = false;
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Текст кнопка закрыть
          Row(
            children: [
              /// Текст
              Row(
                children: [
                  Text(
                    'Создать шаблон ТО  Лифт с МП',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: size.width > 570.0 ? 25.0 : 16.0),
                  ),
                ],
              ),
              const Spacer(),
              /// кнопка закрыть
              IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.close,
                    color: ColorApp.myColorGreenAuth,
                  )),
            ],
          ),
          const SizedBox(height: 20.0),
          Column(
            children: [
              /// Кнопка TO 1 и 3
              Row(
                children: [
                  /// Кнопка TO 1
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: saveTO1 == true ? Colors.grey :  Colors.lightGreen,
                          padding: const EdgeInsets.symmetric(vertical: 20.0)),
                      onPressed: saveTO1 == true ? (){} :  (){
                        setState(() {
                          showDialog(
                              context: context,
                              builder: (context) =>
                                  AlertDialog(
                                      content: StreamBuilder(
                                          stream: myStream.stream,
                                          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                            return  SizedBox(
                                              width: 800.0,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  /// Текст кнопка закрыть
                                                  Row(
                                                    children: [
                                                      /// Текст
                                                      Text(
                                                        'Добавить ТО 1',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                      ),
                                                      const SizedBox(width: 20.0),
                                                      const Spacer(),
                                                      /// кнопка закрыть
                                                      IconButton(
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                          },
                                                          icon: const Icon(
                                                            Icons.close,
                                                            color: ColorApp.myColorGreenAuth,
                                                          )),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  /// Добавление нового пункта в ТО'
                                                  Padding(
                                                    padding: const EdgeInsets.all(5.0),
                                                    child: SizedBox(
                                                      height: 45.0,
                                                      child: Form(
                                                        key: keyNameTO1,
                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                        child: TextFormField(
                                                          validator: (value) {
                                                            if (value!.isEmpty) {
                                                              return 'Заполните название';
                                                            } else {
                                                              return null;
                                                            }
                                                          },
                                                          cursorColor: ColorApp.myColorGray,
                                                          controller: addNewNameTO,
                                                          decoration:  InputDecoration(
                                                              suffixIcon: IconButton(onPressed: (){
                                                                if(addNewNameTO.text.isNotEmpty){
                                                                  liftMOTO1.add({"text" : addNewNameTO.text, "bool" : false});
                                                                  openBoolTo1 = false;
                                                                  myStream.add(IntTest.indexScreens);
                                                                  addNewNameTO.clear();
                                                                }
                                                                // openBoolTo1 = false;
                                                                addNewNameTO.clear();
                                                                // keyNameTO1.currentState!.validate();

                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                              labelText: 'Добавление нового пункта в ТО',
                                                              border: const OutlineInputBorder(),
                                                              focusedBorder: const OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: ColorApp.myColorGreenAuth),
                                                              ),
                                                              // labelText: 'Документ',
                                                              labelStyle:
                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15.0),
                                                  /// Список ТО
                                                  SizedBox(
                                                    height: MediaQuery.of(context).size.height * 0.60,
                                                    child: ListView.builder(
                                                      itemCount: liftMOTO1.length,
                                                      itemBuilder: (context, index) {
                                                        final text = liftMOTO1[index]['text'];
                                                        return Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                child: Container(
                                                                  padding: const EdgeInsets.all(10.0),
                                                                  decoration: BoxDecoration(
                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                  ),
                                                                  child: Text('$text'),
                                                                ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                                onPressed: (){
                                                                  liftMOTO1.removeAt(index);
                                                                  myStream.add(IntTest.indexScreens);
                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  MainButtonApp(
                                                      textButton: 'Добавить',
                                                      press: () async {
                                                        createTemplateTO(listSelectedObject['data']['factory_model_id']['id'],1,liftMOTO1);
                                                        saveTO1 = true;
                                                        myStream.add(IntTest.indexScreens);
                                                        Navigator.pop(context);
                                                        setState(() {});
                                                      }
                                                  ),
                                                ],
                                              ),
                                            );})
                                  ));
                        });
                      },
                      child: Text(saveTO1 == true ? 'Создано' : 'TO 1',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  /// Кнопка TO 3
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: saveTO2 == true ? Colors.grey :  Colors.lightGreen,
                          padding: const EdgeInsets.symmetric(vertical: 20.0)),
                      onPressed: saveTO2 == true ? (){} : (){
                        setState(() {
                          showDialog(
                              context: context,
                              builder: (context) =>
                                  AlertDialog(
                                      content: StreamBuilder(
                                          stream: myStream.stream,
                                          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                            return  SizedBox(
                                              width: 800.0,
                                              child: Column(
                                                children: [
                                                  /// Текст кнопка закрыть
                                                  Row(
                                                    children: [
                                                      /// Текст
                                                      Text(
                                                        'Добавить ТО 3',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                      ),
                                                      const Spacer(),
                                                      /// кнопка закрыть
                                                      IconButton(
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                          },
                                                          icon: const Icon(
                                                            Icons.close,
                                                            color: ColorApp.myColorGreenAuth,
                                                          )),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  /// Добавление нового пункта в ТО'
                                                  Padding(
                                                    padding: const EdgeInsets.all(5.0),
                                                    child: SizedBox(
                                                      height: 45.0,
                                                      child: Form(
                                                        key: keyNameTO1,
                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                        child: TextFormField(
                                                          // validator: (value) {
                                                          //   if (value!.isEmpty) {
                                                          //     return 'Заполните название';
                                                          //   } else {
                                                          //     return null;
                                                          //   }
                                                          // },
                                                          cursorColor: ColorApp.myColorGray,
                                                          controller: addNewNameTO,
                                                          decoration:  InputDecoration(
                                                              suffixIcon: IconButton(onPressed: (){
                                                                if(addNewNameTO.text.isNotEmpty){
                                                                  liftMOTO3.add({"text" : addNewNameTO.text, "bool" : false});
                                                                  print(addNewNameTO.text);
                                                                  openBoolTo1 = false;
                                                                  myStream.add(IntTest.indexScreens);
                                                                  addNewNameTO.clear();
                                                                }
                                                                // openBoolTo1 = false;
                                                                addNewNameTO.clear();
                                                                // keyNameTO1.currentState!.validate();

                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                              labelText: 'Добавление нового пункта в ТО',
                                                              border: const OutlineInputBorder(),
                                                              focusedBorder: const OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: ColorApp.myColorGreenAuth),
                                                              ),
                                                              // labelText: 'Документ',
                                                              labelStyle:
                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15.0),
                                                  /// Список ТО
                                                  SizedBox(
                                                    height: MediaQuery.of(context).size.height * 0.60,
                                                    child: ListView.builder(
                                                      itemCount: liftMOTO3.length,
                                                      itemBuilder: (context, index) {
                                                        final text = liftMOTO3[index]['text'];
                                                        return Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                child: Container(
                                                                  padding: const EdgeInsets.all(10.0),
                                                                  decoration: BoxDecoration(
                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                  ),
                                                                  child: Text('$text'),
                                                                ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                                onPressed: (){
                                                                  liftMOTO3.removeAt(index);
                                                                  myStream.add(IntTest.indexScreens);
                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  /// Кнопка
                                                  MainButtonApp(
                                                      textButton: 'Добавить',
                                                      press: () async {
                                                        await createTemplateTO(listSelectedObject['data']['factory_model_id']['id'],3,liftMOTO3);
                                                        saveTO2 = true;
                                                        myStream.add(IntTest.indexScreens);
                                                        Navigator.pop(context);
                                                        setState(() {});
                                                      }
                                                  ),
                                                ],
                                              ),
                                            );})

                                  ));
                        });
                      },
                      child: Text(saveTO2 == true ? 'Создано' :  'TO 3',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              /// Кнопка TO 6 и 12
              Row(
                children: [
                  /// Кнопка TO 6
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: saveTO3 == true ? Colors.grey : Colors.lightGreen,
                          padding: const EdgeInsets.symmetric(vertical: 20.0)),
                      onPressed: saveTO3 == true ? (){} : (){
                        setState(() {
                          showDialog(
                              context: context,
                              builder: (context) =>
                                  AlertDialog(
                                      content: StreamBuilder(
                                          stream: myStream.stream,
                                          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                            return SizedBox(
                                              width: 800.0,
                                              child: Column(
                                                children: [
                                                  /// Текст кнопка закрыть
                                                  Row(
                                                    children: [
                                                      /// Текст
                                                      Text(
                                                        'Добавить ТО 6',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                      ),
                                                      const Spacer(),
                                                      /// кнопка закрыть
                                                      IconButton(
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                          },
                                                          icon: const Icon(
                                                            Icons.close,
                                                            color: ColorApp.myColorGreenAuth,
                                                          )),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  /// Добавление нового пункта в ТО'
                                                  Padding(
                                                    padding: const EdgeInsets.all(5.0),
                                                    child: SizedBox(
                                                      height: 45.0,
                                                      child: Form(
                                                        key: keyNameTO1,
                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                        child: TextFormField(
                                                          validator: (value) {
                                                            if (value!.isEmpty) {
                                                              return 'Заполните название';
                                                            } else {
                                                              return null;
                                                            }
                                                          },
                                                          cursorColor: ColorApp.myColorGray,
                                                          controller: addNewNameTO,
                                                          decoration:  InputDecoration(
                                                              suffixIcon: IconButton(onPressed: (){
                                                                if(addNewNameTO.text.isNotEmpty){
                                                                  liftMOTO6A.add({"text" : addNewNameTO.text, "bool" : false});
                                                                  print(addNewNameTO.text);
                                                                  openBoolTo1 = false;
                                                                  myStream.add(IntTest.indexScreens);
                                                                  addNewNameTO.clear();
                                                                }
                                                                // openBoolTo1 = false;
                                                                addNewNameTO.clear();
                                                                // keyNameTO1.currentState!.validate();

                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                              labelText: 'Добавление нового пункта в ТО',
                                                              border: const OutlineInputBorder(),
                                                              focusedBorder: const OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: ColorApp.myColorGreenAuth),
                                                              ),
                                                              // labelText: 'Документ',
                                                              labelStyle:
                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15.0),
                                                  /// Список ТО
                                                  SizedBox(
                                                    height: MediaQuery.of(context).size.height * 0.60,
                                                    child: ListView.builder(
                                                      itemCount: liftMOTO6A.length,
                                                      itemBuilder: (context, index) {
                                                        final text = liftMOTO6A[index]['text'];
                                                        return Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                child: Container(
                                                                  padding: const EdgeInsets.all(10.0),
                                                                  decoration: BoxDecoration(
                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                  ),
                                                                  child: Text('$text'),
                                                                ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                                onPressed: (){
                                                                  liftMOTO6A.removeAt(index);
                                                                  myStream.add(IntTest.indexScreens);
                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  /// Кноака добавить
                                                  MainButtonApp(
                                                      textButton: 'Добавить',
                                                      press: () async {
                                                        await createTemplateTO(listSelectedObject['data']['factory_model_id']['id'],6,liftMOTO6A);
                                                        saveTO3 = true;
                                                        myStream.add(IntTest.indexScreens);
                                                        Navigator.pop(context);
                                                        setState(() {});
                                                      }
                                                  ),
                                                ],
                                              ),
                                            );})

                                  ));
                        });
                      },
                      child: Text(saveTO3 == true ? 'Создано' :  'TO 6',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  /// Кнопка TO 12
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: saveTO4 == true ? Colors.grey : Colors.lightGreen,
                          padding: const EdgeInsets.symmetric(vertical: 20.0)),
                      onPressed: saveTO4 == true ? (){} : (){
                        setState(() {
                          showDialog(
                              context: context,
                              builder: (context) =>
                                  AlertDialog(
                                      content: StreamBuilder(
                                          stream: myStream.stream,
                                          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                            return   SizedBox(
                                              width: 800.0,
                                              child: Column(
                                                children: [
                                                  /// Текст кнопка закрыть
                                                  Row(
                                                    children: [
                                                      /// Текст
                                                      Text(
                                                        'Добавить ТО 12',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                      ),
                                                      const Spacer(),
                                                      /// кнопка закрыть
                                                      IconButton(
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                          },
                                                          icon: const Icon(
                                                            Icons.close,
                                                            color: ColorApp.myColorGreenAuth,
                                                          )),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  /// Добавление нового пункта в ТО'
                                                  Padding(
                                                    padding: const EdgeInsets.all(5.0),
                                                    child: SizedBox(
                                                      height: 45.0,
                                                      child: Form(
                                                        key: keyNameTO1,
                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                        child: TextFormField(
                                                          // validator: (value) {
                                                          //   if (value!.isEmpty) {
                                                          //     return 'Заполните название';
                                                          //   } else {
                                                          //     return null;
                                                          //   }
                                                          // },
                                                          cursorColor: ColorApp.myColorGray,
                                                          controller: addNewNameTO,
                                                          decoration:  InputDecoration(
                                                              suffixIcon: IconButton(onPressed: (){
                                                                if(addNewNameTO.text.isNotEmpty){
                                                                  liftMOTO12A.add({"text" : addNewNameTO.text, "bool" : false});
                                                                  print(addNewNameTO.text);
                                                                  openBoolTo1 = false;
                                                                  myStream.add(IntTest.indexScreens);
                                                                  addNewNameTO.clear();
                                                                }
                                                                // openBoolTo1 = false;
                                                                addNewNameTO.clear();
                                                                // keyNameTO1.currentState!.validate();

                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                              labelText: 'Добавление нового пункта в ТО',
                                                              border: const OutlineInputBorder(),
                                                              focusedBorder: const OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: ColorApp.myColorGreenAuth),
                                                              ),
                                                              // labelText: 'Документ',
                                                              labelStyle:
                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15.0),
                                                  /// Список ТО
                                                  SizedBox(
                                                    height: MediaQuery.of(context).size.height * 0.60,
                                                    child: ListView.builder(
                                                      itemCount: liftMOTO12A.length,
                                                      itemBuilder: (context, index) {
                                                        final text = liftMOTO12A[index]['text'];
                                                        return Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                child: Container(
                                                                  padding: const EdgeInsets.all(10.0),
                                                                  decoration: BoxDecoration(
                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                  ),
                                                                  child: Text('$text'),
                                                                ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                                onPressed: (){
                                                                  liftMOTO12A.removeAt(index);
                                                                  myStream.add(IntTest.indexScreens);
                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  /// Кнопка добавить
                                                  MainButtonApp(
                                                      textButton: 'Добавить',
                                                      press: () async {
                                                        await createTemplateTO(listSelectedObject['data']['factory_model_id']['id'],12,liftMOTO12A);
                                                        await getAllTemplateTOInIdObject(IntTest.pressHover);
                                                        saveTO4 = true;
                                                        myStream.add(IntTest.indexScreens);
                                                        Navigator.pop(context);
                                                        setState(() {});
                                                      }
                                                  ),
                                                ],
                                              ),
                                            );})

                                  ));
                        });
                      },
                      child: Text(saveTO4 == true ? 'Создано' : 'TO 12',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              /// Кнопка создать новое TO
              // Row(
              //   children: [
              //     Expanded(
              //       child: ElevatedButton(
              //         style: ElevatedButton.styleFrom(
              //             primary: Colors.lightGreen,
              //             padding: const EdgeInsets.symmetric(vertical: 20.0)),
              //         onPressed: (){
              //           setState(() {
              //             showDialog(
              //                 context: context,
              //                 builder: (context) =>
              //                     AlertDialog(
              //                         content: StreamBuilder(
              //                             stream: myStream.stream,
              //                             builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              //                               return SizedBox(
              //                                 width: 800.0,
              //                                 child: Column(
              //                                   children: [
              //                                     /// Текст кнопка закрыть
              //                                     Row(
              //                                       children: [
              //                                         /// Текст
              //                                         Row(
              //                                           children: [
              //                                             Text(
              //                                               'Создать новое ТО',
              //                                               style: TextStyle(
              //                                                   fontWeight: FontWeight.w700,
              //                                                   fontSize: size.width > 570.0 ? 25.0 : 16.0),
              //                                             ),
              //                                             const SizedBox(width: 20.0),
              //                                             SizedBox(
              //                                               height: 40.0,
              //                                               width: 70.0,
              //                                               child: TextFormField(
              //                                                 validator: (value) {
              //                                                   if (value!.isEmpty) {
              //                                                     return 'Заполните № ТО';
              //                                                   } else {
              //                                                     return null;
              //                                                   }
              //                                                 },
              //                                                 cursorColor: ColorApp.myColorGray,
              //                                                 controller: addNumberTO,
              //                                                 decoration:  const InputDecoration(
              //                                                   // suffixIcon: IconButton(onPressed: (){
              //                                                   //   if(addNewNameTO.text.isNotEmpty){
              //                                                   //     newListTO.add(addNewNameTO.text);
              //                                                   //     print(addNewNameTO.text);
              //                                                   //     openBoolTo1 = false;
              //                                                   //     myStream.add(IntTest.indexScreens);
              //                                                   //     addNewNameTO.clear();
              //                                                   //   }
              //                                                   //   // openBoolTo1 = false;
              //                                                   //   addNewNameTO.clear();
              //                                                   //   // keyNameTO1.currentState!.validate();
              //                                                   //
              //                                                   // }, icon: const Icon(Icons.send,color: Colors.green)),
              //                                                   // labelText: 'Добавление нового пункта в ТО',
              //                                                     border: OutlineInputBorder(),
              //                                                     focusedBorder: OutlineInputBorder(
              //                                                       borderSide: BorderSide(
              //                                                           color: ColorApp.myColorGreenAuth),
              //                                                     ),
              //                                                     labelText: '№ ТО',
              //                                                     labelStyle:
              //                                                     TextStyle(color: ColorApp.myColorGray)),
              //                                               ),
              //                                             ),
              //                                           ],
              //                                         ),
              //                                         const Spacer(),
              //                                         /// кнопка закрыть
              //                                         IconButton(
              //                                             onPressed: () {
              //                                               Navigator.pop(context);
              //                                             },
              //                                             icon: const Icon(
              //                                               Icons.close,
              //                                               color: ColorApp.myColorGreenAuth,
              //                                             )),
              //                                       ],
              //                                     ),
              //                                     const SizedBox(height: 20.0),
              //                                     /// Добавление нового пункта в ТО'
              //                                     Padding(
              //                                       padding: const EdgeInsets.all(5.0),
              //                                       child: SizedBox(
              //                                         height: 45.0,
              //                                         child: Form(
              //                                           key: keyNameTO1,
              //                                           autovalidateMode: AutovalidateMode.onUserInteraction,
              //                                           child: TextFormField(
              //                                             // validator: (value) {
              //                                             //   if (value!.isEmpty) {
              //                                             //     return 'Заполните название';
              //                                             //   } else {
              //                                             //     return null;
              //                                             //   }
              //                                             // },
              //                                             cursorColor: ColorApp.myColorGray,
              //                                             controller: addNewNameTO,
              //                                             decoration:  InputDecoration(
              //                                                 suffixIcon: IconButton(onPressed: (){
              //                                                   if(addNewNameTO.text.isNotEmpty){
              //                                                     newTOLiftNotMO.add(addNewNameTO.text);
              //                                                     print(addNewNameTO.text);
              //                                                     openBoolTo1 = false;
              //                                                     myStream.add(IntTest.indexScreens);
              //                                                     addNewNameTO.clear();
              //                                                   }
              //                                                   // openBoolTo1 = false;
              //                                                   addNewNameTO.clear();
              //                                                   // keyNameTO1.currentState!.validate();
              //
              //                                                 }, icon: const Icon(Icons.send,color: Colors.green)),
              //                                                 labelText: 'Добавление нового пункта в ТО',
              //                                                 border: const OutlineInputBorder(),
              //                                                 focusedBorder: const OutlineInputBorder(
              //                                                   borderSide: BorderSide(
              //                                                       color: ColorApp.myColorGreenAuth),
              //                                                 ),
              //                                                 // labelText: 'Документ',
              //                                                 labelStyle:
              //                                                 const TextStyle(color: ColorApp.myColorGray)),
              //                                           ),
              //                                         ),
              //                                       ),
              //                                     ),
              //                                     const SizedBox(height: 15.0),
              //                                     /// Список нового ТО
              //                                     SizedBox(
              //                                       height: MediaQuery.of(context).size.height * 0.60,
              //                                       child: ListView.builder(
              //                                         itemCount: newTOLiftNotMO.length,
              //                                         itemBuilder: (context, index) {
              //                                           final text = newTOLiftNotMO[index];
              //                                           return Row(
              //                                             crossAxisAlignment: CrossAxisAlignment.center,
              //                                             children: [
              //                                               Expanded(
              //                                                 child: Padding(
              //                                                   padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
              //                                                   child: Container(
              //                                                     padding: const EdgeInsets.all(10.0),
              //                                                     decoration: BoxDecoration(
              //                                                         borderRadius: BorderRadius.circular(5.0),
              //                                                         border: Border.all(color: Colors.grey, width: 1.5)
              //                                                     ),
              //                                                     child: Text('$text'),
              //                                                   ),
              //                                                 ),
              //                                               ),
              //                                               IconButton(
              //                                                   onPressed: (){
              //                                                     newTOLiftNotMO.removeAt(index);
              //                                                     myStream.add(IntTest.indexScreens);
              //                                                   }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
              //                                             ],
              //                                           );
              //                                         },
              //                                       ),
              //                                     ),
              //                                     const SizedBox(height: 20.0),
              //                                     /// Кнопка добавить
              //                                     MainButtonApp(
              //                                         textButton: 'Добавить',
              //                                         press: () async {
              //                                           if(addNumberTO.text.isNotEmpty){
              //                                             myStream.add(IntTest.indexScreens);
              //                                             Navigator.pop(context);
              //                                           }
              //                                           keyNumberTO.currentState!.validate();
              //                                           setState(() {});
              //                                         }
              //                                     ),
              //
              //                                   ],
              //                                 ),
              //                               );})
              //
              //                     ));
              //           });
              //         },
              //         child: const Text(
              //           'Создать новое TO',
              //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ],
      ),
    );
  }
}



