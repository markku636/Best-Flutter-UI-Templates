import 'package:best_flutter_ui_templates/design_course/home_design_course.dart';
import 'package:best_flutter_ui_templates/fitness_app/fitness_app_home_screen.dart';
import 'package:best_flutter_ui_templates/home_screen.dart';
import 'package:best_flutter_ui_templates/hotel_booking/hotel_home_screen.dart';
import 'package:best_flutter_ui_templates/introduction_animation/introduction_animation_screen.dart';
import 'package:best_flutter_ui_templates/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MyApp());
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final workSans = FontLoader('WorkSans')
      ..addFont(rootBundle.load('assets/fonts/WorkSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/WorkSans-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/WorkSans-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/WorkSans-Bold.ttf'));
    final roboto = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    await workSans.load();
    await roboto.load();
  });

  testWidgets('Home shows four demos and switches grid layout', (tester) async {
    await openHome(tester);
    expect(find.text('Flutter UI'), findsOneWidget);
    expect(find.byType(HomeListView), findsNWidgets(4));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.dashboard));
    await tester.pumpAndSettle();
    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      1,
    );
    expect(tester.takeException(), isNull);
  });

  final demos = <(String, Type)>[
    ('Introduction', IntroductionAnimationScreen),
    ('Hotel booking', HotelHomeScreen),
    ('Fitness', FitnessAppHomeScreen),
    ('Design course', DesignCourseHomeScreen),
  ];

  for (var index = 0; index < demos.length; index++) {
    final (name, screenType) = demos[index];
    testWidgets('$name opens from the home screen', (tester) async {
      await openHome(tester);
      await tester.tap(find.byType(HomeListView).at(index));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(screenType), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
