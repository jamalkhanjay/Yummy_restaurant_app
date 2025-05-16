import 'dart:ui';
import 'package:flutter/material.dart';
import 'constants.dart';
import 'home.dart';
import '../models/models.dart';
import 'screens/screens.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const Yummy());
}

/// Allows the ability to scroll by dragging with touch, mouse, and trackpad.
class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class Yummy extends StatefulWidget {
  const Yummy({super.key});

  @override
  State<Yummy> createState() => _YummyState();
}

class _YummyState extends State<Yummy> {
  ThemeMode themeMode = ThemeMode.light;
  ColorSelection colorSelected = ColorSelection.pink;

  /// Authentication to manage user login session
  // ignore: unused_field
  final YummyAuth _auth = YummyAuth();

  /// Manage user's shopping cart for the items they order.
  final CartManager _cartManager = CartManager();

  /// Manage user's orders submitted
  final OrderManager _orderManager = OrderManager();

  late final _router = GoRouter(
    initialLocation: '/login',
    redirect: _appRedirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(
          onLogIn: (Credentials credentials) async {
            _auth.signIn(credentials.username, credentials.password).then(
                  (_) => context.go('/${YummyTab.home.value}'),
                );
          },
        ),
      ),
      GoRoute(
        path: '/:tab',
        builder: (context, state) {
          return Home(
              auth: _auth,
              cartManager: _cartManager,
              ordersManager: _orderManager,
              changeTheme: changeThemeMode,
              changeColor: changeColor,
              colorSelected: colorSelected,
              tab: int.tryParse(state.pathParameters['tab'] ?? '') ?? 0);
        },
        // These are subroutes
        routes: [
          GoRoute(
            path: 'restaurant/:id',
            builder: (context, state) {
              // Extracting id from the route path and then converts it into an
              // integer with int.tryParse If the conversion fails (e.g., if
              // the ID is missing or not a number), it defaults to 0.
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              // Retrieving a single list restaurant from the the list
              final restaurant = restaurants[id];

              return RestaurantPage(
                restaurant: restaurant,
                cartManager: _cartManager,
                ordersManager: _orderManager,
              );
            },
          ),
        ],
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Text(
            state.error.toString(),
          ),
        ),
      ),
    ),
  );

  Future<String?> _appRedirect(
      BuildContext context, GoRouterState state) async {
    final loggedIn = await _auth.loggedIn;
    final isOnLoginPage = state.matchedLocation == '/login';
    // Go to /login if the user is not signed in
    if (!loggedIn) {
      return '/login';
    }
    // Go to root if the user is already signed in
    else if (loggedIn && isOnLoginPage) {
      return '/${YummyTab.home.value}';
    }
    // no redirect
    return null;
  }

  void changeThemeMode(bool useLightMode) {
    setState(() {
      themeMode = useLightMode ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void changeColor(int value) {
    setState(
      () {
        colorSelected = ColorSelection.values[value];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      title: 'Yummy',
      scrollBehavior: CustomScrollBehavior(),
      themeMode: themeMode,
      theme: ThemeData(
        colorSchemeSeed: colorSelected.color,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: colorSelected.color,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
    );
  }
}
