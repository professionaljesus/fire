import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

/**
 * def calc_savings(self, btn):
        traj = self.calculate_trajectory(float(self.current_savings.text),
                                         float(self.income.text) - float(self.tax.text) - float(self.expenditures.text),
                                         int(self.years.text))
        self.total_savings.text = str(int(traj[-1]))

        self.plot_trajectory(traj)
        goal = self.calc_goal()
        self.plot_goal(goal, traj)

    def calc_goal(self):
        # Calculate goal based on current budget
        current_disposable_income = float(self.income.text) - float(self.tax.text)
        goal = current_disposable_income*12 / 0.04
        return goal

    def calculate_trajectory(self, II, MI, yrs=10, r=0.08, i=0.02, n=12, MI_inc=0.02):
        # r: average return
        # n: compounds per year
        # i: inflation rate
        # II: initial investment
        # MI: monthly investment
        # MI_inc: yearly increase of monthly investment

        # Months to run for:
        trajectory = [II]
        MI_over_time = [MI]
        for t_ in range(12 * yrs + 1):
            MI_over_time.append(MI*(1+MI_inc/12)**t_) ## Not used at the moment
            II_growth = II * (1 + r/n) ** t_
            MI_growth = (MI * (1 + MI_inc/12) * ((1 + MI_inc/12)**t_ - (1 + r/n) ** t_))/(MI_inc/12 - (r/n))
            trajectory.append((II_growth + MI_growth) * (1 - i/12) ** t_)

        return trajectory
 * 
 */

List<double> calculateTrajectory(
    double initialInvestment, double monthlyInvestment,
    {double years = 10,
    double averageReturn = 0.08,
    double inflationRate = 0.02,
    double n = 12,
    double monthlyInvestmentIncrease = 0.02}) {
  List<double> trajectory = [initialInvestment];
  List<double> monthlyOverTime = [monthlyInvestment];

  for (int i = 0; i < 12 * years + 1; i++) {
    monthlyOverTime
        .add(monthlyInvestment * pow(1 + monthlyInvestmentIncrease / 12, i));
    double initialInvesmentGrowth =
        initialInvestment * pow(1 + averageReturn / n, i);
    double monthlyIncreaseGrowth =
        (monthlyInvestment * (1 + monthlyInvestmentIncrease / 12) +
            (pow(1 + monthlyInvestmentIncrease / 12, i) -
                    pow(1 + averageReturn / n, i)) /
                (monthlyInvestmentIncrease / 12 + (averageReturn / n)));
    trajectory.add(
        (initialInvesmentGrowth + monthlyIncreaseGrowth) * pow(1 - i / 12, i));
  }
  return trajectory;
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'FIRE App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  List<double> trajectory = [];

  final Map<String, TextEditingController> _controllers = {
    'Income': TextEditingController(),
    'Tax': TextEditingController(),
    'Current Savings': TextEditingController(),
    'Expenditures': TextEditingController(),
    'Years': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    loadPrefs();
  }

  Future<void> loadPrefs() async {
    final SharedPreferences prefs = await _prefs;
    for (String key in _controllers.keys) {
      if (prefs.containsKey(key)) {
        _controllers[key].text = prefs.getString(key);
      } else {
        _controllers[key].text = '0';
      }
    }
    setState(() {});
  }

  Future<void> updateTrajectory() async {
    final SharedPreferences prefs = await _prefs;
    for (String key in _controllers.keys) {
      prefs.setString(key, _controllers[key].text);
    }

    double income = double.tryParse(_controllers['Income'].text);
    double tax = double.tryParse(_controllers['Tax'].text);
    double currentSavings =
        double.tryParse(_controllers['Current Savings'].text);
    double expenditures = double.tryParse(_controllers['Expenditures'].text);
    double years = double.tryParse(_controllers['Years'].text);

    income ??= 0;
    tax ??= 0;
    currentSavings ??= 0;
    expenditures ??= 0;
    years ??= 0;

    List<double> traj = calculateTrajectory(
        currentSavings, income - tax - expenditures,
        years: years);
    setState(() {
      trajectory = traj;
      print(trajectory);
    });
  }

  List<Widget> col() {
    List<Widget> w = List<Widget>.generate(_controllers.keys.length, (index) {
      String key = _controllers.keys.elementAt(index);

      return TextField(
        textAlign: TextAlign.right,
        controller: _controllers[key],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(suffixText: 'kr', labelText: key),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly
        ],
      );
    });
    w.add(ElevatedButton(
        onPressed: updateTrajectory, child: const Text('Calculate')));
    w.add(Expanded(
        child: SfSparkLineChart(
      //Enable the trackball
      trackball: const SparkChartTrackball(
          activationMode: SparkChartActivationMode.tap),
      //Enable marker
      marker:
          const SparkChartMarker(displayMode: SparkChartMarkerDisplayMode.all),
      //Enable data label
      labelDisplayMode: SparkChartLabelDisplayMode.all,
      data: trajectory,
    )));

    return w;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black87,
      ),
      body: Center(
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListView(
                children: col(),
                physics: const BouncingScrollPhysics(),
              ))),
    );
  }
}
