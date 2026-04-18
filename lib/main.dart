import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

Widget createAppRoot() {
  return const ProviderScope(child: RentABoxApp());
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(createAppRoot());
}
