// lib/calendar_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'app_language.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'appBar.dart';

/// =====================
/// MODEL
/// =====================
class Reminder {
  final String id;
  final String title;
  final DateTime dateTime;
  final String? note;

  Reminder({
    required this.id,
    required this.title,
    required this.dateTime,
    this.note,
  });
}

DateTime dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// =====================
/// STORE (in-memory)
/// =====================
class ReminderStore extends ChangeNotifier {
  final Map<DateTime, List<Reminder>> _data = {};

  List<Reminder> forDay(DateTime day) {
    final key = dayKey(day);
    final list = _data[key] ?? [];
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return List.unmodifiable(list);
  }

  void add(Reminder r) {
    final key = dayKey(r.dateTime);
    _data.putIfAbsent(key, () => []);
    _data[key]!.add(r);
    notifyListeners();
  }

  void remove(Reminder r) {
    final key = dayKey(r.dateTime);
    _data[key]?.removeWhere((e) => e.id == r.id);
    if (_data[key]?.isEmpty ?? false) _data.remove(key);
    notifyListeners();
  }
}

/// =====================
/// NOTIFICATION SERVICE
/// =====================
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initIfNeeded() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    final tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _ready = true;
  }

  Future<void> schedule(Reminder r) async {
    await initIfNeeded();

    final when = tz.TZDateTime.from(r.dateTime, tz.local);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      r.id.hashCode,
      'Reminder',
      r.title,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(Reminder r) async {
    await initIfNeeded();
    await _plugin.cancel(r.id.hashCode);
  }
}

/// =====================
/// DAY SCHEDULE PAGE (คล้าย Google Calendar แบบง่าย)
/// =====================
class DaySchedulePage extends StatelessWidget {
  final DateTime day;
  final ReminderStore store;

  const DaySchedulePage({super.key, required this.day, required this.store});

  @override
  Widget build(BuildContext context) {
    //final list = store.forDay(day);

    String dateLabel(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text('${AppText.get('reminders')} • ${dateLabel(day)}'),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (_, __) {
          final items = store.forDay(day);

          if (items.isEmpty) {
            return Center(child: Text(AppText.get('noReminder')));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = items[i];
              final t = TimeOfDay.fromDateTime(r.dateTime).format(context);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange, width: 1.6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          if ((r.note ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              r.note!,
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        store.remove(r);
                        await NotificationService.instance.cancel(r);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// =====================
/// CALENDAR PAGE
/// =====================
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final store = ReminderStore();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  static const orange = Color(0xFFFFA726);

  @override
  void initState() {
    super.initState();
    NotificationService.instance.initIfNeeded();
  }

  String monthLabel(DateTime d) {
    return '${AppText.month(d.month)} ${d.year}';
  }

  Future<void> _pickMonth() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select Month',
    );
    if (d != null) {
      setState(() => _focusedDay = DateTime(d.year, d.month, 1));
    }
  }

  Future<void> _addReminder({DateTime? preset}) async {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime date = preset ?? _selectedDay;
    TimeOfDay time = TimeOfDay.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppText.get('addReminder'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(labelText: AppText.get('title')),
            ),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(labelText: AppText.get('note')),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    child: Text(
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                    ),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) date = d;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    child: Text(time.format(context)),
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (t != null) time = t;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;

                final dt = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );

                final r = Reminder(
                  id: '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}',
                  title: titleCtrl.text.trim(),
                  dateTime: dt,
                  note: noteCtrl.text.trim().isEmpty
                      ? null
                      : noteCtrl.text.trim(),
                );

                store.add(r);
                await NotificationService.instance.schedule(r);

                if (mounted) Navigator.pop(context);
              },
              child: Text(AppText.get('save')),
            ),
          ],
        ),
      ),
    );
  }

  Color _eventColor(Reminder r) {
    // โทนสีหลากหลายเหมือนตัวอย่าง (เดิมสีส้มเป็นกรอบอยู่แล้ว)
    final colors = <Color>[
      const Color(0xFFE57373), // red
      const Color(0xFF64B5F6), // blue
      const Color(0xFF81C784), // green
      const Color(0xFFBA68C8), // purple
      const Color(0xFFFFB74D), // orange
      const Color(0xFF4DB6AC), // teal
    ];
    final idx = r.title.hashCode.abs() % colors.length;
    return colors[idx];
  }

  Widget _dayCell({
    required DateTime day,
    required bool isOutside,
    required bool isSelected,
    required bool isToday,
  }) {
    final events = store.forDay(day);
    final borderColor = orange;

    final bg = isSelected
        ? orange.withValues(alpha: 51)
        : (isToday ? const Color(0xFFE8EDFF) : Colors.white);

    final textColor = isOutside ? Colors.grey.shade400 : Colors.black87;

    final first = events.isNotEmpty ? events.first : null;

    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 2.5),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          if (first != null)
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _eventColor(first),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  first.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          // ถ้ามีหลายอัน ให้แสดงจุดเล็ก ๆ เพิ่ม (เหมือน indicator)
          if (events.length > 1)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    min(events.length, 3),
                    (_) => Container(
                      margin: const EdgeInsets.only(left: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // โทนพื้นหลังแบบนุ่ม ๆ เหมือน mockup
    const bg = Color(0xFFF6F8ED);

    return Scaffold(
      backgroundColor: bg,
      appBar: MyAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            /// LEFT PANEL
            SizedBox(
              width: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month pill
                  InkWell(
                    onTap: _pickMonth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: orange,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        monthLabel(_focusedDay),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reminder Box
                  Expanded(
                    child: AnimatedBuilder(
                      animation: store,
                      builder: (_, __) {
                        final list = store.forDay(_selectedDay);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: orange, width: 3),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    AppText.get('reminders'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 22),
                                    onPressed: () =>
                                        _addReminder(preset: _selectedDay),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: list.isEmpty
                                    ? Center(
                                        child: Text(AppText.get('noReminder')),
                                      )
                                    : ListView.separated(
                                        itemCount: list.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (_, i) {
                                          final r = list[i];
                                          final t = TimeOfDay.fromDateTime(
                                            r.dateTime,
                                          ).format(context);

                                          return Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 10,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: _eventColor(r),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        r.title,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        t,
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey
                                                              .shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 20,
                                                  ),
                                                  onPressed: () async {
                                                    store.remove(r);
                                                    await NotificationService
                                                        .instance
                                                        .cancel(r);
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // CALENDAR
            Expanded(
              child: AnimatedBuilder(
                animation: store,
                builder: (_, __) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weekday header row
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 6,
                          right: 6,
                          bottom: 6,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Text(
                                  AppText.weekday(0),
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  AppText.weekday(1),
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  AppText.weekday(2),
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  AppText.weekday(3),
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  AppText.weekday(4),
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  AppText.weekday(5),
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  AppText.weekday(6),
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: TableCalendar(
                          firstDay: DateTime(2000),
                          lastDay: DateTime(2100),
                          focusedDay: _focusedDay,
                          headerVisible: false,
                          calendarFormat: CalendarFormat.month,
                          selectedDayPredicate: (d) =>
                              isSameDay(d, _selectedDay),
                          eventLoader: (d) => store.forDay(d),
                          daysOfWeekVisible: false,
                          rowHeight: 110,

                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DaySchedulePage(
                                  day: dayKey(selectedDay),
                                  store: store,
                                ),
                              ),
                            );
                          },

                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) {
                              return _dayCell(
                                day: day,
                                isOutside: false,
                                isSelected: isSameDay(day, _selectedDay),
                                isToday: isSameDay(day, DateTime.now()),
                              );
                            },
                            todayBuilder: (context, day, focusedDay) {
                              return _dayCell(
                                day: day,
                                isOutside: false,
                                isSelected: isSameDay(day, _selectedDay),
                                isToday: true,
                              );
                            },
                            selectedBuilder: (context, day, focusedDay) {
                              return _dayCell(
                                day: day,
                                isOutside: false,
                                isSelected: true,
                                isToday: isSameDay(day, DateTime.now()),
                              );
                            },
                            outsideBuilder: (context, day, focusedDay) {
                              return _dayCell(
                                day: day,
                                isOutside: true,
                                isSelected: isSameDay(day, _selectedDay),
                                isToday: false,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
