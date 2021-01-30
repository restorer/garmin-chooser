using Toybox.Graphics;
using Toybox.WatchUi;

class RoundIconDrawable extends WatchUi.Drawable {
    var font = null;
    var icon = "";
    var borderWidth = 0;
    var backgroundColor = 0;
    var borderColor = 0;
    var iconColor = 0;
    var offsetCenterX = 0;
    var offsetCenterY = 0;
    var radius = 0;

    function initialize(settings) {
        Drawable.initialize(settings);

        font = (settings.hasKey(:font)? settings[:font] : null);
        icon = (settings.hasKey(:icon) ? settings[:icon] : "");
        borderWidth = (settings.hasKey(:borderWidth) ? settings[:borderWidth] : 0);
        backgroundColor = (settings.hasKey(:backgroundColor) ? settings[:backgroundColor] : Graphics.COLOR_TRANSPARENT);
        borderColor = (settings.hasKey(:borderColor) ? settings[:borderColor] : Graphics.COLOR_TRANSPARENT);
        iconColor = (settings.hasKey(:iconColor) ? settings[:iconColor] : Graphics.COLOR_TRANSPARENT);

        offsetCenterX = (width * 0.5).toNumber();
        offsetCenterY = (height * 0.5).toNumber();
        radius = ((width < height ? width : height) * 0.5 - 0.5).toNumber();
    }

    function draw(dc) {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        drawBackground(dc);

        if (font != null && iconColor != Graphics.COLOR_TRANSPARENT && icon != "") {
            dc.setColor(iconColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(locX + offsetCenterX, locY + offsetCenterY, font, icon, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function drawBackground(dc) {
        var centerX = locX + offsetCenterX;
        var centerY = locY + offsetCenterY;

        if (borderColor == Graphics.COLOR_TRANSPARENT || borderWidth < 1) {
            if (backgroundColor == Graphics.COLOR_TRANSPARENT) {
                return;
            }

            dc.setColor(backgroundColor, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(centerX, centerY, radius);
            return;
        }

        dc.setColor(borderColor, Graphics.COLOR_TRANSPARENT);

        if (backgroundColor == Graphics.COLOR_TRANSPARENT) {
            dc.setPenWidth(borderWidth);
            dc.drawCircle(centerX, centerY, radius - (borderWidth * 0.5).toNumber());
        } else {
            dc.fillCircle(centerX, centerY, radius);

            if (backgroundColor != borderColor) {
                dc.setColor(backgroundColor, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(centerX, centerY, radius - borderWidth);
            }
        }
    }
}

class FlatIconDrawable extends WatchUi.Drawable {
    var font = null;
    var icon = "";
    var backgroundColor = 0;
    var iconColor = 0;
    var offsetCenterX = 0;
    var offsetCenterY = 0;

    function initialize(settings) {
        Drawable.initialize(settings);

        font = (settings.hasKey(:font)? settings[:font] : null);
        icon = (settings.hasKey(:icon) ? settings[:icon] : "");
        backgroundColor = (settings.hasKey(:backgroundColor) ? settings[:backgroundColor] : Graphics.COLOR_TRANSPARENT);
        iconColor = (settings.hasKey(:iconColor) ? settings[:iconColor] : Graphics.COLOR_TRANSPARENT);

        offsetCenterX = (width * 0.5).toNumber();
        offsetCenterY = (height * 0.5).toNumber();
    }

    function draw(dc) {
        if (backgroundColor != Graphics.COLOR_TRANSPARENT) {
            dc.setColor(backgroundColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(locX, locY, width, height);
        }

        if (font != null && iconColor != Graphics.COLOR_TRANSPARENT && icon != "") {
            dc.setColor(iconColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(locX + offsetCenterX, locY + offsetCenterY, font, icon, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
