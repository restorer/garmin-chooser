using Toybox.WatchUi;
using Toybox.Timer;
using Toybox.Time;

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
    var confirmStartText = "";
    var confirmCancelText = "";

    function initialize(ownerView) {
        BehaviorDelegate.initialize();

        self.ownerView = ownerView;
        confirmStartText = WatchUi.loadResource(Rez.Strings.ConfirmStart);
        confirmCancelText = WatchUi.loadResource(Rez.Strings.ConfirmCancel);
    }

    function onMenu() {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new ChooserMenuDelegate(), WatchUi.SLIDE_LEFT);
        return true;
    }

    function onThumbsUp() {
        ownerView.onThumbsUp();
        return true;
    }

    function onThumbsDown() {
        ownerView.onThumbsDown();
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
    const COLOR_THUMBS_UP = Graphics.COLOR_YELLOW;
    const COLOR_THUMBS_DOWN = Graphics.COLOR_DK_BLUE;

    const PROGRESS_LINE_WIDTH = 5;
    const PROGRESS_UPDATE_DURATION = 50;

    var titleFont = Graphics.FONT_SMALL;
    var iconFont = null;
    var roundFormat = "";
    var startingText = "";
    var cancellingText = "";
    var progressTimer = null;

    var pendingMethod = null;
    var isProgressShown = false;
    var isProgressTimerStarted = false;
    var progressDt = 0;

    var dcWidth = 0;
    var dcHeight = 0;
    var dcSize = 0;
    var dcCenterX = 0;
    var dcCenterY = 0;
    var progressRadius = 0;

    function initialize() {
        View.initialize();

        iconFont = WatchUi.loadResource(Rez.Fonts.Icons);
        roundFormat = WatchUi.loadResource(Rez.Strings.Round);
        startingText = WatchUi.loadResource(Rez.Strings.Starting);
        cancellingText = WatchUi.loadResource(Rez.Strings.Cancelling);
        progressTimer = new Timer.Timer();
    }

    function onLayout(dc) {
        dcWidth = dc.getWidth();
        dcHeight = dc.getHeight();
        dcSize = (dcWidth < dcHeight ? dcWidth : dcHeight);
        dcCenterX = (dcWidth * 0.5).toNumber();
        dcCenterY = (dcHeight * 0.5).toNumber();
        progressRadius = ((dcSize - PROGRESS_LINE_WIDTH) * 0.5).toNumber();

        setLayout(getChooseLayout(42));
        //
    }

    function onShow() {
        if (isProgressShown && !isProgressTimerStarted) {
            isProgressTimerStarted = true;
            progressTimer.start(method(:onProgressTimer), PROGRESS_UPDATE_DURATION, true);
        }
    }

    function onUpdate(dc) {
        View.onUpdate(dc);

        if (pendingMethod != null) {
            var _method = pendingMethod;
            pendingMethod = null;
            _method.invoke();
        }

        if (isProgressShown) {
            drawProgress(dc);
        }
    }

    function onHide() {
        if (isProgressShown && isProgressTimerStarted) {
            progressTimer.stop();
            isProgressTimerStarted = false;
        }
    }

    // Handlers

    function onProgressTimer() {
        progressDt += PROGRESS_UPDATE_DURATION;
        WatchUi.requestUpdate();
    }

    function onThumbsUp() {
        showProgress();
        setLayout(getResultLayout(42, null, :myThumbsUp));
    }

    function onThumbsDown() {
        showProgress();
        setLayout(getResultLayout(42, :myThumbsDown, null));
    }

    function onStartRound() {
        // TODO
    }

    function onCancelRound() {
        // TODO
    }

    // Progress

    function showProgress() {
        isProgressShown = true;

        if (!isProgressTimerStarted) {
            isProgressTimerStarted = true;
            progressTimer.start(method(:onProgressTimer), PROGRESS_UPDATE_DURATION, true);
        }
    }

    function hideProgress() {
        isProgressShown = false;

        if (isProgressTimerStarted) {
            progressTimer.stop();
            isProgressTimerStarted = false;
        }
    }

    function drawProgress(dc) {
        var sa = 360 - ((progressDt / 1000).toNumber() % 24) * 15;
        var da = ((progressDt % 1000) * 18 / 100).toNumber() + 1;

        if (progressDt % 2000 >= 1000) {
            da = 180 - da;
        }

        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(PROGRESS_LINE_WIDTH);

        dc.drawArc(
            dcCenterX,
            dcCenterY,
            progressRadius,
            Graphics.ARC_COUNTER_CLOCKWISE,
            sa - da,
            sa + da
        );
    }

    // Layouts

    function getSetupLayout() {
        return [];
    }

    function getChooseLayout(roundNum) {
        var midSize = dcSize * 0.25;
        var midHalfSize = midSize * 0.5;
        var midTopY = dcCenterY - midHalfSize;
        var botHeight = dcHeight * 0.2;

        return [
            getRoundNumDrawable(dcCenterX, dcHeight * 0.1, roundNum),
            getMidButton(dcWidth * 0.3 - midHalfSize, midTopY, midSize, COLOR_THUMBS_DOWN, ICON_THUMBS_DOWN, :onThumbsDown),
            getMidButton(dcWidth * 0.7 - midHalfSize, midTopY, midSize, COLOR_THUMBS_UP, ICON_THUMBS_UP, :onThumbsUp),
            getBotButton(dcHeight - botHeight, dcWidth, botHeight, Graphics.COLOR_DK_RED, Graphics.COLOR_RED, ICON_DELETE, :onCancelRound),
        ];
    }

    function getResultLayout(roundNum, firstResult, secondResult) {
        var midSize = dcSize * 0.25;
        var midHalfSize = midSize * 0.5;
        var midTopY = dcCenterY - midHalfSize;
        var botHeight = dcHeight * 0.2;
        var botTopY = dcHeight - botHeight;
        var isFinished = (firstResult != null && secondResult != null);

        var layout = [];

        if (isFinished) {
            var isSame = (firstResult == :myThumbsUp && secondResult == :opThumbsUp)
                || (firstResult == :opThumbsUp && secondResult == :myThumbsUp)
                || (firstResult == :myThumbsDown && secondResult == :opThumbsDown)
                || (firstResult == :opThumbsDown && secondResult == :myThumbsDown);

            layout.add(getTopIndicator(dcWidth, dcHeight * 0.2, isSame ? Graphics.COLOR_DK_GREEN : Graphics.COLOR_DK_RED));
        }

        layout.addAll([
            getRoundNumDrawable(dcCenterX, dcHeight * 0.1, roundNum),
            getMidResult(dcWidth * 0.3 - midHalfSize, midTopY, midSize, midHalfSize, firstResult),
            getMidResult(dcWidth * 0.7 - midHalfSize, midTopY, midSize, midHalfSize, secondResult),
        ]);

        if (!isProgressShown) {
            layout.add(isFinished
                ? getBotButton(botTopY, dcWidth, botHeight, Graphics.COLOR_DK_GREEN, Graphics.COLOR_GREEN, ICON_CHECKMARK, :onStartRound)
                : getBotButton(botTopY, dcWidth, botHeight, Graphics.COLOR_DK_RED, Graphics.COLOR_RED, ICON_DELETE, :onCancelRound)
            );
        }

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
                :backgroundColor => COLOR_THUMBS_UP,
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
                :backgroundColor => COLOR_THUMBS_DOWN,
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
