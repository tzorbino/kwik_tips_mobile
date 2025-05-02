import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class ViewReportScreen extends StatelessWidget {
  final Map<String, dynamic> reportData;

  const ViewReportScreen({super.key, required this.reportData});

  @override
  Widget build(BuildContext context) {
    final bool isServerReport =
        (reportData['reportType']?.toString().toLowerCase().trim() ?? '') ==
        'server';

    print('🟡 reportType: ${reportData['reportType']}');
    print('🟢 isServerReport: $isServerReport');
    print('🔵 alcoholSales: ${reportData['alcoholSales']}');
    print('🔵 alcoholTipPercentage: ${reportData['alcoholTipPercentage']}');
    print('🔵 totalPayout: ${reportData['totalPayout']}');
    print('🔵 totalAfterTipOuts: ${reportData['totalAfterTipOuts']}');
    print('🔵 barTipOutPercentage: ${reportData['barTipOutPercentage']}');

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSummarySection(),
            const SizedBox(height: 20),
            if (reportData['foodRunners'] != null) _buildFoodRunnerSection(),
            if (isServerReport) _buildServerReportSection(),
            if (reportData['barbacks'] != null) _buildBarbackSection(),

            if (reportData['bartenders'] != null) _buildBartenderSection(),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF184B74),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  foregroundColor: Colors.white, // 👈 ensures white text
                ),
                onPressed: () => _generateAndDownloadPdf(context),
                child: const Text('Download PDF'),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF184B74),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  foregroundColor: Colors.white, // 👈 ensures white text
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back to Form'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Image.asset('assets/newLogo.png', height: 120),
          const SizedBox(height: 10),
          Text(
            '${reportData['date'] ?? ''}  ${reportData['shiftType'] ?? ''}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return _buildCard([
      const Text(
        'Tip Summary',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      _buildSummaryRow('Total Cash Tips', reportData['totalCashTips']),
      _buildSummaryRow('Total Credit Card Tips', reportData['totalCcTips']),
    ]);
  }

  Widget _buildFoodRunnerSection() {
    final foodRunners = List<Map<String, dynamic>>.from(
      reportData['foodRunners'] ?? [],
    );
    return _buildCard([
      const Text(
        'Runners',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _buildDataTable(
          ['#', 'Sales', 'Tip-Out %', 'Amount Owed'],
          List.generate(
            foodRunners.length,
            (index) => [
              '${index + 1}',
              _formatCurrency(foodRunners[index]['foodSales']),
              '${(foodRunners[index]['foodRunnerTipPercentage'] ?? 0)}%',
              _formatCurrency(foodRunners[index]['foodRunnerTipAmount']),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildBarbackSection() {
    final barbacks = List<Map<String, dynamic>>.from(
      reportData['barbacks'] ?? [],
    );
    return _buildCard([
      const Text(
        'Barbacks',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),

      const SizedBox(height: 10),

      Row(
        children: [
          Expanded(
            child: _buildSummaryRow(
              'Cash Tip-Out %',
              reportData['barbackCashTipPercentage'],
              formatter: _formatPercent,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildSummaryRow(
              'Cash Hourly',
              reportData['barbackCashHourly'],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _buildSummaryRow(
              'CC Tip-Out %',
              reportData['barbackCcTipPercentage'],
              formatter: _formatPercent,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildSummaryRow('CC Hourly', reportData['barbackCcHourly']),
          ),
        ],
      ),

      const SizedBox(height: 10),

      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _buildDataTable(
          ['Name', 'Shift Length', 'Cash Tips', 'CC Tips'],
          barbacks
              .map(
                (barback) => [
                  (barback['barbackName'] ?? '').toString(),
                  (barback['barbackShiftHours'] ?? '').toString(),
                  _formatCurrency(barback['barbackCashTips']),
                  _formatCurrency(barback['barbackCcTips']),
                ],
              )
              .toList(),
        ),
      ),
    ]);
  }

  Widget _buildBartenderSection() {
    final bartenders = List<Map<String, dynamic>>.from(
      reportData['bartenders'] ?? [],
    );
    return _buildCard([
      const Text(
        'Bartenders',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),

      Wrap(
        spacing: 20,
        runSpacing: 10,
        children: [
          _buildSummaryRow('Cash Hourly', reportData['bartenderCashHourly']),
          _buildSummaryRow('CC Hourly', reportData['bartenderCcHourly']),
        ],
      ),

      const SizedBox(height: 10),

      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _buildDataTable(
          ['Name', 'Hours Worked', 'Cash Tips', 'Credit Card Tips'],
          bartenders
              .map(
                (bartender) => [
                  (bartender['name'] ?? '').toString(),
                  (bartender['hoursWorked'] ?? '').toString(),
                  _formatCurrency(bartender['cashTips']),
                  _formatCurrency(bartender['ccTips']),
                ],
              )
              .toList(),
        ),
      ),
    ]);
  }

  Widget _buildServerReportSection() {
    final alcoholSales = _formatCurrency(reportData['alcoholSales'] ?? 0);
    final alcoholTipPercentage = _formatPercent(
      reportData['alcoholTipPercentage'] ?? 0,
    );

    final totalPayout = _formatCurrency(reportData['totalPayout'] ?? 0);
    final totalAfterTipOuts = _formatCurrency(
      reportData['totalAfterTipOuts'] ?? 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCard([
          const Text(
            'Bar Tip-Out',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildDataTable(
              ['Alcohol Sales', 'Tip-Out %', 'Amount Owed'],
              [
                [alcoholSales, alcoholTipPercentage, totalPayout],
              ],
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _buildCard([
          Center(
            child: Text(
              'Total Tips (After Tip-Outs)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              totalAfterTipOuts,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    dynamic value, {
    String Function(dynamic)? formatter,
  }) {
    final formattedValue =
        formatter != null ? formatter(value) : _formatCurrency(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Text(formattedValue, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<String> headers, List<List<dynamic>> rows) {
    return DataTable(
      columns:
          headers.map((header) => DataColumn(label: Text(header))).toList(),
      rows:
          rows
              .map(
                (row) => DataRow(
                  cells:
                      row
                          .map((cell) => DataCell(Text(cell?.toString() ?? '')))
                          .toList(),
                ),
              )
              .toList(),
      headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
      border: TableBorder.all(color: Colors.grey.shade300),
    );
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }

  void _generateAndDownloadPdf(BuildContext context) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final rawBartenderCashHourly = reportData['bartenderCashHourly'];
          final rawBartenderCcHourly = reportData['bartenderCcHourly'];

          final bartenderCashHourly =
              (rawBartenderCashHourly is num)
                  ? rawBartenderCashHourly.toStringAsFixed(2)
                  : double.tryParse(
                        rawBartenderCashHourly?.toString() ?? '',
                      )?.toStringAsFixed(2) ??
                      '0.00';

          final bartenderCcHourly =
              (rawBartenderCcHourly is num)
                  ? rawBartenderCcHourly.toStringAsFixed(2)
                  : double.tryParse(
                        rawBartenderCcHourly?.toString() ?? '',
                      )?.toStringAsFixed(2) ??
                      '0.00';

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Kwik Tips Report',
                style: pw.TextStyle(font: font, fontSize: 24),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Date: ${reportData['date']} - ${reportData['shiftType']}',
                style: pw.TextStyle(font: font),
              ),
              pw.SizedBox(height: 20),

              // Tip Summary
              pw.Text(
                'Tip Summary',
                style: pw.TextStyle(font: font, fontSize: 18),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Total Cash Tips: \$${reportData['totalCashTips']?.toStringAsFixed(2) ?? '0.00'}',
              ),
              pw.Text(
                'Total Credit Card Tips: \$${reportData['totalCcTips']?.toStringAsFixed(2) ?? '0.00'}',
              ),
              pw.SizedBox(height: 20),

              // Runners
              if (reportData['foodRunners'] != null)
                pw.Column(
                  children: [
                    pw.Text(
                      'Runners',
                      style: pw.TextStyle(font: font, fontSize: 18),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Table.fromTextArray(
                      headers: ['#', 'Sales', 'Tip-Out %', 'Amount Owed'],
                      data: List<List<dynamic>>.from(
                        (reportData['foodRunners'] as List).asMap().entries.map((
                          entry,
                        ) {
                          final i = entry.key;
                          final r = entry.value;
                          return [
                            '${i + 1}',
                            '\$${(r['foodSales'] ?? 0).toStringAsFixed(2)}',
                            '${(r['foodRunnerTipPercentage'] ?? 0)}%',
                            '\$${(r['foodRunnerTipAmount'] ?? 0).toStringAsFixed(2)}',
                          ];
                        }),
                      ),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                ),

              // Barbacks
              if (reportData['barbacks'] != null)
                () {
                  final rawCashPct = reportData['barbackCashTipPercentage'];
                  final rawCcPct = reportData['barbackCcTipPercentage'];

                  final barbackCashPercentage =
                      (rawCashPct != null &&
                              rawCashPct.toString().trim().isNotEmpty)
                          ? rawCashPct.toString().replaceAll('.0', '')
                          : null;

                  final barbackCcPercentage =
                      (rawCcPct != null &&
                              rawCcPct.toString().trim().isNotEmpty)
                          ? rawCcPct.toString().replaceAll('.0', '')
                          : null;

                  final barbackCashHourly = double.tryParse(
                    reportData['barbackCashHourly']?.toString() ?? '',
                  );
                  final barbackCcHourly = double.tryParse(
                    reportData['barbackCcHourly']?.toString() ?? '',
                  );

                  return pw.Column(
                    children: [
                      pw.Text(
                        'Barbacks',
                        style: pw.TextStyle(font: font, fontSize: 18),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Barback Tip-Out % - Cash: ${barbackCashPercentage ?? 'N/A'}% | CC: ${barbackCcPercentage ?? 'N/A'}%',
                        style: pw.TextStyle(font: font),
                      ),
                      pw.Text(
                        'Barback Hourly Rate - Cash: \$${barbackCashHourly != null ? barbackCashHourly.toStringAsFixed(2) : 'N/A'}'
                        ' | CC: \$${barbackCcHourly != null ? barbackCcHourly.toStringAsFixed(2) : 'N/A'}',
                        style: pw.TextStyle(font: font),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Table.fromTextArray(
                        headers: ['Name', 'Hours', 'Cash Tips', 'CC Tips'],
                        data: List<List<dynamic>>.from(
                          (reportData['barbacks'] as List).map(
                            (b) => [
                              b['barbackName']?.toString() ?? '',
                              b['barbackShiftHours']?.toString() ?? '',
                              '\$${(b['barbackCashTips'] ?? 0).toStringAsFixed(2)}',
                              '\$${(b['barbackCcTips'] ?? 0).toStringAsFixed(2)}',
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 20),
                    ],
                  );
                }(),

              // Bartenders
              if (reportData['bartenders'] != null)
                pw.Column(
                  children: [
                    pw.Text(
                      'Bartenders',
                      style: pw.TextStyle(font: font, fontSize: 18),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Bartender Hourly Rate - Cash: \$${bartenderCashHourly} | CC: \$${bartenderCcHourly}',
                      style: pw.TextStyle(font: font),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Table.fromTextArray(
                      headers: ['Name', 'Hours Worked', 'Cash Tips', 'CC Tips'],
                      data: List<List<dynamic>>.from(
                        (reportData['bartenders'] as List).map(
                          (b) => [
                            b['name']?.toString() ?? '',
                            b['hoursWorked']?.toString() ?? '',
                            '\$${(b['cashTips'] ?? 0).toStringAsFixed(2)}',
                            '\$${(b['ccTips'] ?? 0).toStringAsFixed(2)}',
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                ),

              // Server Report (no heading)
              if (reportData['reportType'] == 'server')
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Bar Tip-Out',
                      style: pw.TextStyle(font: font, fontSize: 18),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Table.fromTextArray(
                      headers: ['Alcohol Sales', 'Tip-Out %', 'Amount Owed'],
                      data: [
                        [
                          '\$${(reportData['alcoholSales'] ?? 0).toStringAsFixed(2)}',
                          '${(reportData['alcoholTipPercentage'] ?? 0).toString()}%',
                          '\$${(reportData['totalPayout'] ?? 0).toStringAsFixed(2)}',
                        ],
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'Total Tips (After Tip-Outs)',
                      style: pw.TextStyle(font: font, fontSize: 16),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '\$${(reportData['totalAfterTipOuts'] ?? 0).toStringAsFixed(2)}',
                      style: pw.TextStyle(font: font, fontSize: 20),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '\$0.00';
    return '\$${(value as num).toStringAsFixed(2)}';
  }

  String _formatPercent(dynamic value) {
    try {
      if (value == null) return '0.00%';
      final numValue = value is num ? value : num.parse(value.toString());
      return '${numValue.toStringAsFixed(2)}%';
    } catch (_) {
      return '0.00%';
    }
  }
}
