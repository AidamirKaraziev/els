/// «Личный кабинет» механика — кадр `1826:283`.
///
/// Данные берём из уже загруженного профиля (`/auth/me`), а не ходим за ними
/// заново: он лежит в `userProfile` с момента входа и обновляется вместе с
/// сессией.
///
/// Отличия от кадра, сделанные сознательно:
///
/// * **Правка профиля (карандаш справа сверху) не подключена.** Подрядчик
///   правил профиль админской ручкой `/cp/admin/universal-user/{id}/`, на
///   которую у механика нет прав — она ответит `403`. Свою ручку правки
///   профиля заводить в рамках каркаса нельзя, поэтому карандаша здесь нет:
///   кнопка, которая отвечает отказом, хуже отсутствующей.
/// * **«Документы» показывают только наличие.** Удостоверение и ЦОК лежат
///   файлами (`identity_card`, `qualification_file`), а просмотрщик файлов —
///   это отдельный экран со скачиванием по короткоживущей ссылке.
/// * **Выход спрашивает подтверждение, если есть неотправленное.** В макете
///   этого нет, но в макете нет и офлайна: молча выкинуть работу, которую
///   человек сделал в подвале без связи, нельзя.
library;

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../../helper/session.dart';
import '../../screns/user/user_contact.dart';
import '../data/mechanic_workspace.dart';
import '../mechanic_theme.dart';

class MechanicProfileScreen extends StatelessWidget {
  const MechanicProfileScreen({Key? key, this.onBack}) : super(key: key);

  /// Возврат на вкладку, с которой сюда пришли. `null` — стрелку не рисуем:
  /// экран открыт не переходом, а сам по себе (так он живёт в тестах).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> profile = userProfile.isNotEmpty
        ? Map<String, dynamic>.from(userProfile[0] as Map)
        : <String, dynamic>{};

    return ListView(
      padding: const EdgeInsets.only(bottom: 32.0),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MechanicLayout.screenPadding,
            24.0,
            MechanicLayout.screenPadding,
            16.0,
          ),
          child: Row(
            children: <Widget>[
              if (onBack != null) ...<Widget>[
                InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(20.0),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.arrow_back, size: 24.0),
                  ),
                ),
                const SizedBox(width: 8.0),
              ],
              const Text('Личный кабинет', style: MechanicLayout.screenTitle),
            ],
          ),
        ),
        _Head(profile: profile),
        const Divider(height: 33.0, thickness: 1.0, color: MechanicLayout.divider),
        _Group(
          label: 'Контакты',
          rows: <Widget>[
            _Row(
              icon: Icons.person_outline,
              label: 'ФИО',
              value: _text(profile['name']),
            ),
            _Row(
              icon: Icons.phone,
              label: 'Номер телефона',
              value: _text(profile['contact_phone']),
            ),
            _Row(
              icon: Icons.mail_outline,
              label: 'Эл.почта',
              value: _text(profile['email']),
            ),
          ],
        ),
        _Group(
          label: 'Информация',
          rows: <Widget>[
            _Row(
              icon: Icons.place_outlined,
              label: 'Участок',
              value: _nested(profile['division_id'], 'title'),
            ),
            _Row(
              icon: Icons.badge_outlined,
              label: 'Должность',
              // Должность человека — это специальность («Механик»), а не роль
              // в системе. Роль совпадает с ней не всегда: инженер-наладчик
              // работает по той же оболочке.
              value: _nested(profile['working_specialty_id'], 'name',
                  fallback: _nested(profile['role_id'], 'name')),
            ),
            _Row(
              icon: Icons.apartment_outlined,
              label: 'Компания',
              value: _nested(profile['company_id'], 'name'),
            ),
          ],
        ),
        _Group(
          label: 'Документы',
          rows: <Widget>[
            _Row(
              icon: Icons.badge_outlined,
              label: 'Удостоверение',
              value: profile['identity_card'] == null ? 'Не загружено' : 'Загружено',
            ),
            _Row(
              icon: Icons.workspace_premium_outlined,
              label: 'ЦОК',
              value:
                  profile['qualification_file'] == null ? 'Не загружено' : 'Загружено',
            ),
          ],
        ),
        const SizedBox(height: 24.0),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MechanicLayout.screenPadding,
          ),
          child: SizedBox(
            height: 50.0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorApp.myColorGreen,
                elevation: 0.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
                ),
              ),
              onPressed: () => _signOut(context),
              child: const Text(
                'Выйти',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                  color: ColorApp.myColorWhite,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Выход с оглядкой на очередь: неотправленное после выхода послать нечем.
  Future<void> _signOut(BuildContext context) async {
    final MechanicWorkspace? workspace = MechanicWorkspace.current;
    final int pending = workspace?.status.value.pending ?? 0;

    if (pending > 0) {
      final bool? leave = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Есть неотправленная работа'),
          content: Text(
            'Не ушло действий: $pending. Они пропадут вместе с выходом — '
            'сначала выйдите на связь.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Остаться'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Выйти и потерять'),
            ),
          ],
        ),
      );
      if (leave != true) return;
    }

    await workspace?.forget();
    await signOut();
  }

  static String _text(dynamic value) {
    final String text = value == null ? '' : '$value'.trim();
    return text.isEmpty ? '—' : text;
  }

  /// Значение из вложенного объекта: бэкенд отдаёт участок, компанию и
  /// специальность объектами, а не строками.
  static String _nested(dynamic value, String field, {String? fallback}) {
    if (value is Map && value[field] != null) {
      final String text = '${value[field]}'.trim();
      if (text.isNotEmpty) return text;
    }
    return fallback ?? '—';
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.profile});

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final String name = MechanicProfileScreen._text(profile['name']);
    final String email = MechanicProfileScreen._text(profile['email']);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MechanicLayout.screenPadding,
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 25.0,
            backgroundColor: ColorApp.myColorAvatar,
            child: Icon(Icons.person, color: ColorApp.myColorWhite),
          ),
          const SizedBox(width: 17.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w700,
                    color: ColorApp.myColorBlack,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  email,
                  style: const TextStyle(fontSize: 14.0, color: Color(0xff545456)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.rows});

  final String label;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MechanicLayout.screenPadding,
            20.0,
            MechanicLayout.screenPadding,
            4.0,
          ),
          child: Text(label, style: MechanicLayout.groupLabel),
        ),
        ...rows,
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: MechanicLayout.screenPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 32.0,
            height: 32.0,
            decoration: const BoxDecoration(
              color: ColorApp.myColorGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18.0, color: ColorApp.myColorWhite),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18.0),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: MechanicLayout.divider),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Text(label, style: MechanicLayout.rowLabel),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: MechanicLayout.rowValue,
                    ),
                  ),
                  const SizedBox(width: MechanicLayout.screenPadding),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
