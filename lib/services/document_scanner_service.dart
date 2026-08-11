Future<void> _gestisciScattoFoto(String imagePath) async {
  final wallet = Provider.of<WalletProvider>(context, listen: false);

  // 🔄 Mostra caricamento...
  final ScanResult result = await DocumentScannerService.scanDocument(
    imagePath: imagePath,
    wallet: wallet,
  );

  setState(() {
    if (result.importo != null) {
      _importoController.text = result.importo!.toStringAsFixed(2);
    }
    if (result.piva != null) {
      _pivaController.text = result.piva!;
    }
    if (result.ragioneSociale != null) {
      _clienteController.text = result.ragioneSociale!;
    }
  });

  // 💬 Notifica trasparente sull'engine utilizzato
  final messaggio = result.metodoUsato == 'AI_VISION'
      ? '🤖 Documento analizzato con AI Vision Pro!'
      : '⚡ Dati estratti con scansione veloce.';

  AppNotifications.mostraInAlto(context, messaggio, type: NotificationType.success);
}