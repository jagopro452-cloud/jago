import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_pilot_app/features/call/controllers/call_controller.dart';
import 'package:jago_pilot_app/util/dimensions.dart';
import 'package:jago_pilot_app/util/styles.dart';

class CallOverlayWidget extends StatelessWidget {
  const CallOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CallController>(builder: (callController) {
      if (callController.callState == CallState.idle) {
        return const SizedBox.shrink();
      }

      if (callController.isIncoming && callController.callState == CallState.ringing) {
        return _IncomingCallOverlay(callController: callController);
      }

      return _ActiveCallOverlay(callController: callController);
    });
  }
}

class _IncomingCallOverlay extends StatelessWidget {
  final CallController callController;
  const _IncomingCallOverlay({required this.callController});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColorDark,
                  ],
                ),
              ),
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            Text(
              callController.callerDisplayName ?? 'incoming_call'.tr,
              style: textBold.copyWith(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Text(
              'incoming_call'.tr,
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Colors.white70,
              ),
            ),

            const Spacer(flex: 3),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallActionButton(
                  icon: Icons.call_end,
                  label: 'decline'.tr,
                  color: Colors.red,
                  onPressed: () => callController.rejectIncomingCall(),
                ),
                _CallActionButton(
                  icon: Icons.call,
                  label: 'accept'.tr,
                  color: Colors.green,
                  onPressed: () => callController.acceptIncomingCall(),
                ),
              ],
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _ActiveCallOverlay extends StatelessWidget {
  final CallController callController;
  const _ActiveCallOverlay({required this.callController});

  @override
  Widget build(BuildContext context) {
    final isConnecting = callController.callState == CallState.connecting;
    final isRinging = callController.callState == CallState.ringing;
    final isEnded = callController.callState == CallState.ended;
    final isError = callController.callState == CallState.error;

    String statusText;
    if (isConnecting) {
      statusText = 'connecting'.tr;
    } else if (isRinging) {
      statusText = 'ringing'.tr;
    } else if (isEnded) {
      statusText = 'call_ended'.tr;
    } else if (isError) {
      statusText = 'call_failed'.tr;
    } else {
      statusText = callController.formattedDuration;
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E3A8A),
              const Color(0xFF2563EB).withValues(alpha: 0.95),
              const Color(0xFF1D4ED8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.person, size: 55, color: Colors.white),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              Text(
                callController.calleeDisplayName ?? 'Unknown',
                style: textBold.copyWith(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  statusText,
                  key: ValueKey(statusText),
                  style: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Colors.white70,
                  ),
                ),
              ),

              if (isConnecting || isRinging) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],

              const Spacer(flex: 3),

              if (callController.callState == CallState.active)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CallActionButton(
                      icon: callController.isMuted ? Icons.mic_off : Icons.mic,
                      label: callController.isMuted ? 'unmute'.tr : 'mute'.tr,
                      color: callController.isMuted ? Colors.red.shade400 : Colors.white.withValues(alpha: 0.2),
                      iconColor: Colors.white,
                      onPressed: () => callController.toggleMute(),
                    ),
                    _CallActionButton(
                      icon: Icons.call_end,
                      label: 'end_call'.tr,
                      color: Colors.red,
                      onPressed: () => callController.hangUp(),
                      size: 70,
                    ),
                    _CallActionButton(
                      icon: callController.isSpeaker ? Icons.volume_up : Icons.volume_down,
                      label: 'speaker'.tr,
                      color: callController.isSpeaker ? const Color(0xFF93C5FD) : Colors.white.withValues(alpha: 0.2),
                      iconColor: Colors.white,
                      onPressed: () => callController.toggleSpeaker(),
                    ),
                  ],
                )
              else if (!isEnded && !isError)
                _CallActionButton(
                  icon: Icons.call_end,
                  label: 'cancel'.tr,
                  color: Colors.red,
                  onPressed: () => callController.hangUp(),
                  size: 70,
                ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onPressed;
  final double size;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.iconColor = Colors.white,
    required this.onPressed,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: size * 0.45),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: textRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
