using Toybox.WatchUi;
using Toybox.Timer;
using Toybox.Time;
using Toybox.Communications;

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
        WatchUi.pushView(new ChooserMenu(), new ChooserMenuDelegate(), WatchUi.SLIDE_LEFT);
        return true;
    }

    function onRefresh() {
        ownerView.onRefresh();
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

class ChooserView extends WatchUi.View {
    const ENDPOINT = "https://eightsines.com/garmin-chooser/index.php";

    const METHOD_SYNC = "sync";
    const METHOD_START = "start";
    const METHOD_CANCEL = "cancel";
    const METHOD_UP = "up";
    const METHOD_DOWN = "down";

    const RESP_STATUS = "status";
    const RESP_DATA = "data";
    const RESP_ERROR = "error";
    const RESP_DATA_ID = "id";
    const RESP_DATA_MY = "my";
    const RESP_DATA_OP = "op";
    const RESP_THUMBS_UP = 1;
    const RESP_THUMBS_DOWN = 2;

    const STATUS_OK = "ok";
    const STATUS_ERROR = "error";

    const ERROR_UNREGISTERED = "UNREGISTERED";

    const ICON_THUMBS_UP = "0";
    const ICON_THUMBS_DOWN = "1";
    const ICON_CHECKMARK = "2";
    const ICON_DELETE = "3";
    const ICON_REFRESH = "4";

    const COLOR_FOREGROUND = 0xFFFFFF;
    const COLOR_PROGRESS = 0x00AAAA;
    const COLOR_THUMBS_UP = 0x00AA00;
    const COLOR_THUMBS_DOWN = 0xAA0000;
    const COLOR_REFRESH = 0x555555;
    const COLOR_BOT_DEFAULT = 0x0000AA;
    const COLOR_BOT_HIGHLIGHTED = 0x0000FF;
    const COLOR_NOT_SAME = 0xAA00AA;

    const MID_BUTTON_BORDER_WIDTH = 4;
    const PROGRESS_LINE_WIDTH = 5;
    const PROGRESS_UPDATE_DURATION = 50;

    var tinyFont = Graphics.FONT_XTINY;
    var smallFont = Graphics.FONT_SMALL;
    var iconFont = null;
    var titleText = "";
    var roundFormat = "";
    var refreshingText = "";
    var startingText = "";
    var cancellingText = "";
    var errorText = "";
    var progressTimer = null;

    var lastLayout = null;
    var pendingMethod = null;
    var isProgressStarted = false;
    var isProgressTimerStarted = false;
    var progressDt = 0;

    var uid = "";
    var lastRoundId = 0;

    var dcWidth = 0;
    var dcHeight = 0;
    var dcSize = 0;
    var dcCenterX = 0;
    var dcCenterY = 0;
    var progressRadius = 0;

    function initialize() {
        View.initialize();

        iconFont = WatchUi.loadResource(Rez.Fonts.Icons);
        titleText = WatchUi.loadResource(Rez.Strings.AppName);
        roundFormat = WatchUi.loadResource(Rez.Strings.Round);
        refreshingText = WatchUi.loadResource(Rez.Strings.Refreshing);
        startingText = WatchUi.loadResource(Rez.Strings.Starting);
        cancellingText = WatchUi.loadResource(Rez.Strings.Cancelling);
        errorText = WatchUi.loadResource(Rez.Strings.Error);
        progressTimer = new Timer.Timer();

        uid = System.getDeviceSettings().uniqueIdentifier;

        if (uid == null) {
            uid = "0000-0000";
        } else {
            if (uid.length() >= 8) {
                uid = uid.substring(0, 4) + "-" + uid.substring(4, 8);
            }

            uid = uid.toUpper();
        }
    }

    function onLayout(dc) {
        dcWidth = dc.getWidth();
        dcHeight = dc.getHeight();
        dcSize = (dcWidth < dcHeight ? dcWidth : dcHeight);
        dcCenterX = (dcWidth * 0.5).toNumber();
        dcCenterY = (dcHeight * 0.5).toNumber();
        progressRadius = ((dcSize - PROGRESS_LINE_WIDTH) * 0.5).toNumber();

        changeLayout([:getRefreshLayout, refreshingText]);
        onRefresh();
    }

    function onShow() {
        if (isProgressStarted && !isProgressTimerStarted) {
            isProgressTimerStarted = true;
            progressTimer.start(method(:onProgressTimer), PROGRESS_UPDATE_DURATION, true);
        }
    }

    function onUpdate(dc) {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        View.onUpdate(dc);

        if (pendingMethod != null) {
            var _method = pendingMethod;
            pendingMethod = null;
            _method.invoke();
        }

        if (isProgressStarted) {
            drawProgress(dc);
        }
    }

    function onHide() {
        if (isProgressStarted && isProgressTimerStarted) {
            progressTimer.stop();
            isProgressTimerStarted = false;
        }
    }

    // Handlers

    function onProgressTimer() {
        progressDt += PROGRESS_UPDATE_DURATION;
        WatchUi.requestUpdate();
    }

    function onRefresh() {
        startProgress();
        changeLayout(lastLayout);
        makeRequest(METHOD_SYNC);
    }

    function onThumbsUp() {
        startProgress();
        changeLayout([:getResultLayout, lastRoundId, null, :myThumbsUp]);
        makeRequest(METHOD_UP);
    }

    function onThumbsDown() {
        startProgress();
        changeLayout([:getResultLayout, lastRoundId, :myThumbsDown, null]);
        makeRequest(METHOD_DOWN);
    }

    function onStartRound() {
        startProgress();
        changeLayout([:getRefreshLayout, startingText]);
        makeRequest(METHOD_START);
    }

    function onCancelRound() {
        startProgress();
        changeLayout([:getRefreshLayout, cancellingText]);
        makeRequest(METHOD_CANCEL);
    }

    // Request

    function makeRequest(method) {
        Communications.makeWebRequest(
            ENDPOINT,
            {
                "method" => method,
                "uid" => uid,
            },
            {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            },
            method(:onReceiveResponse)
        );
    }

    function onReceiveResponse(responseCode, data) {
        // System.println("responseCode = " + responseCode + ", data = " + data);
        stopProgress();

        if (data == null) {
            changeLayout([:getErrorLayout, "<NULL>\n" + responseCode]);
            return;
        }

        if (!(data instanceof Dictionary)) {
            changeLayout([:getErrorLayout, "<NOT_A_DICTIONARY>\n" + data]);
            return;
        }

        if (!data.hasKey(RESP_STATUS)) {
            changeLayout([:getErrorLayout, "<HAS_NO_STATUS>\n" + data]);
            return;
        }

        var status = data[RESP_STATUS];

        if (STATUS_ERROR.equals(status)) {
            if (!data.hasKey(RESP_ERROR)) {
                changeLayout([:getErrorLayout, "<HAS_NO_ERROR>\n" + data]);
                return;
            }

            var error = data[RESP_ERROR];

            if (error == null) {
                changeLayout([:getErrorLayout, "<NULL_ERROR>\n" + data]);
            }

            if (ERROR_UNREGISTERED.equals(error)) {
                changeLayout([:getSetupLayout]);
                return;
            }

            changeLayout([:getErrorLayout, error.toString()]);
            return;
        }

        if (!STATUS_OK.equals(status)) {
            changeLayout([:getErrorLayout, "<UNKNOWN_STATUS>\n" + data]);
            return;
        }

        if (!data.hasKey(RESP_DATA)) {
            changeLayout([:getErrorLayout, "<HAS_NO_DATA>\n" + data]);
            return;
        }

        var respData = data[RESP_DATA];

        if (!(respData instanceof Dictionary)) {
            changeLayout([:getErrorLayout, "<DATA_NOT_A_DICTIONARY>\n" + respData]);
            return;
        }

        if (!respData.hasKey(RESP_DATA_ID)) {
            changeLayout([:getErrorLayout, "<DATA_HAS_NO_ID>\n" + respData]);
            return;
        }

        var respId = respData[RESP_DATA_ID];

        if (!(respId instanceof Number)) {
            changeLayout([:getErrorLayout, "<DATA_ID_NOT_A_NUMBER>\n" + respData]);
            return;
        }

        lastRoundId = respId;

        if (!respData.hasKey(RESP_DATA_MY)) {
            changeLayout([:getErrorLayout, "<DATA_HAS_NO_MY>\n" + respData]);
            return;
        }

        var respMy = respData["my"];

        if (!(respMy instanceof Number)) {
            changeLayout([:getErrorLayout, "<DATA_MY_NOT_A_NUMBER>\n" + respData]);
            return;
        }

        if (respMy != RESP_THUMBS_UP && respMy != RESP_THUMBS_DOWN) {
            changeLayout([:getChooseLayout, respId]);
            return;
        }

        if (!respData.hasKey(RESP_DATA_OP)) {
            changeLayout([:getErrorLayout, "<DATA_HAS_NO_OP>\n" + respData]);
            return;
        }

        var respOp = respData["op"];

        if (!(respOp instanceof Number)) {
            changeLayout([:getErrorLayout, "<DATA_OP_NOT_A_NUMBER>\n" + respData]);
            return;
        }

        var opResult = (respOp == RESP_THUMBS_UP ? :opThumbsUp : (respOp == RESP_THUMBS_DOWN ? :opThumbsDown : null));

        if (respMy == RESP_THUMBS_UP) {
            changeLayout([:getResultLayout, respId, opResult, :myThumbsUp]);
        } else {
            changeLayout([:getResultLayout, respId, :myThumbsDown, opResult]);
        }
    }

    // Progress

    function startProgress() {
        isProgressStarted = true;

        if (!isProgressTimerStarted) {
            isProgressTimerStarted = true;
            progressTimer.start(method(:onProgressTimer), PROGRESS_UPDATE_DURATION, true);
        }
    }

    function stopProgress() {
        isProgressStarted = false;

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

        dc.setColor(COLOR_PROGRESS, Graphics.COLOR_TRANSPARENT);
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

    function getRefreshLayout(opts) {
        var text = opts[0];

        return [
            getTextDrawable(dcCenterX, dcCenterY, text),
        ];
    }

    function getSetupLayout(opts) {
        var botHeight = dcHeight * 0.2;
        var botTopY = dcHeight - botHeight;

        var layout = [
            getTextDrawable(dcCenterX, dcHeight * 0.4, titleText),
            getTextDrawable(dcCenterX, dcHeight * 0.6, uid),
        ];

        if (!isProgressStarted) {
            layout.add(getBotButton(botTopY, dcWidth, botHeight, COLOR_BOT_DEFAULT, COLOR_BOT_HIGHLIGHTED, ICON_REFRESH, :onRefresh));
        }

        return layout;
    }

    function getErrorLayout(opts) {
        var errorMessageText = opts[0];

        var botHeight = dcHeight * 0.2;
        var botTopY = dcHeight - botHeight;

        var layout = [
            getTextDrawable(dcCenterX, dcHeight * 0.4, errorText),
            getTinyTextDrawable(dcCenterX, dcHeight * 0.6, errorMessageText),
        ];

        if (!isProgressStarted) {
            layout.add(getBotButton(botTopY, dcWidth, botHeight, COLOR_BOT_DEFAULT, COLOR_BOT_HIGHLIGHTED, ICON_REFRESH, :onRefresh));
        }

        return layout;
    }

    function getChooseLayout(opts) {
        var roundNum = opts[0];

        var midSize = dcSize * 0.25;
        var midHalfSize = midSize * 0.5;
        var midTopY = dcCenterY - midHalfSize;
        var botHeight = dcHeight * 0.2;

        return [
            getRoundNumDrawable(dcCenterX, dcHeight * 0.1, roundNum),
            getMidButton(dcWidth * 0.3 - midHalfSize, midTopY, midSize, COLOR_THUMBS_DOWN, ICON_THUMBS_DOWN, :onThumbsDown),
            getMidButton(dcWidth * 0.7 - midHalfSize, midTopY, midSize, COLOR_THUMBS_UP, ICON_THUMBS_UP, :onThumbsUp),
        ];
    }

    function getResultLayout(opts) {
        var roundNum = opts[0];
        var firstResult = opts[1];
        var secondResult = opts[2];

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

            layout.add(getTopIndicator(
                dcWidth,
                dcHeight * 0.2,
                (isSame
                    ? ((firstResult == :myThumbsUp || secondResult == :myThumbsUp) ? COLOR_THUMBS_UP : COLOR_THUMBS_DOWN)
                    : COLOR_NOT_SAME
                )
            ));
        }

        layout.addAll([
            getRoundNumDrawable(dcCenterX, dcHeight * 0.1, roundNum),
            getMidResult(dcWidth * 0.3 - midHalfSize, midTopY, midSize, midHalfSize, firstResult),
            getMidResult(dcWidth * 0.7 - midHalfSize, midTopY, midSize, midHalfSize, secondResult),
        ]);

        if (!isProgressStarted) {
            layout.add(isFinished
                ? getBotButton(botTopY, dcWidth, botHeight, COLOR_BOT_DEFAULT, COLOR_BOT_HIGHLIGHTED, ICON_CHECKMARK, :onStartRound)
                : getBotButton(botTopY, dcWidth, botHeight, COLOR_BOT_DEFAULT, COLOR_BOT_HIGHLIGHTED, ICON_DELETE, :onCancelRound)
            );
        }

        return layout;
    }

    // Drawables

    function getTextDrawable(x, y, text) {
        return new WatchUi.Text({
            :locX => x.toNumber(),
            :locY => y.toNumber(),
            :text => text,
            :font => smallFont,
            :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
        });
    }

    function getTinyTextDrawable(x, y, text) {
        return new WatchUi.Text({
            :locX => x.toNumber(),
            :locY => y.toNumber(),
            :text => text,
            :font => tinyFont,
            :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
        });
    }

    function getRoundNumDrawable(x, y, roundNum) {
        return getTextDrawable(x, y, Lang.format(roundFormat, [roundNum]));
    }

    function getMidButton(x, y, size, color, icon, behavior) {
        size = size.toNumber();

        return new WatchUi.Button({
            :behavior => behavior,
            :locX => x.toNumber(),
            :locY => y.toNumber(),
            :width => size,
            :height => size,
            :stateDefault => new RoundIconDrawable({
                :font => iconFont,
                :icon => icon,
                :width => size,
                :height => size,
                :borderWidth => MID_BUTTON_BORDER_WIDTH,
                :borderColor => color,
                :iconColor => COLOR_FOREGROUND,
            }),
            :stateHighlighted => new RoundIconDrawable({
                :font => iconFont,
                :icon => icon,
                :width => size,
                :height => size,
                :backgroundColor => color,
                :iconColor => COLOR_FOREGROUND,
            }),
        });
    }

    function getBotButton(y, width, height, defaultColor, highlightedColor, icon, behavior) {
        width = width.toNumber();
        height = height.toNumber();

        return new WatchUi.Button({
            :behavior => behavior,
            :locX => 0,
            :locY => y.toNumber(),
            :width => width,
            :height => height,
            :stateDefault => new FlatIconDrawable({
                :font => iconFont,
                :icon => icon,
                :width => width,
                :height => height,
                :backgroundColor => defaultColor,
                :iconColor => COLOR_FOREGROUND,
            }),
            :stateHighlighted => new FlatIconDrawable({
                :font => iconFont,
                :icon => icon,
                :width => width,
                :height => height,
                :backgroundColor => highlightedColor,
                :iconColor => COLOR_FOREGROUND,
            }),
        });
    }

    function getTopIndicator(width, height, color) {
        return new BoxDrawable({
            :locX => 0,
            :locY => 0,
            :width => width.toNumber(),
            :height => height.toNumber(),
            :color => color,
        });
    }

    function getMidResult(x, y, size, halfSize, result) {
        x = x.toNumber();
        y = y.toNumber();
        size = size.toNumber();
        halfSize = halfSize.toNumber();

        if (result == :myThumbsUp) {
            return new RoundIconDrawable({
                :font => iconFont,
                :icon => ICON_THUMBS_UP,
                :locX => x,
                :locY => y,
                :width => size,
                :height => size,
                :backgroundColor => COLOR_THUMBS_UP,
                :iconColor => COLOR_FOREGROUND,
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
                :iconColor => COLOR_FOREGROUND,
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

        if (isProgressStarted) {
            return new WatchUi.Text({
                :locX => x + halfSize,
                :locY => y + halfSize,
                :text => ICON_REFRESH,
                :font => iconFont,
                :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            });
        }

        return getMidButton(x, y, size, COLOR_REFRESH, ICON_REFRESH, :onRefresh);
    }

    // Utils

    function changeLayout(spec) {
        lastLayout = spec;
        setLayout(method(spec[0]).invoke(spec.slice(1, null)));
        WatchUi.requestUpdate();
    }
}
