import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(const ChickenZoneApp());

const green = Color(0xFF087A42);
const red = Color(0xFFD71920);
const String validLicenseKey = 'TU-CHICKEN-FULL-2026';

class ChickenZoneApp extends StatelessWidget {
  const ChickenZoneApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TU Chicken Zone',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: green),
      scaffoldBackgroundColor: const Color(0xFFF4F7F8),
      appBarTheme: const AppBarTheme(backgroundColor: green, foregroundColor: Colors.white, centerTitle: true)),
    home: const LicenseGate(),
  );
}

class LicenseGate extends StatefulWidget {
  const LicenseGate({super.key});
  @override
  State<LicenseGate> createState() => _LicenseGateState();
}
class _LicenseGateState extends State<LicenseGate> {
  bool ready=false, activated=false, expired=false;
  int remaining=86400;
  Timer? timer;
  @override
  void initState(){super.initState(); _load();}
  Future<void> _load() async {
    final p=await SharedPreferences.getInstance();
    activated=p.getBool('cz_activated')??false;
    int? start=p.getInt('cz_demo_start');
    if(start==null){start=DateTime.now().millisecondsSinceEpoch; await p.setInt('cz_demo_start',start);}
    remaining=(86400-((DateTime.now().millisecondsSinceEpoch-start)~/1000)).clamp(0,86400).toInt();
    expired=remaining<=0;
    if(!activated && !expired) timer=Timer.periodic(const Duration(seconds:1),(_){
      if(!mounted)return; setState(()=>remaining=(remaining-1).clamp(0,86400).toInt());
      if(remaining<=0){timer?.cancel();setState(()=>expired=true);}
    });
    if(mounted)setState(()=>ready=true);
  }
  @override
  void dispose(){timer?.cancel();super.dispose();}
  Future<void> activate() async {
    final c=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Activate License / لائسنس'),
      content:TextField(controller:c,decoration:const InputDecoration(labelText:'License Key')),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,c.text.trim().toUpperCase()==validLicenseKey),child:const Text('Activate'))]));
    if(ok==true){final p=await SharedPreferences.getInstance();await p.setBool('cz_activated',true);if(mounted)setState(()=>activated=true);}
    else if(ok==false && c.text.trim().isNotEmpty && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Invalid License Key')));
  }
  @override
  Widget build(BuildContext context){
    if(!ready)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    if(activated)return const HomePage();
    if(!expired)return HomePage(demoSeconds:remaining,onActivate:activate);
    return Scaffold(body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
      Image.asset('assets/chicken_zone_logo.png',height:150),const SizedBox(height:16),
      const Text('Demo expired / ڈیمو ختم ہوگیا',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
      const SizedBox(height:12),FilledButton(onPressed:activate,child:const Text('Enter License Key'))]))));
  }
}

class HomePage extends StatefulWidget {
  final int? demoSeconds; final VoidCallback? onActivate;
  const HomePage({super.key,this.demoSeconds,this.onActivate});
  @override State<HomePage> createState()=>_HomePageState();
}
class _HomePageState extends State<HomePage>{
  int page=0; bool loading=true;
  List<Map<String,dynamic>> customers=[],mall=[],kami=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{final p=await SharedPreferences.getInstance();
    customers=dec(p.getString('cz_customers'));mall=dec(p.getString('cz_mall'));kami=dec(p.getString('cz_kami'));
    if(mounted)setState(()=>loading=false);}
  List<Map<String,dynamic>> dec(String? s){try{return (jsonDecode(s??'[]') as List).map((e)=>Map<String,dynamic>.from(e)).toList();}catch(_){return [];}}
  double n(dynamic v)=>v is num?v.toDouble():double.tryParse('$v')??0;
  double weight(Map<String,dynamic> m)=>n(m['kg'])+n(m['grams'])/1000;
  String money(dynamic v)=>'Rs. ${n(v).toStringAsFixed(0)}';
  String wt(Map<String,dynamic> m)=>'${n(m['kg']).toStringAsFixed(0)} Kg ${n(m['grams']).toStringAsFixed(0)} g';
  double total(Map<String,dynamic> c)=>n(c['oldBalance'])+n(c['newMall']);
  double balance(Map<String,dynamic> c)=>total(c)-n(c['received']);
  double get receivedTotal=>customers.fold(0.0,(s,c)=>s+n(c['received']));
  double get balanceTotal=>customers.fold(0.0,(s,c)=>s+balance(c));
  double get mallAmount=>mall.fold(0.0,(s,r)=>s+n(r['total']));
  double get kamiAmount=>kami.fold(0.0,(s,r)=>s+n(r['total']));
  Future<void> save()async{final p=await SharedPreferences.getInstance();await p.setString('cz_customers',jsonEncode(customers));await p.setString('cz_mall',jsonEncode(mall));await p.setString('cz_kami',jsonEncode(kami));if(mounted)setState((){});}
  TextEditingController ctl(dynamic v)=>TextEditingController(text:'${v??''}');
  Widget field(TextEditingController c,String label,{bool numeric=false})=>TextField(controller:c,keyboardType:numeric?const TextInputType.numberWithOptions(decimal:true):TextInputType.text,decoration:InputDecoration(labelText:label));
  Future<void> addRecord(bool isKami)async{
    final kgc=ctl(''),gc=ctl('0'),rate=ctl(''),expense=ctl('');
    final result=await showDialog<Map<String,dynamic>>(context:context,builder:(ctx)=>AlertDialog(title:Text(isKami?'Mall Mein Kami':'Total Mall'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        field(kgc,'Weight Kg',numeric:true),field(gc,'Weight Gram (0-999)',numeric:true),field(rate,'Sale Rate Rs/Kg',numeric:true),field(expense,isKami?'Vehicle Expense':'Mall Expense',numeric:true),
        const SizedBox(height:8),const Text('Amount = total weight × rate + expense') ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:(){
        final w=n(kgc.text)+n(gc.text)/1000,r=n(rate.text),e=n(expense.text);
        if(w<=0||r<=0)return;Navigator.pop(ctx,{'kg':n(kgc.text),'grams':n(gc.text),'rate':r,'expense':e,'total':w*r+e,'date':DateTime.now().toIso8601String().substring(0,10)});
      },child:const Text('Save'))]));
    if(result!=null){setState(()=>(isKami?kami:mall).insert(0,result));await save();}
  }
  Future<void> customerForm({Map<String,dynamic>? oldC,int? index})async{
    final name=ctl(oldC?['name']??''),place=ctl(oldC?['place']??''),phone=ctl(oldC?['phone']??'');
    final old=ctl(oldC?['oldBalance']??0),kgc=ctl(oldC?['kg']??0),gc=ctl(oldC?['grams']??0),rate=ctl(oldC?['rate']??0),received=ctl(oldC?['received']??0);
    final data=await showDialog<Map<String,dynamic>>(context:context,builder:(ctx)=>AlertDialog(title:Text(oldC==null?'Add Customer':'Edit Customer'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        field(name,'Customer Name *'),field(place,'Area / Location'),field(phone,'Phone Number'),field(old,'Old Balance Rs',numeric:true),
        field(kgc,'New Mall Weight Kg',numeric:true),field(gc,'New Mall Weight Gram',numeric:true),field(rate,'Rate Rs/Kg',numeric:true),field(received,'Received Rs',numeric:true),
        const SizedBox(height:8),const Text('New Mall amount = (Kg + Gram/1000) × rate') ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:(){
        if(name.text.trim().isEmpty)return;
        final amount=(n(kgc.text)+n(gc.text)/1000)*n(rate.text);
        Navigator.pop(ctx,{'name':name.text.trim(),'place':place.text.trim(),'phone':phone.text.trim(),'oldBalance':n(old.text),'kg':n(kgc.text),'grams':n(gc.text),'rate':n(rate.text),'newMall':amount,'received':n(received.text),'updated':DateTime.now().toIso8601String().substring(0,10)});
      },child:const Text('Save Customer'))]));
    if(data!=null){setState((){if(index==null)customers.insert(0,data);else customers[index]=data;});await save();}
  }
  Future<void> payment(int i)async{final c=ctl('');final v=await showDialog<double>(context:context,builder:(ctx)=>AlertDialog(title:Text('Payment - ${customers[i]['name']}'),content:field(c,'Amount Rs',numeric:true),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,n(c.text)),child:const Text('Add'))]));
    if(v!=null&&v>0){customers[i]['received']=n(customers[i]['received'])+v;await save();}}
  Future<void> pdfCustomer(Map<String,dynamic> c)async{final d=pw.Document();d.addPage(pw.Page(build:(_)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
    pw.Center(child:pw.Text('TU CHICKEN ZONE - CUSTOMER LEDGER',style:pw.TextStyle(fontSize:20,fontWeight:pw.FontWeight.bold))),
    pw.SizedBox(height:20),pw.Table.fromTextArray(headers:['Detail','Value'],data:[
      ['Name','${c['name']}'],['Place','${c['place']}'],['Phone','${c['phone']}'],['Weight',wt(c)],['Rate',money(c['rate'])],
      ['Old Balance',money(c['oldBalance'])],['New Mall',money(c['newMall'])],['Total',money(total(c))],['Received',money(c['received'])],['Remaining',money(balance(c))]])])));
    await Printing.layoutPdf(onLayout:(_)=>d.save());}
  Future<void> pdfAll()async{final d=pw.Document();d.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4.landscape,build:(_)=>[
    pw.Text('TU CHICKEN ZONE - CUSTOMER LIST',style:pw.TextStyle(fontSize:18,fontWeight:pw.FontWeight.bold)),
    pw.Table.fromTextArray(headers:['#','Name','Area','Weight','Rate','Old','New Mall','Total','Received','Balance'],
    data:customers.asMap().entries.map((e){final c=e.value;return ['${e.key+1}','${c['name']}','${c['place']}',wt(c),money(c['rate']),money(c['oldBalance']),money(c['newMall']),money(total(c)),money(c['received']),money(balance(c))];}).toList())]));
    await Printing.layoutPdf(onLayout:(_)=>d.save());}
  Widget stat(String title,String value,Color color)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title),const SizedBox(height:6),Text(value,style:TextStyle(fontWeight:FontWeight.bold,color:color,fontSize:16))])));
  Widget dashboard()=>ListView(padding:const EdgeInsets.all(12),children:[
    Card(color:green,child:Padding(padding:const EdgeInsets.all(16),child:Row(children:[Image.asset('assets/chicken_zone_logo.png',width:70,height:70),const SizedBox(width:12),const Expanded(child:Text('TU CHICKEN ZONE\nManagement System',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)))]))),
    if(widget.demoSeconds!=null)Card(child:ListTile(title:const Text('Demo Version (24 Hours)'),subtitle:Text('Remaining: ${widget.demoSeconds!~/3600}h ${(widget.demoSeconds!%3600)~/60}m ${widget.demoSeconds!%60}s'),trailing:TextButton(onPressed:widget.onActivate,child:const Text('License')))),
    GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.7,children:[
      stat('Total Mall Amount',money(mallAmount),green),stat('Kami Amount',money(kamiAmount),red),stat('Customer Received',money(receivedTotal),green),stat('Customer Balance',money(balanceTotal),red)]),
    Wrap(spacing:8,children:[FilledButton(onPressed:()=>addRecord(false),child:const Text('Add Mall')),FilledButton(onPressed:()=>addRecord(true),child:const Text('Add Kami')),FilledButton(onPressed:()=>customerForm(),child:const Text('Add Customer')),OutlinedButton(onPressed:pdfAll,child:const Text('All Customers PDF'))])]);
  Widget records(bool isKami){final list=isKami?kami:mall;return ListView(padding:const EdgeInsets.all(12),children:[
    FilledButton.icon(onPressed:()=>addRecord(isKami),icon:const Icon(Icons.add),label:Text(isKami?'Add Kami Record':'Add Mall Record')),
    ...list.asMap().entries.map((e)=>Card(child:ListTile(title:Text('${e.value['date']} • ${wt(e.value)}'),subtitle:Text('Rate ${money(e.value['rate'])}/Kg • Expense ${money(e.value['expense'])}'),trailing:Text(money(e.value['total']))))) ]);}
  Widget customerPage()=>Column(children:[Padding(padding:const EdgeInsets.all(10),child:Row(children:[Expanded(child:Text('Customers (${customers.length})',style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold))),IconButton(onPressed:pdfAll,icon:const Icon(Icons.picture_as_pdf)),IconButton(onPressed:()=>customerForm(),icon:const Icon(Icons.person_add))])),
    Expanded(child:ListView.builder(itemCount:customers.length,itemBuilder:(ctx,i){final c=customers[i];return Card(child:ExpansionTile(leading:CircleAvatar(child:Text('${i+1}')),title:Text('${c['name']}'),subtitle:Text('Balance ${money(balance(c))}'),children:[
      ListTile(title:Text('Weight ${wt(c)} • Rate ${money(c['rate'])}/Kg'),subtitle:Text('New Mall ${money(c['newMall'])} | Old ${money(c['oldBalance'])} | Received ${money(c['received'])}')),
      Wrap(children:[TextButton(onPressed:()=>customerForm(oldC:c,index:i),child:const Text('Edit')),TextButton(onPressed:()=>payment(i),child:const Text('Payment')),TextButton(onPressed:()=>pdfCustomer(c),child:const Text('PDF')),TextButton(onPressed:()async{customers.removeAt(i);await save();},child:const Text('Delete'))]) ]));}))]);
  @override Widget build(BuildContext context){if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final views=[dashboard(),records(false),records(true),customerPage()];
    return Scaffold(appBar:AppBar(title:const Text('TU Chicken Zone'),actions:[IconButton(onPressed:pdfAll,icon:const Icon(Icons.picture_as_pdf))]),body:SafeArea(child:views[page]),
      bottomNavigationBar:NavigationBar(selectedIndex:page,onDestinationSelected:(i)=>setState(()=>page=i),destinations:const[
        NavigationDestination(icon:Icon(Icons.home),label:'Home'),NavigationDestination(icon:Icon(Icons.scale),label:'Mall'),NavigationDestination(icon:Icon(Icons.local_shipping),label:'Kami'),NavigationDestination(icon:Icon(Icons.people),label:'Customers')]));
  }
}
