import 'package:flutter/material.dart';
import 'package:kwik_tips_mobile/screens/view_report_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateTipReportScreen extends StatefulWidget {
  const CreateTipReportScreen({super.key});

  @override
  State<CreateTipReportScreen> createState() => _CreateTipReportScreenState();
}

class _CreateTipReportScreenState extends State<CreateTipReportScreen> {
  // Form fields
  DateTime? _selectedDate;
  String _shiftType = 'AM';
  String _reportType = 'bartender';
  final _cashTipsController = TextEditingController();
  final _ccTipsController = TextEditingController();
  final _alcoholSalesController = TextEditingController();
  final _barTipOutPercentageController = TextEditingController();
  final _barbackCashTipPercentageController = TextEditingController();
  final _barbackCcTipPercentageController = TextEditingController();
  final _barbackShiftLengthController = TextEditingController();

  List<Map<String, dynamic>> _foodRunners = [];
  List<Map<String, dynamic>> _barbacks = [];
  List<Map<String, dynamic>> _bartenders = [];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime(Map<String, dynamic> person, String key) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        person[key] = picked;
      });
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
    ),
  );

  ButtonStyle _buttonStyle(Color color) => ElevatedButton.styleFrom(
    backgroundColor: color,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  );

  DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      appBar: AppBar(
        title: const Text('Kwik Tips'),
        centerTitle: true,
        backgroundColor: const Color(0xFF184B74),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainInfoSection(),
            const SizedBox(height: 20),
            if (_reportType == 'server') _buildServerFields(),
            const SizedBox(height: 20),
            _buildRunnerSection(),
            if (_reportType == 'bartender') _buildBarbackSection(),
            if (_reportType == 'bartender') _buildBartenderSection(),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: _buttonStyle(const Color(0xFF33B37A)),
                onPressed: () async {
                  if (_selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a shift date.'),
                      ),
                    );
                    return;
                  }

                  final Map<String, dynamic> reportData = {
                    'date': _selectedDate!.toIso8601String().split('T')[0],
                    'shift': _shiftType,
                    'reportType': _reportType,
                    'cashTips': double.tryParse(_cashTipsController.text) ?? 0,
                    'ccTips': double.tryParse(_ccTipsController.text) ?? 0,
                    'foodSales': _foodRunners.fold(
                      0.0,
                      (sum, r) =>
                          sum + (double.tryParse(r['foodSales'] ?? '0') ?? 0),
                    ),
                    'foodRunnerTip':
                        _foodRunners.isNotEmpty
                            ? double.tryParse(
                                  _foodRunners[0]['foodRunnerTip'] ?? '0',
                                ) ??
                                0
                            : 0,
                    'foodRunners':
                        _foodRunners
                            .map(
                              (runner) => {
                                'foodSales':
                                    double.tryParse(
                                      runner['foodSales'] ?? '0',
                                    ) ??
                                    0,
                                'foodRunnerTip':
                                    double.tryParse(
                                      runner['foodRunnerTip'] ?? '0',
                                    ) ??
                                    0,
                              },
                            )
                            .toList(),
                    'barbacks':
                        _barbacks
                            .map(
                              (barback) => {
                                'name': barback['name'],
                                'timeIn':
                                    combineDateAndTime(
                                      _selectedDate!,
                                      barback['timeIn'],
                                    ).toIso8601String().split('.').first,
                                'timeOut':
                                    combineDateAndTime(
                                      _selectedDate!,
                                      barback['timeOut'],
                                    ).toIso8601String().split('.').first,
                                'shiftLength':
                                    double.tryParse(
                                      _barbackShiftLengthController.text,
                                    ) ??
                                    0,
                              },
                            )
                            .toList(),
                    'bartenders':
                        _bartenders
                            .map(
                              (bartender) => {
                                'name': bartender['name'],
                                'timeIn':
                                    combineDateAndTime(
                                      _selectedDate!,
                                      bartender['timeIn'],
                                    ).toIso8601String().split('.').first,
                                'timeOut':
                                    combineDateAndTime(
                                      _selectedDate!,
                                      bartender['timeOut'],
                                    ).toIso8601String().split('.').first,
                              },
                            )
                            .toList(),
                    'alcoholSales':
                        double.tryParse(_alcoholSalesController.text) ?? 0,
                    'barTipOutPercentage':
                        double.tryParse(_barTipOutPercentageController.text) ??
                        0,
                    'barbackCashTipPercentage':
                        double.tryParse(
                          _barbackCashTipPercentageController.text,
                        ) ??
                        0,
                    'barbackCcTipPercentage':
                        double.tryParse(
                          _barbackCcTipPercentageController.text,
                        ) ??
                        0,
                  };

                  try {
                    print('Sending reportData: ${jsonEncode(reportData)}');

                    final response = await http.post(
                      Uri.parse(
                        'https://kwik-tips-backend.uk.r.appspot.com/api/tip-reports/generate',
                      ),
                      headers: {
                        'Content-Type': 'application/json',
                        'Origin': 'http://localhost:60029', // Manually add this
                      },
                      body: jsonEncode(reportData),
                    );

                    if (response.statusCode == 200 ||
                        response.statusCode == 201) {
                      final generatedReport = jsonDecode(response.body);
                      generatedReport['reportType'] = _reportType;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ViewReportScreen(reportData: generatedReport),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to generate report. Status: ${response.statusCode}',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },

                child: const Text('Generate Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfoSection() {
    return _buildCard([
      ElevatedButton(
        onPressed: _pickDate,
        style: _buttonStyle(const Color(0xFF184B74)),
        child: Text(
          _selectedDate == null
              ? 'Pick Date'
              : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
        ),
      ),
      const SizedBox(height: 10),

      SizedBox(
        width: double.infinity,
        child: DropdownButtonFormField<String>(
          value: _shiftType,
          items: const [
            DropdownMenuItem(value: 'AM', child: Text('AM')),
            DropdownMenuItem(value: 'PM', child: Text('PM')),
          ],
          onChanged: (value) => setState(() => _shiftType = value!),
          decoration: _inputDecoration('Shift'),
        ),
      ),
      const SizedBox(height: 10),

      SizedBox(
        width: double.infinity,
        child: DropdownButtonFormField<String>(
          value: _reportType,
          items: const [
            DropdownMenuItem(
              value: 'bartender',
              child: Text('Bartender Report'),
            ),
            DropdownMenuItem(value: 'server', child: Text('Server Report')),
          ],
          onChanged: (value) => setState(() => _reportType = value!),
          decoration: _inputDecoration('Report Type'),
        ),
      ),
      const SizedBox(height: 10),

      TextField(
        controller: _cashTipsController,
        keyboardType: TextInputType.number,
        decoration: _inputDecoration('Total Cash Tips'),
      ),
      const SizedBox(height: 10),

      TextField(
        controller: _ccTipsController,
        keyboardType: TextInputType.number,
        decoration: _inputDecoration('Total Credit Card Tips'),
      ),
    ]);
  }

  Widget _buildServerFields() {
    return _buildCard([
      TextField(
        controller: _alcoholSalesController,
        keyboardType: TextInputType.number,
        decoration: _inputDecoration('Alcohol Sales'),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _barTipOutPercentageController,
        keyboardType: TextInputType.number,
        decoration: _inputDecoration('Bar Tip-Out %'),
      ),
    ]);
  }

  Widget _buildRunnerSection() {
    return _buildCard([
      ElevatedButton(
        style: _buttonStyle(const Color(0xFF184B74)),
        onPressed:
            () => setState(
              () => _foodRunners.add({'foodSales': '', 'foodRunnerTip': ''}),
            ),
        child: const Text('Add Runner'),
      ),
      ...List.generate(_foodRunners.length, (index) => _buildRunnerCard(index)),
    ]);
  }

  Widget _buildRunnerCard(int index) {
    return _buildEntryCard([
      TextField(
        keyboardType: TextInputType.number,
        decoration: _inputDecoration('Food Sales'),
        onChanged: (value) => _foodRunners[index]['foodSales'] = value,
      ),
      const SizedBox(height: 10),
      TextField(
        keyboardType: TextInputType.number,
        decoration: _inputDecoration('Tip %'),
        onChanged: (value) => _foodRunners[index]['foodRunnerTip'] = value,
      ),
      TextButton(
        onPressed: () => setState(() => _foodRunners.removeAt(index)),
        child: const Text(
          'Remove Runner',
          style: TextStyle(color: Color(0xFFFF6B6B)),
        ),
      ),
    ]);
  }

  Widget _buildBarbackSection() {
    return _buildCard([
      ElevatedButton(
        style: _buttonStyle(const Color(0xFF184B74)),
        onPressed:
            () => setState(
              () =>
                  _barbacks.add({'name': '', 'timeIn': null, 'timeOut': null}),
            ),
        child: const Text('Add Barback'),
      ),
      if (_barbacks.isNotEmpty) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _barbackCashTipPercentageController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('Barback Cash Tip %'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _barbackCcTipPercentageController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('Barback CC Tip %'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _barbackShiftLengthController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('Shift Length (hours)'),
        ),
      ],
      ...List.generate(_barbacks.length, (index) => _buildBarbackCard(index)),
    ]);
  }

  Widget _buildBarbackCard(int index) {
    return _buildEntryCard([
      TextField(
        decoration: _inputDecoration('Barback Name'),
        onChanged: (value) => _barbacks[index]['name'] = value,
      ),
      ElevatedButton(
        style: _buttonStyle(const Color(0xFF184B74)),
        onPressed: () => _pickTime(_barbacks[index], 'timeIn'),
        child: Text(
          _barbacks[index]['timeIn'] != null
              ? (_barbacks[index]['timeIn'] as TimeOfDay).format(context)
              : 'Pick Time In',
        ),
      ),
      ElevatedButton(
        style: _buttonStyle(const Color(0xFF184B74)),
        onPressed: () => _pickTime(_barbacks[index], 'timeOut'),
        child: Text(
          _barbacks[index]['timeOut'] != null
              ? (_barbacks[index]['timeOut'] as TimeOfDay).format(context)
              : 'Pick Time Out',
        ),
      ),

      TextButton(
        onPressed: () => setState(() => _barbacks.removeAt(index)),
        child: const Text(
          'Remove Barback',
          style: TextStyle(color: Color(0xFFFF6B6B)),
        ),
      ),
    ]);
  }

  Widget _buildBartenderSection() {
    return _buildCard([
      ElevatedButton(
        style: _buttonStyle(const Color(0xFF184B74)),
        onPressed:
            () => setState(
              () => _bartenders.add({
                'name': '',
                'timeIn': null,
                'timeOut': null,
              }),
            ),
        child: const Text('Add Bartender'),
      ),
      ...List.generate(
        _bartenders.length,
        (index) => _buildBartenderCard(index),
      ),
    ]);
  }

  Widget _buildBartenderCard(int index) {
    return _buildEntryCard([
      TextField(
        decoration: _inputDecoration('Bartender Name'),
        onChanged: (value) => _bartenders[index]['name'] = value,
      ),
      ElevatedButton(
        style: _buttonStyle(const Color(0xFF184B74)),
        onPressed: () => _pickTime(_bartenders[index], 'timeIn'),
        child: Text(
          _bartenders[index]['timeIn'] != null
              ? (_bartenders[index]['timeIn'] as TimeOfDay).format(context)
              : 'Pick Time In',
        ),
      ),
      ElevatedButton(
        style: _buttonStyle(const Color(0xFF184B74)),
        onPressed: () => _pickTime(_bartenders[index], 'timeOut'),
        child: Text(
          _bartenders[index]['timeOut'] != null
              ? (_bartenders[index]['timeOut'] as TimeOfDay).format(context)
              : 'Pick Time Out',
        ),
      ),
      TextButton(
        onPressed: () => setState(() => _bartenders.removeAt(index)),
        child: const Text(
          'Remove Bartender',
          style: TextStyle(color: Color(0xFFFF6B6B)),
        ),
      ),
    ]);
  }

  Widget _buildCard(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          color: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch, // 👈 this line fixes dropdown width
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEntryCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: _buildCard(children),
    );
  }
}
