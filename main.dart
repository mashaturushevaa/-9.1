import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Обов'язково перед ініціалізацією SharedPreferences [cite: 157]
  await PreferencesManager.getInstance(); // Ініціалізуємо Singleton [cite: 158]
  runApp(const MyApp());
}

// ==========================================
// СЕРВІС (Singleton Pattern) [cite: 160]
// ==========================================
class PreferencesManager {
  static PreferencesManager? _instance; // [cite: 162]
  static SharedPreferences? _prefs; // [cite: 163]

  PreferencesManager._(); // Приватний конструктор

  static Future<PreferencesManager> getInstance() async { // [cite: 164]
    if (_instance == null) {
      _instance = PreferencesManager._(); // [cite: 165]
      _prefs = await SharedPreferences.getInstance(); // [cite: 167]
    }
    return _instance!; // [cite: 166]
  }

  // Ключі для збереження даних
  static const String _keyName = 'profile_name';
  static const String _keyEmail = 'profile_email';
  static const String _keyAge = 'profile_age';
  
  static const String _keyIsDarkMode = 'ui_dark_mode';
  static const String _keyFontSize = 'ui_font_size';
  static const String _keyLanguage = 'ui_language';
  static const String _keyCompactMode = 'ui_compact_mode';
  
  static const String _keyPushNotifications = 'notif_push';

  // --- READ (Getters) ---
  String get name => _prefs?.getString(_keyName) ?? '';
  String get email => _prefs?.getString(_keyEmail) ?? '';
  int get age => _prefs?.getInt(_keyAge) ?? 18; // [cite: 17]
  
  bool get isDarkMode => _prefs?.getBool(_keyIsDarkMode) ?? false; // [cite: 18]
  double get fontSize => _prefs?.getDouble(_keyFontSize) ?? 14.0; // [cite: 18]
  String get language => _prefs?.getString(_keyLanguage) ?? 'Українська'; // [cite: 18]
  bool get isCompactMode => _prefs?.getBool(_keyCompactMode) ?? false; // [cite: 18]
  
  bool get pushNotifications => _prefs?.getBool(_keyPushNotifications) ?? true; // [cite: 18]

  // --- CREATE / UPDATE (Setters) ---
  Future<void> setName(String value) async => await _prefs?.setString(_keyName, value);
  Future<void> setEmail(String value) async => await _prefs?.setString(_keyEmail, value);
  Future<void> setAge(int value) async => await _prefs?.setInt(_keyAge, value);
  
  Future<void> setDarkMode(bool value) async => await _prefs?.setBool(_keyIsDarkMode, value);
  Future<void> setFontSize(double value) async => await _prefs?.setDouble(_keyFontSize, value);
  Future<void> setLanguage(String value) async => await _prefs?.setString(_keyLanguage, value);
  Future<void> setCompactMode(bool value) async => await _prefs?.setBool(_keyCompactMode, value);
  
  Future<void> setPushNotifications(bool value) async => await _prefs?.setBool(_keyPushNotifications, value);

  // --- DELETE (Reset to defaults) ---
  Future<void> resetToDefaults() async {
    await _prefs?.clear(); // Очищає всі дані
  }

  // Експорт у формат JSON (Map) [cite: 28]
  Map<String, dynamic> exportToJson() {
    return {
      'profile': {'name': name, 'email': email, 'age': age},
      'ui': {'darkMode': isDarkMode, 'fontSize': fontSize, 'language': language, 'compact': isCompactMode},
      'notifications': {'push': pushNotifications}
    };
  }
}

// ==========================================
// ГОЛОВНИЙ ВІДЖЕТ ДОДАТКУ
// ==========================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Для динамічної зміни теми на рівні всього додатку
  bool _isDarkTheme = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await PreferencesManager.getInstance();
    setState(() {
      _isDarkTheme = prefs.isDarkMode;
    });
  }

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkTheme = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Settings Manager',
      theme: _isDarkTheme ? ThemeData.dark() : ThemeData.light(), // Застосування теми в реальному часі [cite: 30]
      home: SettingsScreen(onThemeChanged: _toggleTheme),
    );
  }
}

// ==========================================
// ЕКРАН НАЛАШТУВАНЬ (UI)
// ==========================================
class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late PreferencesManager _prefs;
  bool _isLoading = true;

  // Контролери для TextField [cite: 21]
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // Локальні змінні стану для UI
  int _age = 18;
  bool _isDark = false;
  double _fontSize = 14.0;
  String _language = 'Українська';
  bool _isCompact = false;
  bool _pushNotifications = true;

  final List<String> _languages = ['Українська', 'English', 'Polski'];

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  // Завантаження збережених даних
  Future<void> _initSettings() async {
    _prefs = await PreferencesManager.getInstance();
    setState(() {
      _nameController.text = _prefs.name;
      _emailController.text = _prefs.email;
      _age = _prefs.age;
      
      _isDark = _prefs.isDarkMode;
      _fontSize = _prefs.fontSize;
      _language = _prefs.language;
      _isCompact = _prefs.isCompactMode;
      
      _pushNotifications = _prefs.pushNotifications;
      
      _isLoading = false;
    });
  }

  // Показ повідомлення про збереження [cite: 29]
  void _showSaveNotification() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Налаштування збережено (Auto-save)'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Скидання налаштувань [cite: 27]
  Future<void> _resetSettings() async {
    await _prefs.resetToDefaults();
    await _initSettings(); // Перезавантажуємо UI
    widget.onThemeChanged(false); // Скидаємо глобальну тему
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Скинуто до типових налаштувань')),
      );
    }
  }

  // Експорт в JSON [cite: 28]
  void _exportSettings() {
    final jsonData = jsonEncode(_prefs.exportToJson());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Експорт (JSON)'),
        content: SingleChildScrollView(child: Text(jsonData)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Закрити'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Динамічний стиль тексту (залежить від налаштувань) [cite: 30]
    final textStyle = TextStyle(fontSize: _fontSize);
    final headerStyle = TextStyle(fontSize: _fontSize + 4, fontWeight: FontWeight.bold, color: Colors.blueAccent);
    
    // Компактний режим (впливає на відступи) [cite: 18, 30]
    final padding = _isCompact ? const EdgeInsets.all(8.0) : const EdgeInsets.all(16.0);
    final spacing = _isCompact ? 10.0 : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Менеджер налаштувань'),
        actions: [
          IconButton(icon: const Icon(Icons.code), onPressed: _exportSettings, tooltip: 'Експортувати'), // [cite: 28]
          IconButton(icon: const Icon(Icons.restore), onPressed: _resetSettings, tooltip: 'Скинути'), // [cite: 27]
        ],
      ),
      body: ListView(
        padding: padding,
        children: [
          // --- ПРОФІЛЬ --- [cite: 17, 21]
          Text('Профіль', style: headerStyle),
          SizedBox(height: spacing / 2),
          TextField(
            controller: _nameController,
            style: textStyle,
            decoration: const InputDecoration(labelText: "Ім'я", border: OutlineInputBorder()),
            onChanged: (val) {
              _prefs.setName(val); // Auto-save [cite: 26]
              _showSaveNotification();
            },
          ),
          SizedBox(height: spacing / 2),
          TextField(
            controller: _emailController,
            style: textStyle,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
            onChanged: (val) {
              _prefs.setEmail(val); // Auto-save [cite: 26]
              _showSaveNotification();
            },
          ),
          SizedBox(height: spacing / 2),
          Row(
            children: [
              Text('Вік: $_age', style: textStyle),
              Slider( // Замість NumberPicker використовуємо Slider для простоти базових віджетів
                value: _age.toDouble(),
                min: 10,
                max: 100,
                divisions: 90,
                onChanged: (val) {
                  setState(() => _age = val.toInt());
                  _prefs.setAge(_age); // Auto-save [cite: 26]
                },
              )
            ],
          ),

          Divider(height: spacing * 2),

          // --- ВИГЛЯД --- [cite: 18, 22]
          Text('Вигляд', style: headerStyle),
          SwitchListTile(
            title: Text('Темна тема', style: textStyle),
            value: _isDark,
            onChanged: (val) {
              setState(() => _isDark = val);
              _prefs.setDarkMode(val); // Auto-save [cite: 26]
              widget.onThemeChanged(val); // Застосування в реальному часі [cite: 30]
              _showSaveNotification();
            },
          ),
          SwitchListTile(
            title: Text('Компактний режим', style: textStyle),
            value: _isCompact,
            onChanged: (val) {
              setState(() => _isCompact = val);
              _prefs.setCompactMode(val); // Auto-save [cite: 26]
              _showSaveNotification();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Мова', style: textStyle),
                DropdownButton<String>( // [cite: 22]
                  value: _language,
                  items: _languages.map((String lang) {
                    return DropdownMenuItem(value: lang, child: Text(lang, style: textStyle));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _language = val);
                      _prefs.setLanguage(val); // Auto-save [cite: 26]
                      _showSaveNotification();
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text('Шрифт (${_fontSize.toInt()})', style: textStyle),
                Expanded(
                  child: Slider( // [cite: 22]
                    value: _fontSize,
                    min: 12,
                    max: 24,
                    divisions: 12,
                    onChanged: (val) {
                      setState(() => _fontSize = val);
                      _prefs.setFontSize(val); // Auto-save [cite: 26]
                    },
                  ),
                ),
              ],
            ),
          ),

          Divider(height: spacing * 2),

          // --- СПОВІЩЕННЯ --- [cite: 18, 23]
          Text('Сповіщення', style: headerStyle),
          SwitchListTile(
            title: Text('Push-сповіщення', style: textStyle),
            value: _pushNotifications,
            onChanged: (val) {
              setState(() => _pushNotifications = val);
              _prefs.setPushNotifications(val); // Auto-save [cite: 26]
              _showSaveNotification();
            },
          ),
        ],
      ),
    );
  }
}