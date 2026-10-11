import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:archive/archive.dart';

void main() => runApp(const EduTvVaultApp());

class EduTvVaultApp extends StatelessWidget {
  const EduTvVaultApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'edutv VAULT',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: const VaultScreen(),
    );
  }
}

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});
  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  String? lastCode;
  String status = "Pronto para gerar";
  bool isProcessing = false;
  final String bucket = "Edutv_Jequeri_MG_9kX2pL77_2026_A7";
  final String vaultPath = "/storage/emulated/0/edutv_vault";

  String generate11Digits() {
    final rand = Random.secure();
    String code = "";
    for (int i = 0; i < 11; i++) code += rand.nextInt(10).toString();
    return code;
  }

  Future<void> createVault(String code) async {
    setState(() { isProcessing = true; status = "Criando cofre $code..."; });
    await Permission.manageExternalStorage.request();
    await Permission.storage.request();
    try {
      final dir = Directory("$vaultPath/$code");
      if (!await dir.exists()) await dir.create(recursive: true);
      final configFile = File("${dir.path}/$code.config");
      await configFile.writeAsString("BUCKET=$bucket\nCODE=$code\nPATH=${dir.path}\nSTATUS=ACTIVE\nTYPE=DISPOSABLE_11DIGITS\nGERADO=${DateTime.now()}\nAUTO_DELETE=1 USO\n");
      final archive = Archive();
      final bytes = await configFile.readAsBytes();
      archive.addFile(ArchiveFile("$code.config", bytes.length, bytes));
      final zipData = ZipEncoder().encode(archive);
      await File("${dir.path}/$code.zip").writeAsBytes(zipData!);
      setState(() { lastCode = code; status = "Cofre $code criado!\nEm: ${dir.path}"; isProcessing = false; });
    } catch (e) {
      setState(() { status = "Erro: $e"; isProcessing = false; });
    }
  }

  Future<void> deleteVault(String code) async {
    final dir = Directory("$vaultPath/$code");
    if (await dir.exists()) await dir.delete(recursive: true);
    setState(() { status = "Cofre $code DESTRUIDO (1 uso)"; lastCode = null; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("edutv VAULT - Jequeri MG", style: TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold)), backgroundColor: Colors.black, centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(border: Border.all(color: const Color(0xFF00FF88)), borderRadius: BorderRadius.circular(12), color: const Color(0xFF111111)), child: Column(children: [const Text("CODIGO ATUAL", style: TextStyle(color: Colors.white54, letterSpacing: 2)), const SizedBox(height: 10), Text(lastCode ?? "SEM CODIGO", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF00FF88), letterSpacing: 4)), const SizedBox(height: 10), Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))])),
          const SizedBox(height: 20),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF88), foregroundColor: Colors.black, padding: const EdgeInsets.all(18)), onPressed: isProcessing ? null : () => createVault(generate11Digits()), child: Text(isProcessing ? "GERANDO..." : "GERAR CODIGO 11 DIGITOS", style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 12),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.all(18)), onPressed: lastCode == null ? null : () => deleteVault(lastCode!), child: const Text("DESTRUIR COFRE (AUTO-DELETE)", style: TextStyle(fontWeight: FontWeight.bold))),
          const Spacer(),
          Text("Bucket: $bucket\nPath: $vaultPath\nModo: Descartavel 1 uso", style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ),
    );
  }
}
