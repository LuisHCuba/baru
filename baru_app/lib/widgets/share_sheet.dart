import 'package:flutter/material.dart';

import '../share/habitat_share.dart';
import '../l10n_humor.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';
import 'habitat.dart';

class ShareSheet extends StatefulWidget {
  const ShareSheet({super.key});

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final GlobalKey _boundary = GlobalKey();
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _kick());
  }

  Future<void> _kick() async {
    if (_started || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    await _share();
  }

  Future<void> _share() async {
    if (_started || !mounted) return;
    _started = true;
    final app = AppScope.of(context);
    // O que sai do app tem de dizer o mesmo que a tela: quem recebe a
    // imagem não tem contexto nenhum além desta linha.
    final caption = app.t.humorCap(app.falaDoHumor);
    final ok = await HabitatShare.share(boundaryKey: _boundary, text: caption);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(app.t.shareFail),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: IgnorePointer(
              child: SizedBox(
                width: 402,
                height: 296,
                child: RepaintBoundary(
                  key: _boundary,
                  child: const HabitatScene(),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: app.closeShare,
            child: Container(
              color: AppColors.ink.withValues(alpha: 0.42),
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 34),
                  decoration: const BoxDecoration(
                    color: AppColors.shareSheet,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.share)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.inkA(0.18),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          _started = false;
                          _share();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 74,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.shareThumb,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: const FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: 402,
                                    height: 296,
                                    child: HabitatScene(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'habitat.png',
                                      style: nunito(size: 14.5, weight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      app.t.shareMeta,
                                      style: nunito(
                                        size: 12.5,
                                        color: AppColors.inkA(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const AppIcon(
                                Icons.share_outlined,
                                size: 20,
                                color: AppColors.green,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        app.t.shareNote,
                        textAlign: TextAlign.center,
                        style: nunito(size: 12.5, height: 1.5, color: AppColors.inkA(0.5)),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: app.closeShare,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            app.t.shareDone,
                            style: nunito(
                              size: 16,
                              weight: FontWeight.w700,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ),
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
