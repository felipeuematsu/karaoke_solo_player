import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_karaoke_player/features/karaoke_player/components/qr_code_overlay.dart';

class IdleView extends StatelessWidget {
  const IdleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: Colors.grey,
      child: Center(
        child: FutureBuilder<String?>(
          future: getWebUrl(),
          builder: (context, snapshot) {
            if (snapshot.data == null) return const ProgressRing();
            final scale = MediaQuery.of(context).size.height / 1080;
            return Text('Acesse o endereço ${snapshot.data} no seu celular', style: const TextStyle(fontSize: 48), textScaleFactor: scale);
          },
        ),
      ),
    );
  }
}
