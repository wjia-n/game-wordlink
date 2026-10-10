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
    widget.store.lastThanks.addListener(_onThanks);
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
