// Centralized providers for the app
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'viewmodels/NotificationsViewModel.dart';
import 'viewmodels/HomeTabbedViewModel.dart';
import 'services/role_service.dart';
import 'services/league_service.dart';
import 'config.dart';

final List<SingleChildWidget> appProviders = [
  ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
  ChangeNotifierProvider(create: (_) => HomeTabbedViewModel()),
  Provider.value(value: RoleService(baseUrl: Config.apiBaseUrl)),
  Provider.value(value: LeagueService(baseUrl: Config.apiBaseUrl)),
];

