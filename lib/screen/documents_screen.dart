import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class DocumentsScreen extends StatefulWidget {
  final String patientId;
  const DocumentsScreen({super.key, required this.patientId});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  CollectionReference<Map<String, dynamic>> get _docCol => FirebaseFirestore
      .instance
      .collection('patients')
      .doc(widget.patientId)
      .collection('documents');

  Future<void> _pickAndUpload() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'heic'],
    );
    if (res == null) return;

    for (final f in res.files) {
      final path = f.path;
      if (path == null) continue;

      final file = File(path);
      final ext = (f.extension ?? '').toLowerCase();
      final isImage = ['jpg', 'jpeg', 'png', 'heic'].contains(ext);

      // อัปโหลดไป Storage
      final name = '${DateTime.now().millisecondsSinceEpoch}_${f.name}';
      final ref = FirebaseStorage.instance.ref(
        'patients/${widget.patientId}/docs/$name',
      );
      final task = await ref.putFile(file);
      final url = await task.ref.getDownloadURL();

      // บันทึกลง Firestore
      await _docCol.add({
        'name': f.name,
        'url': url,
        'ext': ext,
        'type': isImage ? 'image' : (ext == 'pdf' ? 'pdf' : 'file'),
        'size': f.size,
        'createdAt': FieldValue.serverTimestamp(),
        'note': '',
        'tags': [],
      });
    }
  }

  Future<void> _deleteDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบไฟล์นี้?'),
        content: Text((d['name'] ?? '').toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final url = (d['url'] ?? '').toString();
      if (url.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(url).delete();
      }
    } catch (_) {
      // ถ้าลบ Storage ไม่ได้ ก็ลบเฉพาะใน Firestore
    }
    await d.reference.delete();
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'pdf':
        return const Color(0xFFD32F2F);
      case 'image':
        return const Color(0xFF1976D2);
      default:
        return const Color(0xFF455A64);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        // ⬅️ ใส่ปุ่มย้อนกลับมุมซ้ายบน
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'ย้อนกลับ',
          onPressed: () => Navigator.maybePop(context),
        ),
        foregroundColor: Colors.black87,
        title: const Text('เอกสาร/รูปภาพสุขภาพ'),
        actions: [
          IconButton(
            onPressed: _pickAndUpload,
            icon: const Icon(Icons.add_to_photos_outlined),
            tooltip: 'อัปโหลดไฟล์',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _docCol.orderBy('createdAt', descending: true).snapshots(),
        builder: (_, snap) {
          if (snap.hasError) {
            return const Center(child: Text('โหลดเอกสารไม่สำเร็จ'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return _EmptyState(
              icon: Icons.folder_open_rounded,
              title: 'ยังไม่มีไฟล์',
              message:
                  'อัปโหลดเอกสาร/รูปภาพด้วยปุ่ม “+” มุมขวาบน\nหรือแตะปุ่มด้านล่างเพื่อเริ่มต้น',
              actionText: 'อัปโหลดไฟล์',
              onAction: _pickAndUpload,
              accent: const Color(0xFFF24455),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.80,
            ),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i];
              final type = (d['type'] ?? 'file').toString();
              final name = (d['name'] ?? '').toString();
              final url = (d['url'] ?? '').toString();
              final color = _typeColor(type);

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 3,
                shadowColor: Colors.black.withOpacity(.08),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    // หมายเหตุ: OpenFilex มักต้อง path ในเครื่อง
                    // ถ้าเปิด URL ไม่ได้ อาจต้องดาวน์โหลดมาเก็บชั่วคราวก่อน
                    await OpenFilex.open(url);
                  },
                  onLongPress: () => _deleteDoc(d),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Preview
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _DocPreview(
                              type: type,
                              url: url,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // ชื่อไฟล์
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // ชิปชนิดไฟล์ + ปุ่มลบ
                        Row(
                          children: [
                            _TypeChip(label: type.toUpperCase(), color: color),
                            const Spacer(),
                            IconButton(
                              tooltip: 'ลบ',
                              visualDensity: const VisualDensity(
                                horizontal: -4,
                                vertical: -4,
                              ),
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteDoc(d),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      // เผื่ออยากกดอัปโหลดตรงนี้ด้วย
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUpload,
        icon: const Icon(Icons.file_upload_outlined),
        label: const Text('อัปโหลด'),
      ),
    );
  }
}

/// ─────────────────────────── Widgets ───────────────────────────

class _DocPreview extends StatelessWidget {
  final String type;
  final String url;
  final Color color;
  const _DocPreview({
    required this.type,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (type == 'image') {
      return Image.network(url, fit: BoxFit.cover);
    }
    // พื้นหลังอ่อน + ไอคอนชนิดไฟล์
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(.08), color.withOpacity(.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          type == 'pdf'
              ? Icons.picture_as_pdf_outlined
              : Icons.insert_drive_file_outlined,
          size: 48,
          color: color,
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TypeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(.24)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: .4,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? accent;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withOpacity(.65),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            if (actionText != null && onAction != null)
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.file_upload_outlined),
                label: Text(actionText!),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
