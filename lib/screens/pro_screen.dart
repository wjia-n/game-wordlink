import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/word_themes.dart';
import '../theme/widgets.dart';

/// Word Link PRO: Free-vs-Pro comparison, real purchase, restore, tip jar.
/// All prices come from the store — never hardcoded, never placeholders.
class ProScreen extends StatefulWidget {
  final WordLinkAudio audio;
  final WordLinkSettings settings;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  WordThemeDef get _t => WordThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      widget.audio.win();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — enjoy everything!',
              style: WlText.body(15, _t)),
          backgroundColor: _t.boardEdge,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
    }
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: WlText.body(15, _t)),
        backgroundColor: _t.boardEdge,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final store = widget.store;
    return WlBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accent),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Word Link PRO', style: WlText.display(22, t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  _ComparisonCard(theme: t, isPro: s.isPro),
                  const SizedBox(height: 16),
                  _BuyCard(
                    theme: t,
                    settings: s,
                    store: store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 16),
                  _TipsCard(
                    theme: t,
                    store: store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final WordThemeDef theme;
  final bool isPro;
  const _ComparisonCard({required this.theme, required this.isPro});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Workshop themes', '6', '14'),
      ('Letter tile styles', '4', '8'),
      ('Custom theme creator', '—', '✓'),
      ('Genius difficulty (5×5)', '—', '✓'),
      ('Hints per board', '3', 'Unlimited'),
      ('Future Pro boards', '—', '✓'),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.board,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.boardEdge, width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 3),
              blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Text('Free vs PRO', style: WlText.title(18, theme)),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  const SizedBox(),
                  Center(
                      child: Text('FREE',
                          style: WlText.label(12, theme))),
                  Center(
                      child: Text('PRO',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: theme.accent))),
                ],
              ),
              for (final r in rows)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Text(r.$1,
                          style: WlText.body(13, theme)),
                    ),
                    Center(
                        child: Text(r.$2,
                            style: WlText.body(13, theme,
                                color: theme.muted))),
                    Center(
                        child: Text(r.$3,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: theme.accent))),
                  ],
                ),
            ],
          ),
          if (isPro) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.chipFound,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('PRO active — everything unlocked',
                  style: WlText.body(13, theme)),
            ),
          ],
        ],
      ),
    );
  }
}

class _BuyCard extends StatelessWidget {
  final WordThemeDef theme;
  final WordLinkSettings settings;
  final StoreService store;
  final WordLinkAudio audio;
  const _BuyCard(
      {required this.theme,
      required this.settings,
      required this.store,
      required this.audio});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    if (settings.isPro) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: t.board,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.boardEdge, width: 2),
        ),
        child: Column(
          children: [
            Text('You are PRO', style: WlText.title(17, t)),
            const SizedBox(height: 6),
            Text(
              'One purchase, yours forever — on every device with this account.',
              style: WlText.body(13, t, color: t.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            WlButton(
              label: 'Restore purchases',
              icon: Icons.restore_outlined,
              onTap: () {
                audio.click();
                store.restore();
              },
              theme: t,
            ),
          ],
        ),
      );
    }
    final product = store.proProduct;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.board,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.accent, width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 3),
              blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Text('Unlock PRO', style: WlText.title(17, t)),
          const SizedBox(height: 6),
          Text(
            'One-time purchase. Yours forever — no subscription, no ads to remove, just more workshop.',
            style: WlText.body(13, t, color: t.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Connecting to the store…',
              style: WlText.body(13, t, color: t.muted),
              textAlign: TextAlign.center,
            )
          else if (product != null)
            ValueListenableBuilder<bool>(
              valueListenable: store.purchaseInProgress,
              builder: (_, busy, _) => Opacity(
                opacity: busy ? 0.6 : 1.0,
                child: WlButton(
                  label: 'Get PRO · ${product.price}',
                  icon: Icons.workspace_premium_outlined,
                  onTap: busy ? () {} : () => store.buyPro(),
                  theme: t,
                  primary: true,
                ),
              ),
            ),
          const SizedBox(height: 10),
          ValueListenableBuilder<String?>(
            valueListenable: store.purchaseError,
            builder: (_, err, _) => err == null
                ? const SizedBox()
                : Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(err,
                        style: WlText.body(13, t,
                            color: Colors.red.shade300),
                        textAlign: TextAlign.center),
                  ),
          ),
          TextButton(
            onPressed: () {
              audio.click();
              store.restore();
            },
            child: Text('Restore purchases',
                style: WlText.body(13, t, color: t.accent)),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final WordThemeDef theme;
  final StoreService store;
  final WordLinkAudio audio;
  const _TipsCard(
      {required this.theme, required this.store, required this.audio});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    Widget tipButton(ProductDetails? p, String label, IconData icon) {
      if (p == null) return const SizedBox();
      return Expanded(
        child: ValueListenableBuilder<bool>(
          valueListenable: store.purchaseInProgress,
          builder: (_, busy, _) => WlButton(
            label: '$label · ${p.price}',
            icon: icon,
            onTap: busy ? () {} : () => store.buyTip(p),
            theme: t,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.board,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.boardEdge, width: 2),
      ),
      child: Column(
        children: [
          Text('Tip the workshop', style: WlText.title(17, t)),
          const SizedBox(height: 6),
          Text(
            'Word Link is made by one indie maker. Tips keep the tiles coming — totally optional, always appreciated.',
            style: WlText.body(13, t, color: t.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Connecting to the store…',
              style: WlText.body(13, t, color: t.muted),
              textAlign: TextAlign.center,
            )
          else
            Row(
              children: [
                tipButton(store.coffeeProduct, 'Coffee',
                    Icons.coffee_outlined),
                const SizedBox(width: 10),
                tipButton(store.chocolateProduct, 'Chocolate',
                    Icons.cookie_outlined),
              ],
            ),
        ],
      ),
    );
  }
}
