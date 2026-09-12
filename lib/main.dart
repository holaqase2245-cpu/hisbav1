import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bg = Color(0xFF061014);
const panel = Color(0xFF0C191E);
const panel2 = Color(0xFF102228);
const line = Color(0xFF1B343B);
const accent = Color(0xFF35D5C1);
const muted = Color(0xFF91A6AD);
const gold = Color(0xFFFFC65C);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = HisbaStore();
  await store.init();
  runApp(HisbaApp(store: store));
}

class HisbaApp extends StatefulWidget {
  final HisbaStore store;
  const HisbaApp({super.key, required this.store});
  @override State<HisbaApp> createState() => _HisbaAppState();
}
class _HisbaAppState extends State<HisbaApp> {
  bool light = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'حسبة',
    themeMode: light ? ThemeMode.light : ThemeMode.dark,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: accent), useMaterial3: true),
    darkTheme: ThemeData(
      brightness: Brightness.dark, useMaterial3: true, scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: panel2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
    ),
    home: HomePage(store: widget.store, onTheme: () => setState(() => light = !light)),
  );
}

class HisbaStore {
  late SharedPreferences p;
  final List<GameRecord> records = [];
  Future<void> init() async { p = await SharedPreferences.getInstance(); _load(); }
  void _load() {
    records.clear();
    for (final s in p.getStringList('games') ?? []) { try { records.add(GameRecord.fromJson(jsonDecode(s))); } catch (_) {} }
  }
  Future<void> save() async => p.setStringList('games', records.map((e) => jsonEncode(e.toJson())).toList());
  Future<void> add(GameRecord g) async { records.insert(0, g); await save(); }
  Future<void> remove(int i) async { records.removeAt(i); await save(); }
  Future<void> clear() async { records.clear(); await save(); }
}

class GameRecord {
  final String id, type;
  final DateTime date;
  final List<String> players;
  final List<List<int>> rounds;
  final int totalRounds;
  GameRecord({required this.id, required this.type, required this.date, required this.players, required this.rounds, required this.totalRounds});
  List<int> get totals => List.generate(players.length, (i) => rounds.fold(0, (s, r) => s + r[i]));
  Map<String,dynamic> toJson()=>{'id':id,'type':type,'date':date.toIso8601String(),'players':players,'rounds':rounds,'totalRounds':totalRounds};
  factory GameRecord.fromJson(Map<String,dynamic> j)=>GameRecord(id:j['id'],type:j['type'],date:DateTime.parse(j['date']),players:List<String>.from(j['players']),rounds:(j['rounds'] as List).map((e)=>List<int>.from(e)).toList(),totalRounds:j['totalRounds']);
}

String dateLabel(DateTime d) => '${d.day}/${d.month}/${d.year}';

class HomePage extends StatefulWidget {
  final HisbaStore store; final VoidCallback onTheme;
  const HomePage({super.key, required this.store, required this.onTheme});
  @override State<HomePage> createState()=>_HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab=0;
  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    body: SafeArea(child: IndexedStack(index: tab, children:[
      _home(), HistoryPage(store:widget.store, onChanged:()=>setState((){})), StatsPage(store:widget.store),
    ])),
    bottomNavigationBar: NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[
      NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'الرئيسية'),
      NavigationDestination(icon:Icon(Icons.history),label:'السجل'),
      NavigationDestination(icon:Icon(Icons.insights_outlined),selectedIcon:Icon(Icons.insights),label:'الإحصائيات'),
    ]),
  ));
  Widget _home()=>ListView(padding:const EdgeInsets.fromLTRB(18,12,18,30),children:[
    Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('حِسبة',style:TextStyle(fontSize:42,fontWeight:FontWeight.w900)),Text('خلّي الحسبة علينا',style:TextStyle(color:muted,fontSize:16))])),IconButton(onPressed:widget.onTheme,icon:const Icon(Icons.dark_mode_outlined))]),
    const SizedBox(height:24),
    _hero(), const SizedBox(height:16),
    _gameCard(Icons.style_rounded,'لعبة ورق','3 / 5 / 7 جولات • صفر = -25',accent,()=>_openSetup('ورق')),
    const SizedBox(height:12), _gameCard(Icons.grid_view_rounded,'دومنة','نظام نقاط مرن وسجل كامل',gold,()=>_openSetup('دومنة')),
    const SizedBox(height:22),
    Row(children:[Expanded(child:Text('آخر الألعاب',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold))),TextButton(onPressed:()=>setState(()=>tab=1),child:const Text('عرض الكل'))]),
    if(widget.store.records.isEmpty) _empty() else ...widget.store.records.take(3).map((g)=>_recordTile(g)),
  ]);
  Widget _hero()=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF143038),Color(0xFF0B181D)]),borderRadius:BorderRadius.circular(24),border:Border.all(color:line)),child:Row(children:[Container(width:56,height:56,decoration:BoxDecoration(color:accent.withOpacity(.12),borderRadius:BorderRadius.circular(18)),child:const Icon(Icons.calculate_rounded,color:accent,size:30)),const SizedBox(width:14),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('احسب أسرع، العب أكثر',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),SizedBox(height:5),Text('نقاطك محفوظة وسجل الجولات دائماً بيدك.',style:TextStyle(color:muted,height:1.4))]))]));
  Widget _gameCard(IconData icon,String title,String sub,Color c,VoidCallback tap)=>Material(color:Colors.transparent,child:InkWell(onTap:tap,borderRadius:BorderRadius.circular(22),child:Ink(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(22),border:Border.all(color:line)),child:Row(children:[Container(width:56,height:56,decoration:BoxDecoration(color:c.withOpacity(.12),borderRadius:BorderRadius.circular(17)),child:Icon(icon,color:c,size:29)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:4),Text(sub,style:const TextStyle(color:muted))])),const Icon(Icons.chevron_left_rounded,color:muted)]))));
  Widget _recordTile(GameRecord g)=>Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.symmetric(horizontal:14,vertical:13),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(17),border:Border.all(color:line)),child:Row(children:[CircleAvatar(radius:22,backgroundColor:g.type=='ورق'?accent.withOpacity(.12):gold.withOpacity(.12),child:Icon(g.type=='ورق'?Icons.style:Icons.grid_view,color:g.type=='ورق'?accent:gold)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(g.type,style:const TextStyle(fontWeight:FontWeight.bold)),Text('${g.players.length} لاعبين • ${g.rounds.length}/${g.totalRounds} جولات • ${dateLabel(g.date)}',style:const TextStyle(color:muted,fontSize:12))])),Text('${g.totals.reduce((a,b)=>a>b?a:b)}',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17))]));
  Widget _empty()=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(18),border:Border.all(color:line)),child:const Text('ماكو ألعاب محفوظة بعد. ابدأ أول حسبة من فوق.',style:TextStyle(color:muted)));
  void _openSetup(String type)=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SetupPage(store:widget.store,type:type)));
}

class SetupPage extends StatefulWidget { final HisbaStore store; final String type; const SetupPage({super.key,required this.store,required this.type}); @override State<SetupPage> createState()=>_SetupPageState(); }
class _SetupPageState extends State<SetupPage>{
  int rounds=5;
  final List<String> players=['اللاعب 1','اللاعب 2','اللاعب 3','اللاعب 4'];
  final List<TextEditingController> nameControllers=[];
  final c=TextEditingController();

  @override void initState(){
    super.initState();
    nameControllers.addAll(players.map((name)=>TextEditingController(text:name)));
  }

  void add(){
    final n=c.text.trim();
    if(n.isNotEmpty&&players.length<8){
      setState((){
        players.add(n);
        nameControllers.add(TextEditingController(text:n));
        c.clear();
      });
    }
  }

  void removePlayer(int index){
    if(players.length<=2) return;
    nameControllers[index].dispose();
    setState((){
      players.removeAt(index);
      nameControllers.removeAt(index);
    });
  }

  void renamePlayer(int index,String value){
    players[index]=value;
  }

  @override void dispose(){
    c.dispose();
    for(final controller in nameControllers){controller.dispose();}
    super.dispose();
  }

  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:Text('إعداد ${widget.type}')),body:ListView(padding:const EdgeInsets.all(18),children:[
    _section('عدد الجولات'),const SizedBox(height:10),
    if(widget.type=='ورق')
      Wrap(spacing:9,children:[3,5,7,10].map((n)=>ChoiceChip(label:Text('$n'),selected:rounds==n,onSelected:(_)=>setState(()=>rounds=n))).toList())
    else
      Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:gold.withOpacity(.07),borderRadius:BorderRadius.circular(16),border:Border.all(color:gold.withOpacity(.25))),child:const Row(children:[Icon(Icons.all_inclusive_rounded,color:gold),SizedBox(width:9),Expanded(child:Text('الجولات مفتوحة — تستمر اللعبة تلقائياً إلى أن يصل أحد اللاعبين إلى 151 نقطة.'))])),
    const SizedBox(height:25),
    Row(children:[Expanded(child:_section('اللاعبون')),Text('${players.length}/8',style:const TextStyle(color:muted))]),
    const SizedBox(height:10),
    ...players.asMap().entries.map((e)=>Padding(padding:const EdgeInsets.only(bottom:9),child:Row(children:[
      CircleAvatar(radius:20,backgroundColor:e.key==0?gold.withOpacity(.13):panel2,child:Text('${e.key+1}')),
      const SizedBox(width:10),
      Expanded(child:TextField(
        controller:nameControllers[e.key],
        onChanged:(value)=>renamePlayer(e.key,value),
        textInputAction:TextInputAction.next,
        decoration:InputDecoration(hintText:'اسم اللاعب ${e.key+1}',prefixIcon:const Icon(Icons.person_outline_rounded),suffixIcon:IconButton(onPressed:()=>nameControllers[e.key].clear(),icon:const Icon(Icons.close_rounded))),
      )),
      if(e.key>=2)IconButton(tooltip:'حذف اللاعب',onPressed:()=>removePlayer(e.key),icon:const Icon(Icons.delete_outline_rounded,color:Colors.redAccent)),
    ]))),
    Row(children:[Expanded(child:TextField(controller:c,onSubmitted:(_)=>add(),decoration:const InputDecoration(hintText:'إضافة لاعب جديد',prefixIcon:Icon(Icons.person_add_alt_1_rounded)))),const SizedBox(width:8),IconButton.filled(onPressed:add,icon:const Icon(Icons.add))]),
    const SizedBox(height:10),
    const Text('تقدر تغيّر اسم أي لاعب هنا، والاسم الجديد يظهر تلقائياً في تسجيل النقاط والترتيب والسجل والإحصائيات.',style:TextStyle(color:muted,height:1.45)),
    const SizedBox(height:18),Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:gold.withOpacity(.07),borderRadius:BorderRadius.circular(17),border:Border.all(color:gold.withOpacity(.25))),child:Row(children:[const Icon(Icons.auto_awesome_outlined,color:gold),const SizedBox(width:10),Expanded(child:Text(widget.type=='ورق'?'في الورق: إدخال 0 يحسب -25 تلقائياً.':'في الدومنة: أدخل النقاط كما هي، وتكدر تتراجع عن الجولة.'))])),
    const SizedBox(height:22),SizedBox(height:56,child:FilledButton(onPressed:players.length>=2?(){
      final cleaned=players.map((name)=>name.trim()).toList();
      if(cleaned.any((name)=>name.isEmpty)){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اكتب اسم كل لاعب أولاً')));
        return;
      }
      Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>ScorePage(store:widget.store,type:widget.type,rounds:rounds,players:cleaned)));
    }:null,child:const Text('ابدأ اللعبة',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold))))
  ])));

  Widget _section(String s)=>Text(s,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold));
}

class ScorePage extends StatefulWidget {
  final HisbaStore store;
  final String type;
  final int rounds;
  final List<String> players;

  const ScorePage({
    super.key,
    required this.store,
    required this.type,
    required this.rounds,
    required this.players,
  });

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  late List<int> totals;
  late List<TextEditingController> inputs;
  final List<List<int>> history = [];
  int round = 1;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    totals = List<int>.filled(widget.players.length, 0);
    inputs = List<TextEditingController>.generate(
      widget.players.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final controller in inputs) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> saveRound() async {
    final values = inputs
        .map((controller) => int.tryParse(controller.text.trim()) ?? 0)
        .toList();

    if (inputs.every((controller) => controller.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل نقاط الجولة أولاً')),
      );
      return;
    }

    final scored = widget.type == 'ورق'
        ? values.map((value) => value == 0 ? -25 : value).toList()
        : values;

    bool finished = false;

    setState(() {
      history.add(List<int>.from(scored));
      for (var i = 0; i < totals.length; i++) {
        totals[i] += scored[i];
      }

      // الدومنة: عدد الجولات مفتوح، وتنتهي اللعبة عندما يصل أي لاعب إلى 151.
      if (widget.type == 'دومنة') {
        finished = totals.any((total) => total >= 151);
      } else {
        finished = history.length >= widget.rounds;
      }

      if (!finished) {
        round++;
        for (final controller in inputs) {
          controller.clear();
        }
      }
    });

    if (finished) {
      setState(() => saving = true);

      await widget.store.add(
        GameRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: widget.type,
          date: DateTime.now(),
          players: List<String>.of(widget.players),
          rounds: history.map((r) => List<int>.from(r)).toList(),
          // الدومنة مفتوحة؛ نخزن عدد الجولات الفعلي الذي لُعب.
          totalRounds: widget.type == 'دومنة' ? history.length : widget.rounds,
        ),
      );

      if (mounted) setState(() => saving = false);
    }
  }

  void undo() {
    if (history.isEmpty) return;
    final last = history.removeLast();

    setState(() {
      for (var i = 0; i < totals.length; i++) {
        totals[i] -= last[i];
      }
      round = history.length + 1;
      for (final controller in inputs) {
        controller.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.type == 'دومنة' ? totals.any((total) => total >= 151) : history.length >= widget.rounds;
    final width = MediaQuery.sizeOf(context).width;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          titleSpacing: 18,
          title: Row(
            children: [
              Image.asset(
                'assets/icon/hisba_icon.png',
                width: 30,
                height: 30,
                errorBuilder: (_, __, ___) => const Icon(Icons.calculate_rounded, color: gold),
              ),
              const SizedBox(width: 9),
              Text(widget.type == 'ورق' ? 'لعبة ورق' : 'دومنة'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'تراجع عن الجولة',
              onPressed: history.isEmpty ? null : undo,
              icon: const Icon(Icons.undo_rounded),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: width >= 900
                ? _wideLayout(done)
                : _mobileLayout(done),
          ),
        ),
      ),
    );
  }

  Widget _wideLayout(bool done) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 26),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 220, child: _sidePanel(done)),
          const SizedBox(width: 14),
          Expanded(child: _scoreCard(done)),
          const SizedBox(width: 14),
          SizedBox(width: 220, child: _leaderPanel()),
        ],
      ),
    );
  }

  Widget _mobileLayout(bool done) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 28),
      children: [
        _scoreCard(done),
        const SizedBox(height: 14),
        _leaderPanel(),
        const SizedBox(height: 14),
        _sidePanel(done),
      ],
    );
  }

  Widget _surface({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(14),
    double radius = 20,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _scoreCard(bool done) {
    return _surface(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      radius: 24,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تسجيل النقاط',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: Text(
                        widget.type == 'دومنة' ? 'الجولة $round • الهدف 151' : 'الجولة $round من ${widget.rounds}',
                        key: ValueKey(round),
                        style: const TextStyle(color: muted, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              _roundBadge(),
            ],
          ),
          const SizedBox(height: 13),
          if (!done) _hint(),
          const SizedBox(height: 12),
          ...widget.players.asMap().entries.map((entry) => _playerRow(entry.key, entry.value, done)),
          const SizedBox(height: 7),
          if (!done)
            SizedBox(
              height: 54,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving ? null : saveRound,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: saving
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded, key: ValueKey('check')),
                ),
                label: Text(
                  done ? 'انتهت اللعبة' : (widget.type == 'دومنة' ? 'حفظ الجولة' : (round == widget.rounds ? 'حفظ وإنهاء الجولة' : 'حفظ الجولة')),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            _finishedCard(),
          const SizedBox(height: 18),
          _rankingBlock(),
        ],
      ),
    );
  }

  Widget _roundBadge() {
    final progress = widget.type == 'دومنة'
        ? 0.0
        : (widget.rounds == 0 ? 0.0 : round / widget.rounds);
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: gold.withOpacity(.09),
        shape: BoxShape.circle,
        border: Border.all(color: gold.withOpacity(.35)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 3,
              backgroundColor: line,
              valueColor: const AlwaysStoppedAnimation<Color>(gold),
            ),
          ),
          Text(
            widget.type == 'دومنة' ? '$round' : '$round/${widget.rounds}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _hint() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: gold.withOpacity(.065),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: gold.withOpacity(.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: gold, size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.type == 'ورق'
                  ? 'في الورق: إدخال 0 يحسب -25 تلقائياً.'
                  : 'الدومنة مفتوحة حتى 151 نقطة. أدخل النقاط كما هي وتكدر تتراجع عن آخر جولة.',
              style: const TextStyle(fontSize: 12.5, color: muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerRow(int i, String name, bool done) {
    final total = totals[i];
    final positive = total >= 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: i == 0 ? const Color(0xFF101F23) : panel,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: i == 0 ? gold.withOpacity(.30) : line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: i == 0 ? gold.withOpacity(.13) : panel2,
            child: Text(
              '${i + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: i == 0 ? gold : muted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    'المجموع: $total',
                    key: ValueKey(total),
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 82,
            child: TextField(
              controller: inputs[i],
              enabled: !done,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'النقاط',
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 58,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: total.toDouble(), end: total.toDouble()),
              duration: const Duration(milliseconds: 350),
              builder: (_, value, __) => Text(
                '${value.round()}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: positive ? const Color(0xFF55E69D) : const Color(0xFFFF6B62),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _finishedCard() {
    final best = totals.isEmpty ? 0 : totals.reduce((a, b) => a > b ? a : b);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF151E1C), Color(0xFF10251D)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold.withOpacity(.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, size: 42, color: gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('انتهت اللعبة',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('أعلى مجموع: $best', style: const TextStyle(color: muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankingBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الترتيب',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ..._ranking(),
      ],
    );
  }

  List<Widget> _ranking() {
    final ranked = List.generate(
      widget.players.length,
      (i) => MapEntry(i, totals[i]),
    )..sort((a, b) => b.value.compareTo(a.value));

    return ranked.asMap().entries.map((entry) {
      final originalIndex = entry.value.key;
      return AnimatedContainer(
        duration: Duration(milliseconds: 220 + (entry.key * 30)),
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: entry.key == 0 ? gold.withOpacity(.055) : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: entry.key == 0 ? gold.withOpacity(.15) : panel2,
              child: Text('${entry.key + 1}', style: const TextStyle(fontSize: 11)),
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(widget.players[originalIndex])),
            Text(
              '${entry.value.value}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _sidePanel(bool done) {
    return Column(
      children: [
        _surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: gold),
              const SizedBox(height: 8),
              const Text('المساعد', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(
                widget.type == 'ورق'
                    ? 'الصفر = -25 تلقائياً'
                    : 'الجولات مفتوحة حتى 151 نقطة',
                style: const TextStyle(color: muted, fontSize: 12, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الجولات', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 9),
              if (widget.type == 'دومنة')
                Row(children:[
                  Icon(done ? Icons.check_circle_rounded : Icons.all_inclusive_rounded, size:16, color: done ? const Color(0xFF55E69D) : gold),
                  const SizedBox(width:7),
                  Text(done ? 'انتهت عند الجولة $round' : 'الجولة $round من عدد مفتوح', style: const TextStyle(fontSize:12,color:muted)),
                ])
              else
                ...List.generate(widget.rounds, (i) {
                  final active = i + 1 == round;
                  final finishedRound = i + 1 <= history.length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        Icon(
                          finishedRound
                              ? Icons.check_circle_rounded
                              : active
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: finishedRound
                              ? const Color(0xFF55E69D)
                              : active
                                  ? gold
                                  : muted,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'الجولة ${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: active ? Colors.white : muted,
                            fontWeight: active ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _leaderPanel() {
    final ranked = List.generate(widget.players.length, (i) => MapEntry(i, totals[i]))
      ..sort((a, b) => b.value.compareTo(a.value));

    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: gold, size: 20),
              SizedBox(width: 7),
              Text('متصدر الجولة', style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          if (ranked.isEmpty)
            const Text('—', style: TextStyle(color: muted))
          else
            ...ranked.take(5).toList().asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          entry.key == 0 ? gold.withOpacity(.14) : panel2,
                      child: Text('${entry.key + 1}',
                          style: const TextStyle(fontSize: 10)),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        widget.players[entry.value.key],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${entry.value.value}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: entry.key == 0 ? gold : muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatefulWidget{final HisbaStore store;final VoidCallback onChanged;const HistoryPage({super.key,required this.store,required this.onChanged});@override State<HistoryPage> createState()=>_HistoryPageState();}
class _HistoryPageState extends State<HistoryPage>{
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(16,18,16,30),children:[Row(children:[const Expanded(child:Text('السجل',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900))),if(widget.store.records.isNotEmpty)TextButton(onPressed:()=>_clear(),child:const Text('مسح الكل'))]),const SizedBox(height:8),if(widget.store.records.isEmpty)const Padding(padding:EdgeInsets.only(top:50),child:Center(child:Text('ماكو ألعاب محفوظة بعد',style:TextStyle(color:muted)))) else ...widget.store.records.asMap().entries.map((e)=>_card(e.key,e.value))]);
  Widget _card(int i,GameRecord g)=>Dismissible(key:ValueKey(g.id),background:Container(margin:const EdgeInsets.only(bottom:10),decoration:BoxDecoration(color:Colors.red.withOpacity(.15),borderRadius:BorderRadius.circular(18)),alignment:Alignment.centerLeft,padding:const EdgeInsets.only(left:20),child:const Icon(Icons.delete_outline,color:Colors.red)),onDismissed:(_){widget.store.remove(i);setState((){});widget.onChanged();},child:Card(color:panel,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18),side:const BorderSide(color:line)),child:ListTile(contentPadding:const EdgeInsets.all(12),leading:CircleAvatar(backgroundColor:g.type=='ورق'?accent.withOpacity(.12):gold.withOpacity(.12),child:Icon(g.type=='ورق'?Icons.style:Icons.grid_view,color:g.type=='ورق'?accent:gold)),title:Text(g.type,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${dateLabel(g.date)} • ${g.players.length} لاعبين • ${g.rounds.length}/${g.totalRounds} جولات'),trailing:Text('${g.totals.reduce((a,b)=>a>b?a:b)}',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:18)))));
  Future<void> _clear()async{final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('مسح السجل؟'),content:const Text('سيتم حذف كل الألعاب المحفوظة.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('مسح'))]));if(ok==true){await widget.store.clear();setState((){});widget.onChanged();}}
}

class StatsPage extends StatelessWidget{final HisbaStore store;const StatsPage({super.key,required this.store});@override Widget build(BuildContext context){final games=store.records;final count=games.length;final Map<String,int> wins={};for(final g in games){if(g.totals.isEmpty)continue;final m=g.totals.reduce((a,b)=>a>b?a:b);for(var i=0;i<g.players.length;i++)if(g.totals[i]==m)wins[g.players[i]]=(wins[g.players[i]]??0)+1;}final sorted=wins.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));return ListView(padding:const EdgeInsets.fromLTRB(16,18,16,30),children:[const Text('الإحصائيات',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900)),const SizedBox(height:16),Row(children:[_stat('الألعاب', '$count'),const SizedBox(width:10),_stat('اللاعبين', '${wins.length}'),const SizedBox(width:10),_stat('المتصدر', sorted.isEmpty?'—':sorted.first.key)]),const SizedBox(height:25),const Text('الأكثر فوزاً',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:10),if(sorted.isEmpty)const Text('بعدك ما عندك بيانات كافية.',style:TextStyle(color:muted)) else ...sorted.take(10).toList().asMap().entries.map((e)=>ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(backgroundColor:e.key==0?gold.withOpacity(.15):panel2,child:Text('${e.key+1}')),title:Text(e.value.key),trailing:Text('${e.value.value} فوز',style:const TextStyle(fontWeight:FontWeight.bold))))] );}
  Widget _stat(String a,String b)=>Expanded(child:Container(height:92,padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(18),border:Border.all(color:line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(color:muted)),const Spacer(),Text(b,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900))])));
}
