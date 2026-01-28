// lib/screen/care_news_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CareNewsScreen extends StatefulWidget {
  const CareNewsScreen({super.key});

  @override
  State<CareNewsScreen> createState() => _CareNewsScreenState();
}

class _CareNewsScreenState extends State<CareNewsScreen> {
  // ✅ แหล่งข่าวสุขภาพภาษาไทย (RSS จริง)
  final List<CareNewsSource> sources = const [
    CareNewsSource(
      id: 'anamai',
      name: 'กรมอนามัย',
      siteUrl: 'https://anamai.moph.go.th',
      rssUrl: 'https://anamai.moph.go.th/th/rss.xml',
    ),
    CareNewsSource(
      id: 'thaihealth',
      name: 'สสส.',
      siteUrl: 'https://www.thaihealth.or.th',
      rssUrl: 'https://www.thaihealth.or.th/feed/',
    ),
    CareNewsSource(
      id: 'siriraj',
      name: 'โรงพยาบาลศิริราช',
      siteUrl: 'https://www.si.mahidol.ac.th',
      rssUrl: 'https://www.si.mahidol.ac.th/rss/news.xml',
    ),
    CareNewsSource(
      id: 'rama',
      name: 'โรงพยาบาลรามาธิบดี',
      siteUrl: 'https://www.rama.mahidol.ac.th',
      rssUrl: 'https://www.rama.mahidol.ac.th/rss/news.xml',
    ),
  ];

  int selectedIndex = 0;
  bool loading = false;
  String? error;
  List<CareNewsItem> items = [];

  CareNewsSource get selected => sources[selectedIndex];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
      items = [];
    });

    try {
      final res = await http
          .get(Uri.parse(selected.rssUrl))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw Exception('โหลด RSS ไม่สำเร็จ (${res.statusCode})');
      }

      final body = utf8.decode(res.bodyBytes);
      final parsed = _parseRss(body);

      setState(() {
        items = parsed.take(20).toList();
        loading = false;
      });
    } catch (e) {
      // ✅ เก็บ error ไว้เงียบๆ (ไม่แสดงข้อความข้างล่างแล้ว)
      setState(() {
        error = e.toString();
        loading = false;
        items = [];
      });
    }
  }

  List<CareNewsItem> _parseRss(String xmlText) {
    final doc = XmlDocument.parse(xmlText);
    final rssItems = doc.findAllElements('item');

    return rssItems
        .map((n) {
          final title = n.getElement('title')?.innerText.trim() ?? '';
          final link = n.getElement('link')?.innerText.trim() ?? '';
          final pubDate = n.getElement('pubDate')?.innerText.trim();

          return CareNewsItem(title: title, url: link, subtitle: pubDate);
        })
        .where((e) => e.title.isNotEmpty && e.url.isNotEmpty)
        .toList();
  }

  void _openWeb(String url, {String? title}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _WebViewPage(title: title ?? 'ข่าวสารสุขภาพ', url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final src = selected;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text('ข่าวสารการดูแลสุขภาพ'),
        backgroundColor: const Color(0xFF660F24),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // เลือกแหล่งข่าว
            SizedBox(
              height: 54,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                scrollDirection: Axis.horizontal,
                itemCount: sources.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final s = sources[i];
                  final active = i == selectedIndex;
                  return ChoiceChip(
                    selected: active,
                    label: Text(s.name),
                    onSelected: (_) {
                      setState(() => selectedIndex = i);
                      _load();
                    },
                    selectedColor: const Color(0xFF660F24).withOpacity(.15),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: active ? const Color(0xFF660F24) : Colors.black87,
                    ),
                  );
                },
              ),
            ),

            // หัวข้อ
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Material(
                color: Colors.white,
                elevation: 2,
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  leading: const Icon(
                    Icons.newspaper_outlined,
                    color: Color(0xFF660F24),
                  ),
                  title: Text(
                    src.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text('ดึงข่าวจาก RSS อย่างเป็นทางการ'),
                  trailing: TextButton.icon(
                    onPressed: () => _openWeb(src.siteUrl, title: src.name),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('เว็บไซต์'),
                  ),
                ),
              ),
            ),

            // รายการข่าว
            Expanded(
              child: Builder(
                builder: (_) {
                  if (loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // ✅ ไม่แสดงข้อความ error ใดๆ แล้ว
                  if (error != null) {
                    return const SizedBox.shrink();
                  }

                  if (items.isEmpty) {
                    return const Center(child: Text('ยังไม่มีข่าว'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      return Material(
                        color: Colors.white,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          title: Text(
                            it.title,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: it.subtitle == null
                              ? null
                              : Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(it.subtitle!),
                                ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF660F24),
                          ),
                          onTap: () => _openWeb(it.url, title: src.name),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Models ----------------

class CareNewsSource {
  final String id;
  final String name;
  final String siteUrl;
  final String rssUrl;

  const CareNewsSource({
    required this.id,
    required this.name,
    required this.siteUrl,
    required this.rssUrl,
  });
}

class CareNewsItem {
  final String title;
  final String url;
  final String? subtitle;

  const CareNewsItem({required this.title, required this.url, this.subtitle});
}

// ---------------- WebView ----------------

class _WebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const _WebViewPage({required this.title, required this.url});

  @override
  State<_WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<_WebViewPage> {
  late final WebViewController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF660F24),
        foregroundColor: Colors.white,
      ),
      body: WebViewWidget(controller: _ctl),
    );
  }
}
