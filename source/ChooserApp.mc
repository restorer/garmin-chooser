using Toybox.Application;
using Toybox.WatchUi;

class ChooserApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        return [new ChooserView(), new ChooserViewDelegate()];
    }
}
