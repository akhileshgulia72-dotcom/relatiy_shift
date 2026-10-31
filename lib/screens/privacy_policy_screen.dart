import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const privacyPolicyUrl =
    'https://akhileshgulia72-dotcom.github.io/relatiy_shift/privacy-policy.html';

/// The bundled policy stays readable even when the device is offline.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacy policy')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "Reality Shift · Last updated: October 25, 2026",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "This Privacy Policy explains how Reality Shift (the “Game”) handles information. The Game is published by Akhilesh Gulia (“we,” “us,” or “our”).",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "Information handled by the Game",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "The Game does not ask you to create an account and does not send your puzzle progress or settings to our own servers. Progress, scores, coins, and preferences are stored locally on your device using the platform’s app storage. They remain on that device unless you clear the app’s data or remove the Game.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "On supported devices, a level can use accelerometer readings to control gameplay. These readings are used in real time for that game feature; the Game does not use them to determine your location or retain them as a player profile.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "Advertising",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "The Android and iOS versions include the Google Mobile Ads (AdMob) SDK and may show rewarded or interstitial ads. The web version does not use this ads SDK. When ads are enabled and requested, Google and its advertising partners may receive information such as device identifiers, IP address, app/device information, ad interactions, and diagnostic data. They may use this information to provide, measure, limit, and personalize ads, subject to applicable law and any settings or consent choices available on your device or in the Game. We do not receive your advertising identifier directly through the Game.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "Google’s handling of information is described in Google’s Privacy Policy and How Google uses information from apps that use its services. You can manage ad personalization and reset or limit your advertising identifier in your device settings where available.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "Fonts and network requests",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "The Game uses the Google Fonts package. Depending on platform and font caching, font files may be requested from Google. Google may receive standard connection information, such as your IP address and request details. See Google’s Privacy Policy.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "How information is used and shared",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "Locally stored information is used to run the Game and remember your progress and preferences. We do not sell personal information. We do not operate a player account system or our own analytics backend. Google receives information when its advertising or font services are used, as described above. Information may also be disclosed if required by law or to protect rights, safety, and the integrity of the Game.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "Retention and your choices",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "Game progress and settings remain in local app storage until you clear the Game’s data or uninstall it. We do not have a copy of that local data to retrieve or delete. Where available, you can limit ad personalization through your device privacy settings or any consent choices offered in the Game. Some non-personalized or limited ads may still be served.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "Children’s privacy",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "The Game is not designed to collect personal information from children, and we do not knowingly collect personal information directly from children. The advertising SDK may process device information as described above. If you believe a child has provided personal information to us, contact us using the details below. If the Game is directed to children or is configured to serve ads to children, its store listing, SDK configuration, consent flow, and advertising settings must be updated to meet the applicable children’s privacy requirements.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "Security",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "We use reasonable measures appropriate to the Game’s limited data handling. No method of storage or transmission is completely secure. Because game progress is stored on your device, protect access to that device and its app data.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "Changes to this policy",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "We may update this policy when the Game or its data practices change. We will post the revised policy at this same address and update the “Last updated” date.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text("Contact", style: Theme.of(context).textTheme.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            "For privacy questions or requests, contact akhileshgulia72@gmail.com.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        SelectableText(privacyPolicyUrl),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open online policy'),
          onPressed: () async {
            var opened = false;
            try {
              opened = await launchUrl(
                Uri.parse(privacyPolicyUrl),
                mode: LaunchMode.externalApplication,
              );
            } catch (_) {}
            if (!opened && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Could not open the link. You can read the full policy above.',
                  ),
                ),
              );
            }
          },
        ),
      ],
    ),
  );
}
