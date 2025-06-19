import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'reminder_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('reminders');

  final provider = ReminderProvider();
  await provider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ReminderScreen(),
    );
  }
}

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final TextEditingController _controller = TextEditingController();

  void handleInput(String text) {
    if (text.isNotEmpty) {
      Provider.of<ReminderProvider>(context, listen: false).addReminder(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminders = Provider.of<ReminderProvider>(context).reminders;

    return Scaffold(
      appBar: AppBar(title: const Text('🧠 Smart Reminder')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "e.g. 'Remind me to drink water at 9 PM'",
              ),
              onSubmitted: handleInput,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: reminders.isEmpty
                  ? const Center(child: Text("No reminders yet"))
                  : ListView.builder(
                      itemCount: reminders.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(reminders[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            Provider.of<ReminderProvider>(context,
                                    listen: false)
                                .removeReminder(index);
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
