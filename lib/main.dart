import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProFileAUXApp());
}

class ProFileAUXApp extends StatelessWidget {
  const ProFileAUXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ProFile AUX',
      theme: ThemeData(useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}

class PrefStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kHudPro = 'hudPro';
  static const _kFpsOpt = 'fpsOpt';
  static const _kSens = 'sens';
  static const _kFov = 'fov';
  static const _kAux = 'aux';
  static const _kModo = 'modo';
  static const _kLastApply = 'lastApply';

  static Future<Prefs> load() async {
    final m = await _storage.readAll();
    return Prefs(
      hudPro: (m[_kHudPro] ?? 'true') == 'true',
      fpsOpt: (m[_kFpsOpt] ?? 'true') == 'true',
      sens: (m[_kSens] ?? 'true') == 'true',
      fov: int.tryParse(m[_kFov] ?? '') ?? 100,
      aux: AuxMode.fromString(m[_kAux]),
      modo: FireMode.fromString(m[_kModo]),
      lastApply: _parseIso(m[_kLastApply]),
    );
  }

  static DateTime? _parseIso(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static Future<void> save(Prefs p) async {
    await _storage.write(key: _kHudPro, value: p.hudPro.toString());
    await _storage.write(key: _kFpsOpt, value: p.fpsOpt.toString());
    await _storage.write(key: _kSens, value: p.sens.toString());
    await _storage.write(key: _kFov, value: p.fov.toString());
    await _storage.write(key: _kAux, value: p.aux.value);
    await _storage.write(key: _kModo, value: p.modo.value);
    await _storage.write(key: _kLastApply, value: p.lastApply?.toIso8601String() ?? '');
  }
}

enum AuxMode {
  external('EXTERNAL', 'AUXÍLIO EXTERNAL'),
  internal('INTERNAL', 'AUXÍLIO INTERNAL');

  final String value;
  final String label;
  const AuxMode(this.value, this.label);

  static AuxMode fromString(String? s) {
    if ((s ?? '').toUpperCase() == 'INTERNAL') return AuxMode.internal;
    return AuxMode.external;
  }
}

enum FireMode {
  atira('ATIRAR', 'AO ATIRA'),
  olha('OLHAR', 'AO OLHA');

  final String value;
  final String label;
  const FireMode(this.value, this.label);

  static FireMode fromString(String? s) {
    if ((s ?? '').toUpperCase() == 'OLHAR') return FireMode.olha;
    return FireMode.atira;
  }
}

class Prefs {
  bool hudPro;
  bool fpsOpt;
  bool sens;
  int fov;
  AuxMode aux;
  FireMode modo;
  DateTime? lastApply;

  Prefs({
    required this.hudPro,
    required this.fpsOpt,
    required this.sens,
    required this.fov,
    required this.aux,
    required this.modo,
    required this.lastApply,
  });

  Prefs copyWith({
    bool? hudPro,
    bool? fpsOpt,
    bool? sens,
    int? fov,
    AuxMode? aux,
    FireMode? modo,
    DateTime? lastApply,
  }) {
    return Prefs(
      hudPro: hudPro ?? this.hudPro,
      fpsOpt: fpsOpt ?? this.fpsOpt,
      sens: sens ?? this.sens,
      fov: fov ?? this.fov,
      aux: aux ?? this.aux,
      modo: modo ?? this.modo,
      lastApply: lastApply ?? this.lastApply,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  final TextEditingController _pinCtrl = TextEditingController();
  bool _checking = true;
  bool _bioAvailable = false;
  String? _error;

  static const String _pinFixed = 'ProFileLITE';
  static const String _pinFixedAlt = 'ProFile';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      setState(() {
        _bioAvailable = canCheck && supported;
        _checking = false;
      });

      if (_bioAvailable) {
        await _tryBiometric();
      }
    } catch (_) {
      setState(() {
        _checking = false;
        _bioAvailable = false;
        _error = 'Biometria indisponível neste dispositivo.';
      });
    }
  }

  Future<void> _tryBiometric() async {
    setState(() => _error = null);
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Desbloquear ProFile AUX',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (_) {
      setState(() => _error = 'Falha na biometria. Use o PIN.');
    }
  }

  void _tryPin() {
    final pin = _pinCtrl.text.trim();
    if (pin == _pinFixed || pin == _pinFixedAlt) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() => _error = 'PIN incorreto.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1230),
      body: Stack(
        children: [
          const _NeonBackground(),
          SafeArea(
            child: Center(
              child: _GlassCard(
                width: 380,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _LogoHeader(title: 'ProFile AUX', subtitle: 'Login Seguro'),
                      const SizedBox(height: 16),
                      if (_checking) ...[
                        const SizedBox(height: 6),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 14),
                        Text('Verificando biometria...',
                            style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      ] else ...[
                        if (_bioAvailable) ...[
                          _PrimaryButton(
                            text: 'DESBLOQUEAR COM FACE ID / TOUCH ID',
                            onTap: _tryBiometric,
                          ),
                          const SizedBox(height: 12),
                          Text('ou use o PIN:',
                              style: TextStyle(color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 10),
                        ] else ...[
                          Text('Biometria não disponível. Use o PIN:',
                              style: TextStyle(color: Colors.white.withOpacity(0.65))),
                          const SizedBox(height: 10),
                        ],
                        TextField(
                          controller: _pinCtrl,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Digite o PIN',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                            ),
                          ),
                          onSubmitted: (_) => _tryPin(),
                        ),
                        const SizedBox(height: 12),
                        _PrimaryButton(
                          text: 'ENTRAR',
                          onTap: _tryPin,
                        ),
                        const SizedBox(height: 8),
                        Text('PIN padrão: ProFileLITE',
                            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Prefs? _prefs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await PrefStore.load();
    setState(() {
      _prefs = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1230),
      body: Stack(
        children: [
          const _NeonBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      Text(
                        "ProFile AUX",
                        style: TextStyle(
                          color: Colors.lightBlueAccent.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        icon: Icon(Icons.logout_rounded, color: Colors.lightBlueAccent.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _GlassCard(
                      width: MediaQuery.of(context).size.width * 0.92,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : _HomeContent(
                                prefs: _prefs!,
                                onChanged: (p) => setState(() => _prefs = p),
                                onSave: (p) async {
                                  await PrefStore.save(p);
                                  setState(() => _prefs = p);
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final Prefs prefs;
  final ValueChanged<Prefs> onChanged;
  final Future<void> Function(Prefs) onSave;

  const _HomeContent({
    required this.prefs,
    required this.onChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final lastApply = prefs.lastApply == null
        ? 'Nunca'
        : DateFormat('dd/MM/yyyy HH:mm').format(prefs.lastApply!.toLocal());

    return SingleChildScrollView(
      child: Column(
        children: [
          const _LogoHeader(title: 'ProFile', subtitle: 'Neon Dashboard'),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniToggleCard(
                  title: "HUD Pro",
                  value: prefs.hudPro,
                  onChanged: (v) => onChanged(prefs.copyWith(hudPro: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniToggleCard(
                  title: "Otimização",
                  value: prefs.fpsOpt,
                  onChanged: (v) => onChanged(prefs.copyWith(fpsOpt: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniToggleCard(
                  title: "Sensibilidade",
                  value: prefs.sens,
                  onChanged: (v) => onChanged(prefs.copyWith(sens: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniNavCard(
                  title: "Dicas",
                  onTap: () => TipsModal.show(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BigSliderCard(
            labelLeft: "FOV",
            labelRight: "${prefs.fov}%",
            value: prefs.fov.toDouble(),
            onChanged: (v) => onChanged(prefs.copyWith(fov: v.round().clamp(1, 100))),
          ),
          const SizedBox(height: 14),
          _DropdownCard(
            value: prefs.aux,
            items: const [AuxMode.external, AuxMode.internal],
            onChanged: (v) => onChanged(prefs.copyWith(aux: v)),
          ),
          const SizedBox(height: 16),
          Text(
            "funções:",
            style: TextStyle(
              color: const Color(0xFFB48CFF).withOpacity(0.95),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PillButton(
                  text: "AO ATIRA",
                  selected: prefs.modo == FireMode.atira,
                  onTap: () => onChanged(prefs.copyWith(modo: FireMode.atira)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PillButton(
                  text: "AO OLHA",
                  selected: prefs.modo == FireMode.olha,
                  onTap: () => onChanged(prefs.copyWith(modo: FireMode.olha)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PrimaryButton(
            text: "APLICAR",
            onTap: () async {
              final allowed = await PermissionModal.ask(context);
              if (!context.mounted) return;
              if (!allowed) {
                _toast(context, 'Permissão negada.');
                return;
              }
              final ok = await ApplyProgressModal.run(context);
              if (!context.mounted) return;
              if (ok) {
                final saved = prefs.copyWith(lastApply: DateTime.now());
                await onSave(saved);
                _toast(context, 'Sucesso! Preferências salvas.');
              }
            },
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            text: "ABRIR FREE FIRE",
            onTap: () => _runShortcut(context, 'Abrir Free Fire'),
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            text: "ABRIR FREE FIRE MAX",
            onTap: () => _runShortcut(context, 'Abrir Free Fire Max'),
          ),
          const SizedBox(height: 16),
          _InfoPill(text: 'Última aplicação: $lastApply'),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  static Future<void> _runShortcut(BuildContext context, String name) async {
    final encoded = Uri.encodeComponent(name);
    final uri = Uri.parse('shortcuts://run-shortcut?name=$encoded');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      _toast(context, 'Não foi possível abrir o Atalho. Verifique se existe: "$name".');
    }
  }
}

class PermissionModal {
  static Future<bool> ask(BuildContext context) async {
    return (await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dctx) => AlertDialog(
            backgroundColor: const Color(0xFF121A3F),
            title: const Text('Permissão', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            content: Text(
              'Permitir aplicar estas preferências locais?',
              style: TextStyle(color: Colors.white.withOpacity(0.75)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dctx, false),
                child: const Text('Negar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dctx, true),
                child: const Text('Permitir'),
              ),
            ],
          ),
        )) ??
        false;
  }
}

class ApplyProgressModal {
  static Future<bool> run(BuildContext context) async {
    bool done = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dctx) => _ProgressDialog(
        title: 'Aplicando...',
        subtitle: 'Salvando preferências',
        duration: const Duration(seconds: 3),
        onDone: () {
          done = true;
          Navigator.pop(dctx);
        },
      ),
    );
    return done;
  }
}

class TipsModal {
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _TipsDialog(),
    );
  }
}

class _ProgressDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Duration duration;
  final VoidCallback onDone;

  const _ProgressDialog({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  double _p = 0.0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    final totalMs = widget.duration.inMilliseconds;
    const tickMs = 40;
    _t = Timer.periodic(const Duration(milliseconds: tickMs), (t) {
      setState(() {
        _p += tickMs / totalMs;
        if (_p >= 1.0) {
          _p = 1.0;
          t.cancel();
          widget.onDone();
        }
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF121A3F),
      title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.72))),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: _p),
          const SizedBox(height: 8),
          Text('${(_p * 100).round()}%', style: TextStyle(color: Colors.white.withOpacity(0.75))),
        ],
      ),
    );
  }
}

class _TipsDialog extends StatefulWidget {
  const _TipsDialog();

  @override
  State<_TipsDialog> createState() => _TipsDialogState();
}

class _TipsDialogState extends State<_TipsDialog> {
  bool _loading = true;
  double _p = 0.0;
  Timer? _t;

  final List<String> _tips = const [
    'HUD: deixe o botão de atirar confortável (próximo do polegar). Evite posições muito “esticadas”.',
    'Sensibilidade: ajuste aos poucos; altere 5–10 pontos e teste por 3–5 partidas antes de mudar de novo.',
    'Gelo: treine “gelo rápido” em modo treino; priorize posicionar o gelo na linha de tiro do inimigo.',
    'Rotação: use capas/gelos como pontos de parada; não corra em linha reta em campo aberto.',
    'Mira: puxe levemente para cima ao atirar (controle de recoil) — menos força = mais precisão.',
    'Config gráfico: se seu celular esquenta, baixe sombras e efeitos para manter FPS estável.',
    'Som: use fone e ajuste o volume do jogo; passos e recargas entregam posição.',
    'Treino: 10 min por dia no treino melhora mais do que “maratonar” uma vez por semana.',
  ];

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 40), (t) {
      setState(() {
        _p += 0.03;
        if (_p >= 1.0) {
          _p = 1.0;
          _loading = false;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF121A3F),
      title: const Text('Dicas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 420,
        child: _loading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Carregando dicas...',
                      style: TextStyle(color: Colors.white.withOpacity(0.72))),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: _p),
                  const SizedBox(height: 8),
                  Text('${(_p * 100).round()}%',
                      style: TextStyle(color: Colors.white.withOpacity(0.72))),
                ],
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _tips.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.08)),
                  itemBuilder: (_, i) => Text(
                    '• ${_tips[i]}',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), height: 1.35),
                  ),
                ),
              ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class _NeonBackground extends StatelessWidget {
  const _NeonBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.2, -0.4),
                radius: 1.2,
                colors: [
                  Color(0xFF1B2B7A),
                  Color(0xFF1A1140),
                  Color(0xFF070A1A),
                ],
              ),
            ),
          ),
        ),
        const Positioned(left: -80, top: 80, child: _GlowBlob(color: Color(0xFF7B2CFF), size: 260)),
        const Positioned(right: -60, bottom: 120, child: _GlowBlob(color: Color(0xFF00C2FF), size: 240)),
      ],
    );
  }
}

class _LogoHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LogoHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B2CFF).withOpacity(0.25),
                blurRadius: 22,
                spreadRadius: 2,
              )
            ],
          ),
          child: const Center(
            child: Text(
              "PF",
              style: TextStyle(
                color: Color(0xFF22D3FF),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF22D3FF),
            fontWeight: FontWeight.w800,
            fontSize: 34,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.55), color.withOpacity(0.0)],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double width;
  const _GlassCard({required this.child, required this.width});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFB04CFF).withOpacity(0.35), width: 2),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MiniToggleCard extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MiniToggleCard({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _InnerCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _MiniNavCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _MiniNavCard({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _InnerCard(
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}

class _BigSliderCard extends StatelessWidget {
  final String labelLeft;
  final String labelRight;
  final double value;
  final ValueChanged<double> onChanged;

  const _BigSliderCard({
    required this.labelLeft,
    required this.labelRight,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _InnerCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(labelLeft, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
              Text(
                labelRight,
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontWeight: FontWeight.w800, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            min: 1,
            max: 100,
            divisions: 99,
            value: value.clamp(1, 100),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DropdownCard extends StatelessWidget {
  final AuxMode value;
  final List<AuxMode> items;
  final ValueChanged<AuxMode> onChanged;

  const _DropdownCard({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _InnerCard(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AuxMode>(
          isExpanded: true,
          value: value,
          dropdownColor: const Color(0xFF131A3F),
          iconEnabledColor: Colors.white.withOpacity(0.7),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _InnerCard extends StatelessWidget {
  final Widget child;
  const _InnerCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: child,
    );
  }
}

class _PillButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _PillButton({required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? const Color(0xFF1B78FF).withOpacity(0.22) : Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.6),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _PrimaryButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF7B2CFF).withOpacity(0.25),
              const Color(0xFF00C2FF).withOpacity(0.18),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.1),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;
  const _InfoPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withOpacity(0.70), fontWeight: FontWeight.w600),
      ),
    );
  }
}
