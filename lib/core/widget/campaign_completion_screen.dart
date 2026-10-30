import 'package:flutter/material.dart';
import '../../services/ads_service.dart';

class CampaignCompletionScreen extends StatefulWidget {
  const CampaignCompletionScreen({super.key, required this.title, required this.onContinue});
  final String title;
  final VoidCallback onContinue;
  @override
  State<CampaignCompletionScreen> createState() => _CampaignCompletionScreenState();
}
class _CampaignCompletionScreenState extends State<CampaignCompletionScreen> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => PopScope(canPop: !busy, child: Scaffold(
    backgroundColor: const Color(0xFF080D20),
    body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children:[
      const Icon(Icons.auto_awesome, color: Color(0xFF65E9FF), size:80),
      const SizedBox(height:24),
      const Text('CONGRATULATIONS', style:TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w900)),
      const SizedBox(height:12),Text(widget.title,style:const TextStyle(color:Color(0xFF65E9FF),fontSize:20)),
      const SizedBox(height:12),const Text('Energy recovered. Reality restored.',style:TextStyle(color:Colors.white70)),
      const SizedBox(height:28),FilledButton(onPressed:busy ? null : () async {
        setState(() => busy=true);
        await AdsService.instance.showInterstitialAtTransition();
        if(mounted) widget.onContinue();
      },child:Text(busy ? 'PLEASE WAIT…' : 'RETURN TO LEVELS')),
    ]))),
  ));
}
