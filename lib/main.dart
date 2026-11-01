import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(const ChickenZoneApp());

const Color green = Color(0xFF087A42);
const Color red = Color(0xFFD71920);
const Color blue = Color(0xFF1457B8);
const Color orange = Color(0xFFEF8500);

class ChickenZoneApp extends StatelessWidget {
  const ChickenZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chicken Zone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF4F7F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: green,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int page = 0;
  bool loading = true;
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> mallRecords = [];
  List<Map<String, dynamic>> kamiRecords = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    customers = _decodeList(prefs.getString('cz_customers'));
    mallRecords = _decodeList(prefs.getString('cz_mall'));
    kamiRecords = _decodeList(prefs.getString('cz_kami'));
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, dynamic>> _decodeList(String? value) {
    if (value == null) return [];
    try {
      return (jsonDecode(value) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cz_customers', jsonEncode(customers));
    await prefs.setString('cz_mall', jsonEncode(mallRecords));
    await prefs.setString('cz_kami', jsonEncode(kamiRecords));
    if (mounted) setState(() {});
  }

  double n(dynamic value) => (value is num) ? value.toDouble() : double.tryParse('$value') ?? 0;
  String money(dynamic value) => 'Rs. ${n(value).toStringAsFixed(0)}';
  String kg(dynamic value) => '${n(value).toStringAsFixed(1)} Kg';

  double get totalMall => mallRecords.fold(0, (s, r) => s + n(r['total']));
  double get totalKami => kamiRecords.fold(0, (s, r) => s + n(r['total']));
  double get totalReceived => customers.fold(0, (s, c) => s + n(c['received']));
  double get totalBalance => customers.fold(0, (s, c) => s + customerBalance(c));

  double customerTotal(Map<String, dynamic> c) => n(c['oldBalance']) + n(c['newMall']);
  double customerBalance(Map<String, dynamic> c) => customerTotal(c) - n(c['received']);

  Future<void> addMallRecord({required bool kami}) async {
    final formKey = GlobalKey<FormState>();
    final weight = TextEditingController();
    final rate = TextEditingController();
    final expense = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(kami ? 'Mall Mein Kami (مال میں کمی)' : 'Total Mall (کل مال)'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(weight, kami ? 'کمی وزن (Kg)' : 'کل وزن (Kg)', number: true),
              const SizedBox(height: 10),
              _field(rate, 'فروخت قیمت (Rs/Kg)', number: true),
              const SizedBox(height: 10),
              _field(expense, kami ? 'گاڑی خرچ (Rs)' : 'مال خرچ (Rs)', number: true),
              const SizedBox(height: 12),
              const Text('کل = وزن × فروخت قیمت + خرچ', style: TextStyle(color: green, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final w = n(weight.text), r = n(rate.text), e = n(expense.text);
              final record = {
                'date': DateTime.now().toIso8601String().substring(0, 10),
                'weight': w,
                'rate': r,
                'expense': e,
                'total': w * r + e,
              };
              setState(() => (kami ? kamiRecords : mallRecords).insert(0, record));
              await saveData();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Record'),
          ),
        ],
      ),
    );
  }

  Future<void> customerForm({Map<String, dynamic>? existing, int? index}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: existing?['name'] ?? '');
    final place = TextEditingController(text: existing?['place'] ?? '');
    final phone = TextEditingController(text: existing?['phone'] ?? '');
    final old = TextEditingController(text: '${existing?['oldBalance'] ?? 0}');
    final newMall = TextEditingController(text: '${existing?['newMall'] ?? 0}');
    final received = TextEditingController(text: '${existing?['received'] ?? 0}');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Customer / نیا کسٹمر' : 'Edit Customer / کسٹمر تبدیل کریں'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(name, 'Customer Name / نام', required: true),
              const SizedBox(height: 8),
              _field(place, 'Place / Area / جگہ'),
              const SizedBox(height: 8),
              _field(phone, 'Phone Number / فون'),
              const SizedBox(height: 8),
              _field(old, 'Purana Baqaya / پرانا بقایا', number: true),
              const SizedBox(height: 8),
              _field(newMall, 'New Mall / نیا مال', number: true),
              const SizedBox(height: 8),
              _field(received, 'Wasool / وصولی', number: true),
              const SizedBox(height: 8),
              Text(
                'Total: ${money(n(old.text) + n(newMall.text))}   |   Baqi: ${money(n(old.text) + n(newMall.text) - n(received.text))}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: green),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final item = {
                'name': name.text.trim(),
                'place': place.text.trim(),
                'phone': phone.text.trim(),
                'oldBalance': n(old.text),
                'newMall': n(newMall.text),
                'received': n(received.text),
                'updated': DateTime.now().toIso8601String().substring(0, 10),
              };
              setState(() {
                if (index != null && index >= 0 && index < customers.length) {
                  customers[index] = item;
                } else {
                  customers.insert(0, item);
                }
              });
              await saveData();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(existing == null ? 'Save Customer' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> collectPayment(int index) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Wasooli - ${customers[index]['name']}'),
        content: _field(controller, 'Payment Amount (Rs)', number: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = n(controller.text);
              if (amount <= 0) return;
              setState(() => customers[index]['received'] = n(customers[index]['received']) + amount);
              await saveData();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteCustomer(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text('Remove ${customers[index]['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => customers.removeAt(index));
      await saveData();
    }
  }

  Future<void> customerPdf(Map<String, dynamic> c) async {
    final doc = pw.Document();
    final total = customerTotal(c);
    final received = n(c['received']);
    final balance = customerBalance(c);
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(child: pw.Text('CHICKEN ZONE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800))),
          pw.Center(child: pw.Text('Customer Ledger / کسٹمر حساب')),
          pw.SizedBox(height: 22),
          pw.Table.fromTextArray(
            headers: ['Detail', 'Value'],
            data: [
              ['Customer Name', '${c['name'] ?? ''}'],
              ['Place / Area', '${c['place'] ?? ''}'],
              ['Phone', '${c['phone'] ?? ''}'],
              ['Old Balance', money(c['oldBalance'])],
              ['New Mall', money(c['newMall'])],
              ['Total', money(total)],
              ['Received', money(received)],
              ['Remaining Balance', money(balance)],
              ['Report Date', DateTime.now().toIso8601String().substring(0, 10)],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
            cellPadding: const pw.EdgeInsets.all(8),
          ),
          pw.SizedBox(height: 25),
          pw.Text('Prepared by Chicken Zone Management System'),
        ],
      ),
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: 'customer_${(c['name'] ?? 'ledger').toString().replaceAll(' ', '_')}.pdf');
  }

  Future<void> allCustomersPdf() async {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (context) => [
        pw.Center(child: pw.Text('CHICKEN ZONE - CUSTOMER LEDGER', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 12),
        pw.Table.fromTextArray(
          headers: ['#', 'Name', 'Place', 'Old Balance', 'New Mall', 'Total', 'Received', 'Balance'],
          data: customers.asMap().entries.map((e) {
            final c = e.value;
            return [
              '${e.key + 1}', '${c['name'] ?? ''}', '${c['place'] ?? ''}',
              money(c['oldBalance']), money(c['newMall']), money(customerTotal(c)),
              money(c['received']), money(customerBalance(c)),
            ];
          }).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
          cellPadding: const pw.EdgeInsets.all(5),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Total Remaining: ${money(totalBalance)}'),
      ],
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: 'chicken_zone_customers.pdf');
  }

  Future<void> clearRecords(bool kami) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear records?'),
        content: const Text('This removes all records in this section.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => (kami ? kamiRecords : mallRecords).clear());
      await saveData();
    }
  }

  Widget _field(TextEditingController controller, String label, {bool number = false, bool required = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.edit_note)),
    );
  }

  Widget statCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        ]),
      ),
    );
  }

  Widget dashboard() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [green, Color(0xFF004D2A)]),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🐔 CHICKEN ZONE', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Management System • Poultry Business Solution', style: TextStyle(color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.55,
          children: [
            statCard('Total Mall', kg(mallRecords.fold(0.0, (s, r) => s + n(r['weight']))), green, Icons.scale),
            statCard('Total Mall Amount', money(totalMall), orange, Icons.inventory_2),
            statCard('Mall Mein Kami', kg(kamiRecords.fold(0.0, (s, r) => s + n(r['weight']))), blue, Icons.remove_circle),
            statCard('Kami Amount', money(totalKami), red, Icons.local_shipping),
            statCard('Customer Received', money(totalReceived), green, Icons.payments),
            statCard('Customer Baqaya', money(totalBalance), red, Icons.account_balance_wallet),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Quick Actions / فوری کام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _action('Total Mall', green, Icons.scale, () => addMallRecord(kami: false)),
          _action('Mall Mein Kami', blue, Icons.local_shipping, () => addMallRecord(kami: true)),
          _action('Add Customer', red, Icons.person_add, () => customerForm()),
          _action('Customer PDF', orange, Icons.picture_as_pdf, allCustomersPdf),
        ]),
      ],
    );
  }

  Widget _action(String title, Color color, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 150,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget recordsPage(bool kami) {
    final records = kami ? kamiRecords : mallRecords;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Text(kami ? 'Mall Mein Kami (مال میں کمی)' : 'Total Mall (کل مال)', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(kami ? 'Total = Kami Weight × Sale Price + Gari Kharch' : 'Total = Weight × Sale Price + Mall Kharch', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => addMallRecord(kami: kami),
                icon: const Icon(Icons.add),
                label: const Text('Add New Record'),
              ),
            ]),
          ),
        ),
        ...records.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          return Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: kami ? blue : green, child: Text('${i + 1}', style: const TextStyle(color: Colors.white))),
              title: Text('${r['date']}  •  ${kg(r['weight'])}'),
              subtitle: Text('Rate: ${money(r['rate'])}/Kg   |   Expense: ${money(r['expense'])}'),
              trailing: Text(money(r['total']), style: const TextStyle(fontWeight: FontWeight.bold, color: green)),
            ),
          );
        }),
        if (records.isNotEmpty)
          TextButton.icon(onPressed: () => clearRecords(kami), icon: const Icon(Icons.delete_outline), label: const Text('Clear section records')),
      ],
    );
  }

  Widget customersPage() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: Text('Customers (${customers.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          IconButton.filled(onPressed: () => customerForm(), icon: const Icon(Icons.person_add), tooltip: 'Add Customer'),
          IconButton.filledTonal(onPressed: allCustomersPdf, icon: const Icon(Icons.picture_as_pdf), tooltip: 'All Customer PDF'),
        ]),
      ),
      Expanded(
        child: customers.isEmpty
            ? const Center(child: Text('No customers yet. Add your first customer.'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final c = customers[index];
                  return Card(
                    child: ExpansionTile(
                      leading: CircleAvatar(backgroundColor: green, child: Text('${index + 1}', style: const TextStyle(color: Colors.white))),
                      title: Text('${c['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${c['place'] ?? ''} • Balance: ${money(customerBalance(c))}', style: TextStyle(color: customerBalance(c) > 0 ? red : green)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Phone: ${c['phone'] ?? '-'}'),
                            Text('Old Balance: ${money(c['oldBalance'])}'),
                            Text('New Mall: ${money(c['newMall'])}'),
                            Text('Total: ${money(customerTotal(c))}'),
                            Text('Received: ${money(c['received'])}'),
                            Text('Remaining: ${money(customerBalance(c))}', style: const TextStyle(fontWeight: FontWeight.bold, color: red)),
                            const SizedBox(height: 8),
                            Wrap(spacing: 6, children: [
                              FilledButton.tonalIcon(onPressed: () => customerForm(existing: c, index: index), icon: const Icon(Icons.edit), label: const Text('Edit')),
                              FilledButton.icon(onPressed: () => collectPayment(index), icon: const Icon(Icons.payments), label: const Text('Wasooli')),
                              FilledButton.tonalIcon(onPressed: () => customerPdf(c), icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF')),
                              IconButton(onPressed: () => deleteCustomer(index), icon: const Icon(Icons.delete, color: red)),
                            ]),
                          ]),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final pages = [dashboard(), recordsPage(false), recordsPage(true), customersPage()];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chicken Zone Management'),
        actions: [
          IconButton(
            tooltip: 'Customer PDF',
            onPressed: allCustomersPdf,
            icon: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
      body: SafeArea(child: pages[page]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (i) => setState(() => page = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.scale), label: 'Total Mall'),
          NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Kami'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Customers'),
        ],
      ),
    );
  }
}
