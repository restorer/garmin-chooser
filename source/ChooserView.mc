using Toybox.WatchUi;

class ChooserViewDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new ChooserMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
}

class CustomDrawable extends WatchUi.Drawable {
    function initialize() {
        Drawable.initialize({});
        setSize(50, 50);
    }

    function draw(dc) {
        dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_DK_BLUE);
        dc.fillRectangle(locX, locY, width, height);
    }
}

class ChooserView extends WatchUi.View {
    const ICON_THUMBS_UP = "0";
    const ICON_THUMBS_DOWN = "1";
    const ICON_CHECKMARK = "2";
    const ICON_DELETE = "3";

    var titleFont = Graphics.FONT_SMALL;
    var iconFont = null;
    var roundFormat = "";

    function initialize() {
        View.initialize();
        iconFont = WatchUi.loadResource(Rez.Fonts.Icons);
        roundFormat = WatchUi.loadResource(Rez.Strings.Round);
    }

    function onLayout(dc) {
        var dcWidth = dc.getWidth();
        var dcHeight = dc.getHeight();
        var buttonSize = (dcWidth < dcHeight ? dcWidth : dcHeight) * 0.25;

        setLayout([
            new WatchUi.Text({
                :locX => dcWidth * 0.5,
                :locY => dcHeight * 0.15,
                :text => Lang.format(roundFormat, [999]),
                :font => titleFont,
                :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            }),
            new WatchUi.Button({
                :locX => dcWidth * 0.3 - buttonSize * 0.5,
                :locY => dcHeight * 0.515625 - buttonSize * 0.5,
                :width => buttonSize,
                :height => buttonSize,
                :stateDefault => new RoundIconDrawable({
                    :font => iconFont,
                    :icon => ICON_THUMBS_DOWN,
                    :width => buttonSize,
                    :height => buttonSize,
                    :borderWidth => 4,
                    :borderColor => Graphics.COLOR_DK_RED,
                    :iconColor => Graphics.COLOR_WHITE,
                }),
                :stateHighlighted => new RoundIconDrawable({
                    :font => iconFont,
                    :icon => ICON_THUMBS_DOWN,
                    :width => buttonSize,
                    :height => buttonSize,
                    :backgroundColor => Graphics.COLOR_DK_RED,
                    :iconColor => Graphics.COLOR_WHITE,
                }),
            }),
            new WatchUi.Button({
                :locX => dcWidth * 0.7 - buttonSize * 0.5,
                :locY => dcHeight * 0.515625 - buttonSize * 0.5,
                :width => buttonSize,
                :height => buttonSize,
                :stateDefault => new RoundIconDrawable({
                    :font => iconFont,
                    :icon => ICON_THUMBS_UP,
                    :width => buttonSize,
                    :height => buttonSize,
                    :borderWidth => 4,
                    :borderColor => Graphics.COLOR_DK_GREEN,
                    :iconColor => Graphics.COLOR_WHITE,
                }),
                :stateHighlighted => new RoundIconDrawable({
                    :font => iconFont,
                    :icon => ICON_THUMBS_UP,
                    :width => buttonSize,
                    :height => buttonSize,
                    :backgroundColor => Graphics.COLOR_DK_GREEN,
                    :iconColor => Graphics.COLOR_WHITE,
                }),
            }),
            new WatchUi.Button({
                :locX => 0,
                :locY => dcHeight * 0.8,
                :width => dcWidth,
                :height => dcHeight * 0.2,
                :stateDefault => new FlatIconDrawable({
                    :font => iconFont,
                    :icon => ICON_DELETE,
                    :width => dcWidth,
                    :height => dcHeight * 0.2,
                    :backgroundColor => Graphics.COLOR_DK_RED,
                    :iconColor => Graphics.COLOR_WHITE,
                }),
                :stateHighlighted => new FlatIconDrawable({
                    :font => iconFont,
                    :icon => ICON_DELETE,
                    :width => dcWidth,
                    :height => dcHeight * 0.2,
                    :backgroundColor => Graphics.COLOR_RED,
                    :iconColor => Graphics.COLOR_WHITE,
                }),
            }),
        ]);
    }

    function onShow() {
    }

    function onUpdate(dc) {
        View.onUpdate(dc);
    }

    function onHide() {
    }
}
