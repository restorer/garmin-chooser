using Toybox.WatchUi;

class ChooserViewProgressDelegate extends WatchUi.BehaviorDelegate {
    var ownerView = null;

    function initialize(ownerView) {
        BehaviorDelegate.initialize();
        self.ownerView = ownerView;
    }

    function onBack() {
        ownerView.isProgressShown = false;
        return true;
    }
}

class ChooserViewConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    var ownerView = null;
    var onYesMethod = null;

    function initialize(ownerView, onYesMethod) {
        ConfirmationDelegate.initialize();

        self.ownerView = ownerView;
        self.onYesMethod = onYesMethod;
    }

    function onResponse(response) {
        if (response == WatchUi.CONFIRM_YES) {
            ownerView.pendingMethod = onYesMethod;
        }
    }
}

class ChooserViewDelegate extends WatchUi.BehaviorDelegate {
    var ownerView = null;
    var progressThumbsUpText = "";
    var progressThumbsDownText = "";
    var confirmStartText = "";
    var confirmCancelText = "";

    function initialize(ownerView) {
        BehaviorDelegate.initialize();

        self.ownerView = ownerView;
        progressThumbsUpText = WatchUi.loadResource(Rez.Strings.ProgressThumbsUp);
        progressThumbsDownText = WatchUi.loadResource(Rez.Strings.ProgressThumbsDown);
        confirmStartText = WatchUi.loadResource(Rez.Strings.ConfirmStart);
        confirmCancelText = WatchUi.loadResource(Rez.Strings.ConfirmCancel);
    }

    function onMenu() {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new ChooserMenuDelegate(), WatchUi.SLIDE_LEFT);
        return true;
    }

    function onThumbsUp() {
        ownerView.isProgressShown = true;

        WatchUi.pushView(
            new WatchUi.ProgressBar(progressThumbsUpText, null),
            new ChooserViewProgressDelegate(ownerView),
            WatchUi.SLIDE_LEFT
        );

        return true;
    }

    function onThumbsDown() {
        ownerView.isProgressShown = true;

        WatchUi.pushView(
            new WatchUi.ProgressBar(progressThumbsDownText, null),
            new ChooserViewProgressDelegate(ownerView),
            WatchUi.SLIDE_LEFT
        );

        return true;
    }

    function onStartRound() {
        WatchUi.pushView(
            new WatchUi.Confirmation(confirmStartText),
            new ChooserViewConfirmationDelegate(ownerView, ownerView.method(:onStartRound)),
            WatchUi.SLIDE_LEFT
        );

        return true;
    }

    function onCancelRound() {
        WatchUi.pushView(
            new WatchUi.Confirmation(confirmCancelText),
            new ChooserViewConfirmationDelegate(ownerView, ownerView.method(:onCancelRound)),
            WatchUi.SLIDE_LEFT
        );

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

    const MID_BUTTON_BORDER_WIDTH = 4;

    var titleFont = Graphics.FONT_SMALL;
    var iconFont = null;
    var roundFormat = "";
    var progressStartingText = "";
    var progressCancellingText = "";

    var isProgressShown = false;
    var pendingMethod = null;

    function initialize() {
        View.initialize();

        iconFont = WatchUi.loadResource(Rez.Fonts.Icons);
        roundFormat = WatchUi.loadResource(Rez.Strings.Round);
        progressStartingText = WatchUi.loadResource(Rez.Strings.ProgressStarting);
        progressCancellingText = WatchUi.loadResource(Rez.Strings.ProgressCancelling);
    }

    function onLayout(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        setLayout(getChooseLayout(width, height, 42));
        // setLayout(getResultLayout(width, height, 42, :opThumbsDown, :myThumbsUp));
    }

    function onShow() {
    }

    function onUpdate(dc) {
        View.onUpdate(dc);

        if (pendingMethod != null) {
            var _method = pendingMethod;
            pendingMethod = null;
            _method.invoke();
        }
    }

    function onHide() {
    }

    // Handlers

    function onStartRound() {
        isProgressShown = true;

        WatchUi.pushView(
            new WatchUi.ProgressBar(progressStartingText, null),
            new ChooserViewProgressDelegate(self),
            WatchUi.SLIDE_RIGHT
        );
    }

    function onCancelRound() {
        isProgressShown = true;

        WatchUi.pushView(
            new WatchUi.ProgressBar(progressCancellingText, null),
            new ChooserViewProgressDelegate(self),
            WatchUi.SLIDE_RIGHT
        );
    }

    // Layouts

    function getSetupLayout(width, height) {
        return [];
    }

    function getChooseLayout(width, height, roundNum) {
        var midSize = (width < height ? height : height) * 0.25;
        var midHalfSize = midSize * 0.5;
        var midTopY = height * 0.5 - midHalfSize;
        var botHeight = height * 0.2;

        return [
            getRoundNumDrawable(width * 0.5, height * 0.1, roundNum),
            getMidButton(width * 0.3 - midHalfSize, midTopY, midSize, Graphics.COLOR_DK_RED, ICON_THUMBS_DOWN, :onThumbsDown),
            getMidButton(width * 0.7 - midHalfSize, midTopY, midSize, Graphics.COLOR_DK_GREEN, ICON_THUMBS_UP, :onThumbsUp),
            getBotButton(height - botHeight, width, botHeight, Graphics.COLOR_DK_RED, Graphics.COLOR_RED, ICON_DELETE, :onCancelRound),
        ];
    }

    function getResultLayout(width, height, roundNum, firstResult, secondResult) {
        var midSize = (width < height ? height : height) * 0.25;
        var midHalfSize = midSize * 0.5;
        var midCenterY = height * 0.5;
        var midTopY = midCenterY - midHalfSize;
        var botHeight = height * 0.2;
        var botTopY = height - botHeight;
        var isFinished = (firstResult != null && secondResult != null);

        var layout = [];

        if (isFinished) {
            var isSame = (firstResult == :myThumbsUp && secondResult == :opThumbsUp)
                || (firstResult == :opThumbsUp && secondResult == :myThumbsUp)
                || (firstResult == :myThumbsDown && secondResult == :opThumbsDown)
                || (firstResult == :opThumbsDown && secondResult == :myThumbsDown);

            layout.add(getTopIndicator(width, height * 0.2, isSame ? Graphics.COLOR_DK_GREEN : Graphics.COLOR_DK_RED));
        }

        layout.addAll([
            getRoundNumDrawable(width * 0.5, height * 0.1, roundNum),
            getMidResult(width * 0.3 - midHalfSize, midTopY, midSize, midHalfSize, firstResult),
            getMidResult(width * 0.7 - midHalfSize, midTopY, midSize, midHalfSize, secondResult),
            (isFinished
                ? getBotButton(botTopY, width, botHeight, Graphics.COLOR_DK_GREEN, Graphics.COLOR_GREEN, ICON_CHECKMARK, :onStartRound)
                : getBotButton(botTopY, width, botHeight, Graphics.COLOR_DK_RED, Graphics.COLOR_RED, ICON_DELETE, :onCancelRound)
            ),
        ]);

        return layout;
    }

    // Drawables

    function getRoundNumDrawable(x, y, roundNum) {
        return new WatchUi.Text({
            :locX => x,
            :locY => y,
            :text => Lang.format(roundFormat, [roundNum]),
            :font => titleFont,
            :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
        });
    }

    function getMidButton(x, y, size, color, icon, behavior) {
        return new WatchUi.Button({
            :behavior => behavior,
            :locX => x,
            :locY => y,
            :width => size,
            :height => size,
            :stateDefault => new RoundIconDrawable({
                :font => iconFont,
                :icon => icon,
                :width => size,
                :height => size,
                :borderWidth => MID_BUTTON_BORDER_WIDTH,
                :borderColor => color,
                :iconColor => Graphics.COLOR_WHITE,
            }),
            :stateHighlighted => new RoundIconDrawable({
                :font => iconFont,
                :icon => icon,
                :width => size,
                :height => size,
                :backgroundColor => color,
                :iconColor => Graphics.COLOR_WHITE,
            }),
        });
    }

    function getBotButton(y, width, height, defaultColor, highlightedColor, icon, behavior) {
        return new WatchUi.Button({
            :behavior => behavior,
            :locX => 0,
            :locY => y,
            :width => width,
            :height => height,
            :stateDefault => new FlatIconDrawable({
                :font => iconFont,
                :icon => icon,
                :width => width,
                :height => height,
                :backgroundColor => defaultColor,
                :iconColor => Graphics.COLOR_WHITE,
            }),
            :stateHighlighted => new FlatIconDrawable({
                :font => iconFont,
                :icon => icon,
                :width => width,
                :height => height,
                :backgroundColor => highlightedColor,
                :iconColor => Graphics.COLOR_WHITE,
            }),
        });
    }

    function getTopIndicator(width, height, color) {
        return new BoxDrawable({
            :locX => 0,
            :locY => 0,
            :width => width,
            :height => height,
            :color => color,
        });
    }

    function getMidResult(x, y, size, halfSize, result) {
        if (result == :myThumbsUp) {
            return new RoundIconDrawable({
                :font => iconFont,
                :icon => ICON_THUMBS_UP,
                :locX => x,
                :locY => y,
                :width => size,
                :height => size,
                :backgroundColor => Graphics.COLOR_DK_GREEN,
                :iconColor => Graphics.COLOR_WHITE,
            });
        }

        if (result == :myThumbsDown) {
            return new RoundIconDrawable({
                :font => iconFont,
                :icon => ICON_THUMBS_DOWN,
                :locX => x,
                :locY => y,
                :width => size,
                :height => size,
                :backgroundColor => Graphics.COLOR_DK_RED,
                :iconColor => Graphics.COLOR_WHITE,
            });
        }

        if (result == :opThumbsUp) {
            return new WatchUi.Text({
                :locX => x + halfSize,
                :locY => y + halfSize,
                :text => ICON_THUMBS_UP,
                :font => iconFont,
                :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            });
        }

        if (result == :opThumbsDown) {
            return new WatchUi.Text({
                :locX => x + halfSize,
                :locY => y + halfSize,
                :text => ICON_THUMBS_DOWN,
                :font => iconFont,
                :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            });
        }

        return new WatchUi.Text({
            :locX => x + halfSize,
            :locY => y + halfSize,
            :text => "...",
            :font => titleFont,
            :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
        });
    }
}
