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
        var view = new ChooserView();
        return [view, new ChooserViewDelegate(view)];
    }
}
