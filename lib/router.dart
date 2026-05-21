import 'package:flutter/material.dart';
import 'modules/home/home_page.dart';
import 'modules/notes/note_list_page.dart';
import 'modules/notes/note_edit_page.dart';
import 'modules/todos/todo_list_page.dart';
import 'modules/habits/habit_list_page.dart';
import 'modules/timer/timer_page.dart';
import 'modules/settings/settings_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String notes = '/notes';
  static const String noteEdit = '/notes/edit';
  static const String todos = '/todos';
  static const String habits = '/habits';
  static const String timer = '/timer';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const HomePage(),
    notes: (context) => const NoteListPage(),
    noteEdit: (context) => const NoteEditPage(),
    todos: (context) => const TodoListPage(),
    habits: (context) => const HabitListPage(),
    timer: (context) => const TimerPage(),
    settings: (context) => const SettingsPage(),
  };
}
