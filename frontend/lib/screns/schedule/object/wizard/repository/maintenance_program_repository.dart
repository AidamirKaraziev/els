import '../../../repository/schedules_repository.dart';
import '../models/maintenance_program.dart';

/// Откуда мастер берёт программу обслуживания модели и куда её сохраняет.
///
/// Отдельно от [ScheduleWizardRepository]: тот показывает год объекта, а эта
/// программа принадлежит **модели** — её правка касается всех объектов
/// модели, и складывать две разные сущности в один интерфейс значило бы
/// потерять эту границу.
abstract class MaintenanceProgramRepository {
  /// Программа модели. Её нет — `null`, а не исключение: у модели без
  /// программы мастер открывает окно создания, и «нет» здесь не поломка.
  Future<MaintenanceProgram?> program(int modelId);

  /// Раскладка, которую предлагает сам сервер. В базу не пишется: пока
  /// человек не сохранил её, это подсказка, а не программа.
  Future<MaintenanceProgram> suggestion(int modelId);

  /// Справочник видов ТО — из него выбирается вид на позицию.
  Future<List<TypeAct>> typeActs();

  /// Заменить программу модели целиком.
  ///
  /// Двенадцать позиций, каждая с видом ТО: частичной правки у ручки нет, и
  /// позиция без вида ТО — это 422, а не сохранённая наполовину программа.
  Future<void> save(MaintenanceProgram program);
}

/// Программу сохранить не удалось. Текст готовый, прямо от ручки: у 422 она
/// перечисляет, какие позиции не сошлись, и человеку нужен именно он.
class MaintenanceProgramException extends SchedulesException {
  const MaintenanceProgramException(String message) : super(message);
}
