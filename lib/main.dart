import 'package:intl/date_symbol_data_local.dart';

import 'src/imports/core_imports.dart';
import 'src/imports/packages_imports.dart';
import 'src/app.dart';
import 'src/config/api/api_session.dart';


Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await EasyLocalization.ensureInitialized();
  // Arabic date symbols for DateFormat (English is built in).
  await initializeDateFormatting('ar');
  await dotenv.load(fileName: '.env');

  await StorageService.instance.init();
  // Device id + stored session must be ready before the first request —
  // and so must the UI language, which `App` only mirrors once it builds:
  // `SessionCubit` calls `/me` before that, from the saved locale.
  await ApiSession.instance.init();
  ApiSession.instance.language =
      StorageService.instance.getString('locale')?.split('_').first ?? 'ar';
  await AppConfig.init();

  runApp(
    const LocalizationWrapper(
      child: StateWrapper(
        child: App(),
      ),
    ),
  );
}