import 'package:flutter/material.dart';

class FlutterFlowIconButton extends StatefulWidget {
  const FlutterFlowIconButton({
    super.key,
    required this.icon,
    this.borderColor,
    this.borderRadius,
    this.borderWidth = 1.0,
    this.buttonSize = 48.0,
    this.fillColor,
    this.disabledColor,
    this.disabledIconColor,
    this.hoverColor,
    this.hoverIconColor,
    this.onPressed,
    this.showLoadingIndicator = false,
  });

  final Widget icon;
  final Color? borderColor;
  final double? borderRadius;
  final double borderWidth;
  final double buttonSize;
  final Color? fillColor;
  final Color? disabledColor;
  final Color? disabledIconColor;
  final Color? hoverColor;
  final Color? hoverIconColor;
  final VoidCallback? onPressed;
  final bool showLoadingIndicator;

  @override
  State<FlutterFlowIconButton> createState() => _FlutterFlowIconButtonState();
}

class _FlutterFlowIconButtonState extends State<FlutterFlowIconButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.buttonSize,
      height: widget.buttonSize,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: widget.onPressed != null
                ? widget.fillColor
                : widget.disabledColor ?? widget.fillColor?.withOpacity(0.5),
            borderRadius: widget.borderRadius != null
                ? BorderRadius.circular(widget.borderRadius!)
                : null,
            border: widget.borderColor != null
                ? Border.all(
                    color: widget.borderColor!,
                    width: widget.borderWidth,
                  )
                : null,
          ),
          child: InkWell(
            borderRadius: widget.borderRadius != null
                ? BorderRadius.circular(widget.borderRadius!)
                : null,
            hoverColor: widget.hoverColor,
            onTap: widget.onPressed == null
                ? null
                : () async {
                    if (widget.showLoadingIndicator) {
                      setState(() => _loading = true);
                    }
                    try {
                      widget.onPressed!();
                    } finally {
                      if (widget.showLoadingIndicator && mounted) {
                        setState(() => _loading = false);
                      }
                    }
                  },
            child: Center(
              child: _loading
                  ? SizedBox(
                      width: widget.buttonSize / 2,
                      height: widget.buttonSize / 2,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                      ),
                    )
                  : IconTheme(
                      data: IconThemeData(
                        color: widget.onPressed != null
                            ? null
                            : widget.disabledIconColor,
                      ),
                      child: widget.icon,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
